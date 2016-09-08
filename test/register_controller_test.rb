require_relative './test_helper'

class RegisterControllerTest < Minitest::Test
  def test_get_unauthenticated
    get '/register'

    assert_equal 302, last_response.status
    assert_equal 'https://example.org/register/canvas-auth-login?state=/register',
                  last_response.headers["Location"]
  end

  def test_post_unauthenticated
    post '/register'

    assert_equal 302, last_response.status
    assert_equal 'https://example.org/register/canvas-auth-login?state=/register',
                  last_response.headers["Location"]
  end

  def test_get
    login
    get '/register'

    assert_equal 200, last_response.status
  end

  def test_post
    canvas_account_id = 12345
    canvas_id = 123
    merge_code = '123-abcd-efgh'
    merge_link = "https://example.com/merge?code=#{merge_code}"
    email_body = 'This is an email body'
    full_name = 'Testerino'
    email = 'testerino@example.com'
    expire_in = '30'
    params = {'full_name' => full_name, 'email' => email, 'expire_in' => expire_in}

    user = mock()
    user.responds_like_instance_of(TempAccount::User)
    user.stub_everything
    user.stubs(:merge_code).returns(merge_code)
    user.stubs(:canvas_id).returns(canvas_id)
    user.expects(:register).with(full_name, email, canvas_account_id)
    TempAccount::User.expects(:new).returns(user)
    RegisterController.settings.stubs(:canvas_account_id).returns(canvas_account_id)

    RegisterController.any_instance.expects(:merge_link)
                                    .with(merge_code).returns(merge_link)

    RegisterController.any_instance.expects(:validate_form)
                                   .with(params, instance_of(FormKeeper::Report))

    RegisterController.any_instance.expects(:queue_workers)
                                   .with(expire_in, canvas_id, merge_link)

    RegisterController.any_instance.expects(:send_registration_mail)
                                   .with(email, expire_in, merge_link)

    login
    post '/register', params

    assert_equal 200, last_response.status
    assert_match /Account created successfully/, last_response.body
  end

  def test_post_form_errors
    error = "Parameters are invalid"
    RegisterController.any_instance
                      .expects(:validate_form)
                      .raises(TempAccount::RegistrationError, error)

    login
    post '/register'

    assert_equal 400, last_response.status
    assert_match /#{error}/, last_response.body
  end


  def test_post_registration_error
    error = 'Username is taken'
    user = mock()
    user.responds_like_instance_of(TempAccount::User)
    user.expects(:register).raises(TempAccount::RegistrationError, error)
    TempAccount::User.expects(:new).returns(user)
    RegisterController.any_instance.expects(:validate_form)

    login
    post '/register'

    assert_equal 400, last_response.status
    assert_match /#{error}/, last_response.body
  end


  def test_post_api_error
    error = 'Server Error'
    user = mock()
    user.responds_like_instance_of(TempAccount::User)
    user.expects(:register).raises(TempAccount::ApiError, error)
    TempAccount::User.expects(:new).returns(user)
    RegisterController.any_instance.expects(:validate_form)

    login
    post '/register'

    assert_equal 400, last_response.status
    assert_match /#{error}/, last_response.body
  end
end
