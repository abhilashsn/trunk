class Notifier < ActionMailer::Base
  
  def signup_notification(file_name_new, subject, to)
    @subject =  subject
    @recipients = to
    @from = 'revremit@revenuemed.com'
    @sent_on = Time.now()
    body :file_name_new=> file_name_new
  end

end
