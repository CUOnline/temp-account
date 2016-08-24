require File.expand_path(File.join(File.dirname(__FILE__), '../controllers/application_controller'))

class ExpirationWorker
  @queue = 'temp-account-expiration'

  def self.perform(canvas_id)
    url = "accounts/#{ApplicationController.settings.canvas_account_id}/users/#{canvas_id}"
    ApplicationController.canvas_api.delete(url)
  end
end
