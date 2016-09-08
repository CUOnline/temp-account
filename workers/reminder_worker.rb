require File.expand_path(File.join(File.dirname(__FILE__), '../controllers/application_controller'))

class ReminderWorker
  @queue = 'temp-account-reminder'

  def self.perform(canvas_id, merge_link)
    user = TempAccount::User.new(ApplicationController.canvas_api, canvas_id)
    ApplicationController.send_reminder_mail(user.email, merge_link)
  end
end


