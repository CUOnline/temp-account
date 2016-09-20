class RegisterController < ApplicationController
  set :title, 'Create a temporary Canvas account'
  helpers RegisterHelper

  get '/' do
    slim :register
  end

  post '/' do
    form do
      field :full_name, :present => true, :length => 0..255
      field :email, :present => true, :regexp => /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
      field :expire_in, :present => true, :int => {:gte => 5, :lte => 180}
    end

    begin
      validate_form(params, form)
      user = TempAccount::User.new(canvas_api)
      user.register(params['full_name'], params['email'], settings.canvas_account_id)
      user.set_custom_data(user.merge_code)
      user.setup_sandbox(get_sandbox_account_id)
    rescue TempAccount::RegistrationError, TempAccount::ApiError => e
      status 400
      flash.now[:danger] = e.message
      return fill_in_form(slim :register)
    end

    merge_link = merge_link(user.merge_code)
    queue_workers(params['expire_in'], user.canvas_id, merge_link)
    send_registration_mail(params['email'], params['expire_in'], merge_link)

    flash.now[:success] = 'Account created successfully.'
    slim :register
  end
end
