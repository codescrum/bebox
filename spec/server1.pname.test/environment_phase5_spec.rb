require 'spec_helper'

describe 'Puppet installed in vagrant machine' do

	let(:puppet) { build(:puppet, :installed) }

	before :all do
		RSpec.configure do |config|
	    host = puppet.environment.servers.first.ip
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

	describe package('puppet') do
		it { should be_installed }
	end

	describe service('puppet') do
	  it { should be_installed }
	end

end