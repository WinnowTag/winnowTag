# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_winnow_session',
  :secret      => 'd768f297dcbe7a3afaebeb4d2f7022b30822109291263eec7af980b787d5a1a8ca56833de2bc75f8a26777d5d974d20aac2c6316e2f4786fdd7f17771f9ee1be'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
