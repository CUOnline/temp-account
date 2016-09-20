module ApplicationHelper
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
