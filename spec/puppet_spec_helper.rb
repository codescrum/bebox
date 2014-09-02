RSpec.configure do |config|
  config.before do
    host = 'node0.server1.test'
    if config.host != host
      config.disable_sudo = true
      config.ssh.close if config.ssh
      config.host  = host
      options = Net::SSH::Config.for(config.host)
      options[:keys] = ["#{provision.project_root}/config/environments/vagrant/keys/id_rsa"]
      options[:forward_agent] = true
      user = 'puppet'
      config.ssh   = Net::SSH.start(config.host, user, options)
    end
  end
end