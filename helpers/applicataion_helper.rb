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
      faraday.response :json, :content_type => /\bjson$$/
      faraday.adapter :typhoeus
    end
  end

  def send_mail(subject, body, to_email)
    Mail.deliver do
      to        to_email
      from      'canvas@ucdenver.edu'
      subject   'Registration'

      text_part do
        body body
      end
      html_part do
        content_type 'text/html; charset=UTF-8'
        body body
      end
    end
  end

  def merge_link(code)
    "https://#{env['HTTP_HOST']}#{mount_point}/merge?code=#{code}"
  end
end
