class UserMailer < ApplicationMailer
  def reminder_to_complete_founder_profile(user)
    @user = user
    mail to: @user.email, subject: 'Reminder to fill up founder profile'
  end

  def cofounder_addition(cofounder_mail, current_user)
    @current_user = current_user
    mail(to: cofounder_mail, subject: 'SVApp: You have been added as startup cofounder!')
  end

  def incubation_request_submitted(current_user)
    @current_user = current_user
    mail(to: current_user.email, subject: 'You have successfully submitted your request for incubation at Startup Village.')
  end

  def password_changed(user)
    @user = user
    mail(to: user.email, subject: "Your password has been changed")
  end

  # Mail sent a little while after the a confirmed connect request meeting occured.
  #
  # @param connect_request [ConnectRequest] Request for a meeting which recently occurred.
  def connect_request_feedback(connect_request)
    @connect_request = connect_request
    @faculty = connect_request.faculty
    @user = connect_request.startup.admin
    mail(to: @user.email, subject: "Feedback for your recent faculty connect session with faculty member #{@faculty.name}")
  end
end
