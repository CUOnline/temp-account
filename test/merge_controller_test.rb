require_relative './test_helper'

class MergeControllerTest < Minitest::Test
  def test_get
    code = '12345-1a1a1a1a-2b2b-3c3c-4d4d-5e5e5e5e5e5e'
    name = 'Testerino'
    email = 'testerino@example.com'
    user = mock()

    user.responds_like_instance_of(TempAccount::User)
    user.stubs(:merge_code).returns(code)
    user.stubs(:name).returns(name)
    user.stubs(:email).returns(email)
    TempAccount::User.expects(:new).with(anything, '12345').returns(user)

    get '/merge', {'code' => code}

    assert_equal 200, last_response.status
    assert_match /#{name} \(#{email}\)/, last_response.body
  end

  def test_get_with_invalid_uuid
    code = '12345-1a1a1a1a-2b2b-3c3c-4d4d-'

    get '/merge', {'code' => code}

    assert_equal 400, last_response.status
    assert_match /Invalid merge link/, last_response.body
  end


  def test_get_with_invalid_code
    invalid_code = '12345-1a1a1a1a-2b2b-3c3c-4d4d-5e5e5e5e5e5e'
    valid_code = '12345-1a1a1a1a-2b2b-3c3c-4d4d-5f5f5f5f5f5f'
    user = mock()
    user.responds_like_instance_of(TempAccount::User)
    user.stubs(:merge_code).returns(valid_code)

    get '/merge', {'code' => invalid_code}

    assert_equal 400, last_response.status
    assert_match /Invalid merge link/, last_response.body
  end

  def test_post
    code = '12345-1a1a1a1a-2b2b-3c3c-4d4d-5e5e5e5e5e5e'
    link = "https://example.org/merge?code=#{code}"
    user = mock()
    user.responds_like_instance_of(TempAccount::User)
    user.expects(:get_custom_data).returns(code)
    api = mock()
    api.expects(:put).with("users/12345/merge_into/123")
                     .returns(OpenStruct.new(:status => 200))
    TempAccount::User.expects(:new).with(anything, '12345').returns(user)
    MergeController.any_instance.expects(:canvas_api).twice.returns(api)
    Resque.expects(:remove_delayed).with(ExpirationWorker, 12345)
    Resque.expects(:remove_delayed).with(ReminderWorker, 12345, link)

    login
    post '/merge', {'code' => code}

    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/merge/success', last_request.path
    assert_equal 200, last_response.status
  end


  def test_post_with_missing_code
    login
    post '/merge'

    assert_equal 400, last_response.status
    assert_match /Invalid merge link/, last_response.body
  end

  def test_post_with_missing_primary_account
    code = '12345-1a1a1a1a-2b2b-3c3c-4d4d-5e5e5e5e5e5e'
    user = mock()
    user.responds_like_instance_of(TempAccount::User)
    user.stub_everything
    user.stubs(:merge_code).returns(code)
    TempAccount::User.expects(:new).returns(user)

    post '/merge', {'code' => code}
    assert_equal 302, last_response.status
    assert_match /Log into your primary UCD Canvas account/,
                 last_request.env['rack.session']['flash'][:danger]

    follow_redirect!
    assert_equal "/merge?code=#{code}", last_request.fullpath
  end

  def test_post_with_invalid_code
    invalid_code = '12345-1a1a1a1a-2b2b-3c3c-4d4d-5e5e5e5e5e5e'
    valid_code = '12345-1a1a1a1a-2b2b-3c3c-4d4d-5f5f5f5f5f5f'
    user = mock()
    user.responds_like_instance_of(TempAccount::User)
    user.expects(:get_custom_data).returns(valid_code)
    TempAccount::User.expects(:new).with(anything, '12345').returns(user)

    login
    post '/merge', {'code' => invalid_code}

    assert_equal 400, last_response.status
    assert_match /Invalid merge link/, last_response.body
  end


  def test_post_with_api_error
    code = '12345-1a1a1a1a-2b2b-3c3c-4d4d-5e5e5e5e5e5e'
    user = mock()
    user.responds_like_instance_of(TempAccount::User)
    user.expects(:get_custom_data).returns(code)
    api = mock()
    api.expects(:put).with("users/12345/merge_into/123")
                     .returns(OpenStruct.new(:status => 500))
    MergeController.any_instance.expects(:canvas_api).twice.returns(api)
    TempAccount::User.expects(:new).with(anything, '12345').returns(user)

    login
    post '/merge', {'code' => code}

    assert_equal 400, last_response.status
    assert_match /There was an error merging your accounts/, last_response.body
  end
end
