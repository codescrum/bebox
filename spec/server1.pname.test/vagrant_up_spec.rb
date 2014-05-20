require 'spec_helper'

describe 'vagrant up environment' do

	let(:project) { build(:project, :with_vagrant_up) }

	before :all do
		RSpec.configure do |config|
	    host = project.servers.first.ip
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

	describe interface('eth1') do
	  it { should have_ipv4_address(project.servers.first.ip) }
	end

	describe host('server1.pname.test') do
  	it { should be_resolvable }
	end

	describe host('server1.pname.test') do
	  it { should be_reachable }
	  it { should be_reachable.with( :port => 22 ) }
	end

	describe user('vagrant') do
	  it { should exist }
	end

end