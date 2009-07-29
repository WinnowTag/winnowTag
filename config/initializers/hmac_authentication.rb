if Rails.env.test?
  credentials_file = File.join(RAILS_ROOT, 'config', 'hmac_credentials.yml.example')
else
  credentials_file = File.join(RAILS_ROOT, 'config', 'hmac_credentials.yml')
end

if File.exist?(credentials_file)
  HMAC_CREDENTIALS = YAML.load(File.read(credentials_file))
elsif Rails.env.production?
  raise "Winnow will not start in production mode without providing a credentials file at #{credentials_file}"
else
  HMAC_CREDENTIALS = {}
end