# Be sure to restart your server when you modify this file.
# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Revremit::Application.config.session_store :active_record_store

if Rails.env.production?
  require 'action_dispatch/middleware/session/dalli_store'
  Rails.application.config.session_store :dalli_store, :memcache_server => ['127.0.0.1:11211'], :namespace => 'revremit_sessions', :key => '_revremit_session', :expire_after => 20.minutes
else
  Revremit::Application.config.session_store :active_record_store, :key => '_revremit_session', expire_after: 20.minutes
end