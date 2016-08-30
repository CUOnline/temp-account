require_relative './test_helper'
require_relative '../lib/temp_account'

class TempAccountUserTest < Minitest::Test
  def test_initialize
    canvas_api = mock()
    canvas_id = 123
    user = TempAccount::User.new(canvas_api)

    assert_equal canvas_api, user.instance_variable_get(:@canvas_api)
  end

  def test_initialize_with_id
    canvas_api = mock()
    canvas_id = 123
    TempAccount::User.any_instance.expects(:populate_data)
    user = TempAccount::User.new(canvas_api, canvas_id)

    assert_equal canvas_api, user.instance_variable_get(:@canvas_api)
    assert_equal canvas_id, user.instance_variable_get(:@canvas_id)
  end

  def  test_populate_data
    name = 'Testerino'
    email = 'testerino@example.com'
    canvas_id = 123
    api_response = OpenStruct.new(:body => {
      'name' => name,
      'primary_email' => email,
      'id' => canvas_id })
    canvas_api = mock()
    canvas_api.expects(:get).with("users/#{canvas_id}/profile").returns(api_response)

    user = TempAccount::User.new(canvas_api, canvas_id)

    assert_equal name, user.instance_variable_get(:@name)
    assert_equal email, user.instance_variable_get(:@email)
    assert_equal canvas_id, user.instance_variable_get(:@canvas_id)
  end

  def test_register
    name = 'Testerino'
    email = 'testerino@example.com'
    canvas_id = 123
    canvas_account_id = 456
    api_params = {
      :user => {:name => name},
      :pseudonym => {
        :unique_id => email,
        :force_self_registration => true,
        :send_confirmation => true,
      }
    }
    api_response = OpenStruct.new(:status => 200, :body => {'id' => canvas_id})
    canvas_api = mock()
    canvas_api.expects(:post).with("accounts/#{canvas_account_id}/users", api_params)
                             .returns(api_response)

    user = TempAccount::User.new(canvas_api)
    user.register(name, email, canvas_account_id)

    assert_equal name, user.instance_variable_get(:@name)
    assert_equal email, user.instance_variable_get(:@email)
    assert_equal canvas_id, user.instance_variable_get(:@canvas_id)
  end

  def test_register_with_api_error
    name = 'Testerino'
    email = 'testerino@example.com'
    canvas_id = 123
    canvas_account_id = 456
    api_params = {
      :user => {:name => name},
      :pseudonym => {
        :unique_id => email,
        :force_self_registration => true,
        :send_confirmation => true,
      }
    }
    api_response = OpenStruct.new(:status => 422, :body => {})
    canvas_api = mock()
    canvas_api.expects(:post).with("accounts/#{canvas_account_id}/users", api_params)
                             .returns(api_response)

    user = TempAccount::User.new(canvas_api)
    error = assert_raises TempAccount::ApiError do
      user.register(name, email, canvas_account_id)
    end

    assert_equal "There was a problem creating the account.", error.message
  end

  def test_register_with_taken_email
    name = 'Testerino'
    email = 'testerino@example.com'
    canvas_id = 123
    canvas_account_id = 456
    api_params = {
      :user => {:name => name},
      :pseudonym => {
        :unique_id => email,
        :force_self_registration => true,
        :send_confirmation => true,
      }
    }
    api_response = OpenStruct.new(:status => 422, :body => {
      'errors' => {'pseudonym' => {'unique_id' => [{'message' => 'Taken!'}]}}
    })
    canvas_api = mock()
    canvas_api.expects(:post).with("accounts/#{canvas_account_id}/users", api_params)
                             .returns(api_response)

    user = TempAccount::User.new(canvas_api)
    error = assert_raises TempAccount::RegistrationError do
      user.register(name, email, canvas_account_id)
    end

    assert_equal "Email address is already in use", error.message
  end

  def test_setup_sandbox
    name = 'Testerino'
    email = 'testerino@example.com'
    canvas_id = 123
    course_id = 789
    sandbox_account_id = 456
    canvas_api = mock()
    TempAccount::User.any_instance.expects(:populate_data)
    user = TempAccount::User.new(canvas_api, canvas_id)
    user.name = name
    user.email = email

    first_api_params = { 'course' => { 'name' => "sandbox_#{name}" } }
    api_response = OpenStruct.new(:status => 200, :body => {'id' => course_id} )
    canvas_api.expects(:post)
              .with("accounts/#{sandbox_account_id}/courses", first_api_params)
              .returns(api_response)

    second_api_params = {
      'enrollment' => {
        'user_id' => canvas_id,
        'type' => 'TeacherEnrollment'
      }
    }
    canvas_api.expects(:post)
              .with("courses/#{course_id}/enrollments", second_api_params)
              .returns(OpenStruct.new(:status => 200))

    user.setup_sandbox(sandbox_account_id)
  end

  def test_setup_sandbox_with_create_api_error
    name = 'Testerino'
    email = 'testerino@example.com'
    course_id = 789
    canvas_id = 123
    sandbox_account_id = 456
    canvas_api = mock()
    TempAccount::User.any_instance.expects(:populate_data)
    user = TempAccount::User.new(canvas_api, canvas_id)
    user.name = name
    user.email = email

    api_params = { 'course' => { 'name' => "sandbox_#{name}" } }
    api_response = OpenStruct.new(:status => 500)
    canvas_api.expects(:post).with("accounts/#{sandbox_account_id}/courses", api_params)
                             .returns(api_response)


    error = assert_raises TempAccount::ApiError do
      user.setup_sandbox(sandbox_account_id)
    end

    assert_equal "Account created, but there was a problem creating the sandbox course.",
                  error.message
  end

  def test_setup_sandbox_with_enroll_api_error
    name = 'Testerino'
    email = 'testerino@example.com'
    canvas_id = 123
    course_id = 789
    sandbox_account_id = 456
    canvas_api = mock()
    TempAccount::User.any_instance.expects(:populate_data)
    user = TempAccount::User.new(canvas_api, canvas_id)
    user.name = name
    user.email = email

    api_params = { 'course' => { 'name' => "sandbox_#{name}" } }
    api_response = OpenStruct.new(:status => 200, :body => {'id' => course_id} )
    canvas_api.expects(:post).with("accounts/#{sandbox_account_id}/courses", api_params)
                             .returns(api_response)

    api_params = {
      'enrollment' => {
        'user_id' => canvas_id,
        'type' => 'TeacherEnrollment'
      }
    }
    canvas_api.expects(:post).with("courses/#{course_id}/enrollments", api_params)
                             .returns(OpenStruct.new(:status => 500))

    error = assert_raises TempAccount::ApiError do
      user.setup_sandbox(sandbox_account_id)
    end

    assert_equal "Account created, but there was a problem enrolling in the sandbox course.",
                  error.message
  end

  def test_set_custom_data
    canvas_id = 123
    data = 'Test data'
    canvas_api = mock()
    api_params = {:ns => 'wolf', :data => data}

    canvas_api.expects(:put)
              .with("users/#{canvas_id}/custom_data/temp-account-code", api_params)
    TempAccount::User.any_instance.expects(:populate_data)
    user = TempAccount::User.new(canvas_api, canvas_id)

    user.set_custom_data(data)
  end

  def test_get_custom_data
    canvas_id = 123
    data = 'Test data'
    canvas_api = mock()
    api_params = {:ns => 'wolf'}

    canvas_api.expects(:get)
              .with("users/#{canvas_id}/custom_data/temp-account-code", api_params)
              .returns(OpenStruct.new(:body => {'data' => data}))
    TempAccount::User.any_instance.expects(:populate_data)

    user = TempAccount::User.new(canvas_api, canvas_id)

    assert_equal data, user.get_custom_data
  end

  def test_merge_code_new
    canvas_id = 123
    canvas_api = mock()

    TempAccount::User.any_instance.expects(:get_custom_data).returns(nil)
    TempAccount::User.any_instance.expects(:populate_data)
    user = TempAccount::User.new(canvas_api, canvas_id)
    SecureRandom.expects(:uuid).returns("uuid")

    assert_equal "#{canvas_id}-uuid", user.merge_code
    assert_equal "#{canvas_id}-uuid", user.instance_variable_get(:@merge_code)
  end

  def test_merge_code_already_set
    canvas_id = 123
    code = '123-abc'
    canvas_api = mock()

    TempAccount::User.any_instance.expects(:get_custom_data).returns(code)
    TempAccount::User.any_instance.expects(:populate_data)
    user = TempAccount::User.new(canvas_api, canvas_id)

    assert_equal code, user.merge_code
    assert_equal code, user.instance_variable_get(:@merge_code)
  end
end
