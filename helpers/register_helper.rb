require File.expand_path(File.join(File.dirname(__FILE__), '../workers/expiration_worker.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '../workers/reminder_worker.rb'))

module RegisterHelper
  def validate_form(params, form)
    if form.failed?
      message = ''
      form.failed_fields.each do |f|
        message += "- #{f.to_s.gsub(/_/, ' ').capitalize} is invalid <br/>"
      end

      raise TempAccount::RegistrationError, message
    end
  end

  def queue_workers(expire_in_days, canvas_id, merge_link)
    remind_in_days = (expire_in_days.to_i - 3)
    remind_in_secs = remind_in_days * 24 * 60 * 60
    Resque.enqueue_in(remind_in_secs, ReminderWorker, canvas_id.to_i, merge_link)

    expire_in_secs = expire_in_days.to_i * 24 * 60 * 60
    Resque.enqueue_in(expire_in_secs, ExpirationWorker, canvas_id.to_i)
  end

  def registration_body(expire_in, merge_link)
    "Your temporary Canvas account will expire in #{expire_in} days. "\
    "Once you get your official Canvas account, visit the link below "\
    "to merge in content from your temporary account. \n"\
    "<a href='#{merge_link}'>Merge Accounts</a>"
  end

  def get_sandbox_account_id
    if settings.respond_to?(:sandbox_account_id)
      sandbox_account_id = settings.sandbox_account_id
    else
      sandbox_account_id = settings.canvas_account_id
    end
  end
end

