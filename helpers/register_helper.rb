require File.expand_path(File.join(File.dirname(__FILE__), '../workers/expiration_worker.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '../workers/reminder_worker.rb'))

module RegisterHelper
  def validate_form(params)
    form do
      field :full_name, :present => true, :length => 0..255
      field :email, :present => true, :regexp => /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
      field :expire_in, :present => true, :int => {:lte => 365}
    end

    if form.failed?
      message = ''
      form.failed_fields.each do |f|
        message += "- #{f.to_s.gsub(/_/, ' ').capitalize} is invalid <br/>"
      end

      raise TempAccount::RegistrationError, message
    end
  end

  def queue_workers(expire_in, user)
    remind_in = (expire_in.to_i - 3).days
    Resque.enqueue_in(remind_in, ReminderWorker, user.canvas_id, merge_link(user.merge_code))

    expire_in = expire_in.to_i.days
    Resque.enqueue_in(expire_in, ExpirationWorker, user.canvas_id)
  end

  def registration_body(expire_in, code)
    "Your temporary Canvas account will expire in #{expire_in} days. "\
    "Once you get your official Canvas account, visit the link below "\
    "to merge in content from your temporary account. \n"\
    "<a href='#{merge_link(code)}'>Merge Accounts</a>"
  end

  def sandbox_account_id
    if settings.respond_to?(:sandbox_account_id)
      sandbox_account_id = settings.sandbox_account_id
    else
      sandbox_account_id = settings.canvas_account_id
    end
  end
end

