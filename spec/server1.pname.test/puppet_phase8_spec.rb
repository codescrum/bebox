require 'spec_helper'
require_relative 'puppet_spec_helper.rb'
require_relative '../factories/puppet.rb'

describe 'Phase 08: Puppet configure common modules' do

	# let(:puppet) { build(:puppet, :deploy_puppet_user) }
	let(:puppet) { build(:puppet) }

	before(:all) do
	  puppet.apply_common_modules
	end

  context 'nginx module' do
		describe package('nginx') do
		  it { should be_installed }
		end

		describe service('nginx') do
		  it { should be_enabled }
		end

		describe port(3000) do
		  it { should be_listening }
		end
	end

  context 'rbenv module' do
		describe file('/home/pname/.rbenv') do
		  it { should be_directory }
		end
    describe file('/home/pname/.rbenv/versions/1.9.3-p327') do
      it { should be_directory }
    end
	end

  context 'redis module' do
    describe port(6380) do
      it { should be_listening }
    end
  end

  context 'wkhtmltopdf' do
    describe package('wkhtmltopdf') do
      it { should be_installed }
    end
  end

  context 'imagemagick' do
    describe package('imagemagick') do
      it { should be_installed }
    end
  end

  context 'mysql' do
    describe port(3306) do
      it { should be_listening }
    end
    describe command('cat /etc/mysql/my.cnf | grep max_connections') do
      it { should return_stdout 'max_connections = 1024' }
    end
  end

  context 'postgresql' do
    describe port(5432) do
      it { should be_listening }
    end
    describe command('cat /etc/mysql/my.cnf | grep max_connections') do
      it { should return_stdout 'max_connections = 1024' }
    end
  end

  context 'mongodb' do
    describe port(27017) do
      it { should be_listening }
    end
  end

  context 'newrelic' do
    describe service('newrelic-sysmond') do
      it { should be_enabled }
    end
  end

  context 'htop' do
    describe package('htop') do
      it { should be_installed }
    end
  end

  context 'postfix' do
    describe service('postfix') do
      it { should be_enabled }
    end
  end
end