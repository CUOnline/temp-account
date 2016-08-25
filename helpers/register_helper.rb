require File.expand_path(File.join(File.dirname(__FILE__), '../workers/expiration_worker.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '../workers/reminder_worker.rb'))

module RegisterHelper
  def validate_form(params)
    form do
      field :full_name, :present => true, :length => 0..255
      field :email, :present => true, :regexp => /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
      field :expire_in, :present => true, :int => {:gte => 5, :lte => 180}
    end

    if form.failed?
      message = ''
      form.failed_fields.each do |f|
        message += "- #{f.to_s.gsub(/_/, ' ').capitalize} is invalid <br/>"
      end

      raise TempAccount::RegistrationError, message
    end
  end

  def queue_workers(expire_in_days, user)
    remind_in_days = (expire_in_days.to_i - 3)
    remind_in_secs = remind_in_days * 24 * 60 * 60
    Resque.enqueue_in(remind_in_secs, ReminderWorker, user.canvas_id,
                      merge_link(user.merge_code))

    expire_in_secs = expire_in_days.to_i * 24 * 60 * 60
    Resque.enqueue_in(expire_in_secs, ExpirationWorker, user.canvas_id)
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

