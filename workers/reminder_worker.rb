require File.expand_path(File.join(File.dirname(__FILE__), '../controllers/application_controller'))

class ReminderWorker
  @queue = 'temp-account-reminder'

  def self.perform(canvas_id, merge_link)
    user = TempAccount::User.new(canvas_id)

    body = "This is a friendly reminder that your temporary canvas account will"\
           "expire in 3 days. If you wish to preserve content from this account,"\
           "you can merge it with your primary account by visiting this link: \n"\
           "<a href='#{merge_link}'>Merge Accounts</a>"

    ApplicationController.send_mail('Your temporary Canvas account will expire soon!',
                                    body, user.email)

  end
end


