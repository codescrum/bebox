require 'spec_helper'

describe 'environment with common dev installed' do

	let(:environment) { build(:environment, :with_common_dev) }

	before :all do
		RSpec.configure do |config|
	    host = environment.servers.first.ip
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

  after(:all) do
    environment.halt_vagrant_nodes
    environment.remove_vagrant_boxes
  end

	describe package('curl') do
		it { should be_installed }
	end

	describe package('git-core') do
		it { should be_installed }
	end

	describe command('hostname') do
		it 'should configure the hostname' do
			should return_stdout environment.servers.first.hostname
		end
	end

	describe command("dpkg -s #{Bebox::Environment::UBUNTU_DEPENDENCIES.join(' ')} | grep Status") do
		it 'should install ubuntu dependencies' do
			should return_stdout /(Status: install ok installed\s*){#{Bebox::Environment::UBUNTU_DEPENDENCIES.size}}/
		end
	end

end