RSpec.configure do |config|
  config.before :all do
    host = '192.168.0.70'
    if config.host != host
      config.disable_sudo = true
      config.ssh.close if config.ssh
      config.host  = host
      options = Net::SSH::Config.for(config.host)
      options[:keys] = %w(~/.vagrant.d/insecure_private_key)
      options[:forward_agent] = true
      user = 'vagrant'
      config.ssh   = Net::SSH.start(config.host, user, options)
    end
  end
end