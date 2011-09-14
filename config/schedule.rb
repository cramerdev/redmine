# When using REE in a place that's not in the default path, run this with
# something like `whenever -w PATH=$PATH`
env :PATH, ENV['PATH']

# Load the imap_addresses from the config and set them all up to be checked
# periodically
(((YAML.load_file('config/configuration.yml') || {})['production'] || {})['imap_addresses'] || []).each do |a|
  every 5.minutes do
    rake "redmine:email:receive_imap --silent " + a.map {|k, v| "#{k}=#{v}" }.join(' ')
  end
end
