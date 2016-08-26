class MergeController < ApplicationController

  get '/' do
    # Generated merge codes are in this format: {temp canvas ID}-{UUID}
    valid_uuid = /\A\d+-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z/

    if (params['code'] || '').match(valid_uuid)
      temp_id = params['code'].split('-')[0]
      user = TempAccount::User.new(canvas_api, temp_id)
    end

    # Make sure code matches before submitting so we don't expose name/email
    # to anyone who provides an invalid code containing a valid Canvas ID
    if user && (user.merge_code == params['code'])
      @temp_info = "#{user.name} (#{user.email})"
      erb :merge
    else
      status 400
      flash.now[:danger] = "Invalid merge link"
      erb ''
    end
  end

  # Attempt to merge primary and temporary accounts
  # Temporary account is identified by user ID embedded in param['code']
  # Primary account is identified by session['user_id'] from OAuth login
  post '/' do
    if !session['user_id']
      flash[:danger] = 'Log into your primary UCD Canvas account to merge'
      redirect "#{mount_point}/merge?code=#{params['code']}"
    end

    begin
      raise TempAccount::MergeError, 'Invalid merge link' unless params['code']

      temp_id = params['code'].split('-')[0]
      primary_id = session['user_id']
      user = TempAccount::User.new(canvas_api, temp_id)

      if user.get_custom_data != params['code']
        raise TempAccount::MergeError, 'Invalid merge link'
      end

      response = canvas_api.put("users/#{temp_id}/merge_into/#{primary_id}")

      if response.status != 200
        raise TempAccount::MergeError, 'There was an error merging your accounts'
      end

      # Merging deletes temporary account, so no need for future reminding/expiring
      Resque.remove_delayed(ExpirationWorker, temp_id.to_i)
      Resque.remove_delayed(ReminderWorker, temp_id.to_i)

    rescue TempAccount::MergeError => e
      status 400
      flash.now[:danger] = e.message
      return erb ''
    end

    redirect "#{mount_point}/merge/success"
  end

  get '/success' do
    erb :success
  end
end
