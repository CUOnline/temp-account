require_relative './test_helper'
require_relative '../helpers/register_helper'

class RegisterHelperTest < Minitest::Test
  include RegisterHelper

  def test_validate_form
    form = mock()
    form.stubs(:failed?).returns(false)
    assert_equal nil, validate_form({}, form)
  end

  def test_validate_form_with_invalid_form
    form = mock()
    form.stubs(:failed?).returns(true)
    form.stubs(:failed_fields).returns(['full_name', 'email', 'expire_in'])

    error = assert_raises TempAccount::RegistrationError do
      validate_form({}, form)
    end

    assert_equal "- Full name is invalid <br/>" \
                 "- Email is invalid <br/>" \
                 "- Expire in is invalid <br/>",
                  error.message
  end

  def test_queue_workers
    canvas_id = 123
    code = '123-abcd'
    merge_link = "https://example.com/merge?code=#{code}"
    user = mock()
    user.stubs(:merge_code).returns(code)
    user.stubs(:canvas_id).returns(canvas_id)

    Resque.expects(:enqueue_in).with(1468800, ReminderWorker, canvas_id, merge_link)
    Resque.expects(:enqueue_in).with(1728000, ExpirationWorker, canvas_id)

    queue_workers(20, canvas_id, merge_link)
  end

  def test_get_sandbox_account_id
    id = 123
    self.stubs(:settings).returns(OpenStruct.new(:sandbox_account_id => id))
    assert_equal id, get_sandbox_account_id
  end

  def test_get_sandbox_account_id_with_missing_setting
    id = 456
    self.stubs(:settings).returns(OpenStruct.new(:canvas_account_id => id))
    assert_equal id, get_sandbox_account_id
  end
end
