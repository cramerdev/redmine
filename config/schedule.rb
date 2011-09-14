# Load the imap_addresses from the config and set them all up to be checked
# periodically
(((YAML.load_file('config/configuration.yml') || {})['production'] || {})['imap_addresses'] || []).each do |a|
  every 15.minutes do
    rake "redmine:email:receive_imap " + a.map {|k, v| "#{k}=#{v}" }.join(' ')
  end
end
