# Contains the application specific configurations supplied to ExceptionNotifier class to override the defaults.
# ActiveRecord::RecordNotFound, AbstractController::ActionNotFound, ActionController::RoutingError are ignored by Exception Notifier
# ActionController::InvalidAuthenticityToken needs to be ignored by the RevRemit

if ENV["RAILS_ENV"] == "production"
  exceptions_to_ignore = []
  exceptions_to_ignore << ActiveRecord::RecordNotFound if defined? ActiveRecord
  exceptions_to_ignore << AbstractController::ActionNotFound if defined? AbstractController
  exceptions_to_ignore << ActionController::RoutingError if defined? ActionController
  exceptions_to_ignore << ActionController::InvalidAuthenticityToken if defined? ActionController

  Revremit::Application.config.middleware.use ExceptionNotifier,
    :email_prefix => "[RevRemit : Error]",
    :sender_address => %("RevRemit Application" <revremit@revenuemed.com>),
    :exception_recipients => %w(revremitdevelopment@revenuemed.com qasoftware@revenuemed.com),
    :ignore_exceptions => exceptions_to_ignore
end
