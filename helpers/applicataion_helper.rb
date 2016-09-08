require 'faraday'
require 'faraday_middleware'
require 'typhoeus'
require 'typhoeus/adapters/faraday'

module ApplicationHelper
  def oauth_callback(oauth_response)
    session['user_name'] = oauth_response['user']['name']
    session['user_id'] = oauth_response['user']['id']

    email_response = canvas_api.get("users/#{session['user_id']}/profile")
    session['user_email'] = email_response.body['primary_email']
  end

  def canvas_api
    return Faraday.new(:url => "#{settings.canvas_url}/api/v1") do |faraday|
      faraday.request :oauth2, settings.canvas_token
      faraday.response :json, :content_type => /\bjson$/
      faraday.adapter :typhoeus
    end
  end

  def send_reminder_mail(to_email, merge_link)
    Mail.deliver do
      to        to_email
      from      'Canvas <canvas@ucdenver.edu>'
      subject   'Your temporary Canvas is about to expire'

      text_part do
        body "This is a friendly reminder that your temporary canvas account will "\
             "expire in 3 days. If you wish to preserve content from this account,"\
             "you can merge it with your primary account by visiting URL below. \n\n"\
             "#{merge_link}"
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body "<p>This is a friendly reminder that your temporary canvas account will"\
             "expire in 3 days.</p><p>If you wish to preserve content from this account, "\
             "you can merge it with your primary account by visiting link below.</p>"\
             "<p><a href='#{merge_link}'>Merge Accounts</a></p>"
      end
    end
  end

  def merge_link(code)
    "https://#{env['HTTP_HOST']}#{mount_point}/merge?code=#{code}"
  end
end
