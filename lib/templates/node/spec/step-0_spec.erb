require 'spec_helper'
require_relative 'vagrant_connector.rb'

describe 'Phase-2, Step-0: Apply provision for fundamental step' do

  describe user('puppet') do
    it { should exist }
    it { should belong_to_group 'root' }
    it { should have_home_directory '/home/puppet' }
    it { should have_login_shell '/bin/bash' }
    it { should have_uid 7000 }
  end

  describe file('/home/puppet/.ssh/authorized_keys') do
    let(:disable_sudo) { false }
    it { should be_file }
    its(:content) {
      keys_content = File.read("#{Dir.pwd}/config/environments/vagrant/keys/id_rsa.pub").strip
      should == "#{keys_content}"
    }
  end

  describe file('/etc/sudoers.d/10_puppet') do
    let(:disable_sudo) { false }
    it { should be_file }
  end

end