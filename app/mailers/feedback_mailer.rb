class FeedbackMailer < ActionMailer::Base

  def send_feedback feedback
    @feedback = feedback
    feedback.groups.each do |group|
      mail :from => @feedback.email, :to => group.emails, :subject => @feedback.subject
    end
  end

end
