require 'spec_helper'
require_relative '../factories/puppet.rb'
require_relative '../puppet_spec_helper.rb'

describe 'test_13: Puppet apply Users layer step-1' do

  let(:puppet) { build(:puppet, step: 'step-1') }
  let(:users_profiles) {['base/users/ssh', 'base/users/users']}

  before(:all) do
    Bebox::Puppet.generate_puppetfile(puppet.project_root, puppet.step, users_profiles)
    Bebox::Puppet.generate_roles_and_profiles(puppet.project_root, puppet.step, 'users', users_profiles)
    puppet.apply
  end

  describe user('pname') do
    it { should exist }
    it { should belong_to_group 'root' }
    it { should have_home_directory '/home/pname' }
    it { should have_login_shell '/bin/bash' }
    it { should have_uid 7001 }
  end

  describe file('/home/pname/.ssh/authorized_keys') do
    let(:disable_sudo) { false }
    it { should be_file }
    its(:content) {
      keys_content = File.read("#{puppet.project_root}/config/keys/environments/vagrant/id_rsa.pub").strip
      should == "#{keys_content}"
    }
  end
end