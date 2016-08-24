class RegisterController < ApplicationController

  helpers RegisterHelper

  get '/' do
    erb :register
  end

  post '/' do
    begin
      validate_form(params)
      user = TempAccount::User.new(canvas_api)
      user.register(params['full_name'], params['email'], settings.canvas_account_id)
      user.set_custom_data(user.merge_code)
      user.setup_sandbox(sandbox_account_id)
    rescue TempAccount::RegistrationError, TempAccount::ApiError => e
      status 400
      flash.now[:danger] = e.message
      return fill_in_form(erb :register)
    end

    queue_workers(params['expire_in'], user)
    send_mail('Your temporary Canvas account has been created',
              registration_body(params['expire_in'], user.merge_code),
              params['email'])

    flash.now[:success] = 'Account created successfully.'
    erb :register
  end
end
