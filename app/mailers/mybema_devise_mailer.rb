class MybemaDeviseMailer < Devise::Mailer
  before_filter :set_default_host

  def invitation_instructions(record, token, opts={})
    set_email_opts(opts, token)
    devise_mail(record, :invitation_instructions, opts)
  end

  def confirmation_instructions(record, token, opts={})
    set_email_opts(opts, token)
    devise_mail(record, :confirmation_instructions, opts)
  end

  def notify_admins(comment, user)
    @comment     = comment
    @discussion  = comment.discussion
    @user        = user
    admin_emails = Admin.pluck(:email)

    mail(to: admin_emails,
         from: AppSettings.first.mailer_sender,
         template_path: "mailers/admin_emails",
         subject: "#{user.username} responded to #{@discussion.title}",
         delivery_method_options: app_smtp_settings)
  end

  def notify_admins_of_new_discussion(discussion, user)
    @discussion  = discussion
    @user        = user
    admin_emails = Admin.pluck(:email)

    mail(to: admin_emails,
         from: AppSettings.first.mailer_sender,
         template_path: "mailers/admin_emails",
         subject: "#{user.username} started a new discussion: #{@discussion.title}",
         delivery_method_options: app_smtp_settings)
  end

  def notify_subscribers(discussion, subscribers)
    subscriber_emails = User.where(id: subscribers).map(&:email)
    @app_settings     = AppSettings.first
    @discussion       = discussion

    mail(to: subscriber_emails,
         from: @app_settings.mailer_sender,
         template_path: "mailers/user_emails",
         subject: "New response in #{@app_settings.community_title} community",
         delivery_method_options: app_smtp_settings)
  end

  def reset_password_instructions(record, token, opts={})
    set_email_opts(opts, token)
    devise_mail(record, :reset_password_instructions, opts)
  end

  def send_welcome(record)
    @resource = record
    mail(to: record.email,
         from: AppSettings.first.mailer_sender,
         template_path: "devise/mailer",
         subject: "Welcome to the community!",
         delivery_method_options: app_smtp_settings)
  end

  def unlock_instructions(record, token, opts={})
    set_email_opts(opts, token)
    devise_mail(record, :unlock_instructions, opts)
  end

  private

  def set_email_opts opts, token
    opts[:from] = AppSettings.first.mailer_sender
    opts[:reply_to] = AppSettings.first.mailer_reply_to
    opts[:delivery_method_options] = app_smtp_settings

    @token = token
  end

  def set_default_host
    default_url_options[:host] = smtp_settings.domain_address
  end

  def smtp_settings
    @app_settings || AppSettings.first
  end

  def app_smtp_settings
    self.smtp_settings = {
      address:              smtp_settings.smtp_address,
      port:                 smtp_settings.smtp_port,
      domain:               smtp_settings.smtp_domain,
      user_name:            smtp_settings.smtp_username,
      password:             smtp_settings.smtp_password,
      authentication:       "plain",
      enable_starttls_auto: true
    }
  end
end