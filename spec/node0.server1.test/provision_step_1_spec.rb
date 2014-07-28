require 'spec_helper'
require_relative '../factories/provision.rb'
require_relative '../puppet_spec_helper.rb'

describe 'Test 13: Apply provision for users layer step-1' do

  let(:provision) { build(:provision, step: 'step-1') }
  let(:users_profiles) {['base/users/ssh', 'base/users/users']}

  before(:all) do
    Bebox::Provision.generate_puppetfile(provision.project_root, provision.step, users_profiles)
    Bebox::Provision.generate_roles_and_profiles(provision.project_root, provision.step, 'users', users_profiles)
    provision.apply
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
      keys_content = File.read("#{provision.project_root}/config/keys/environments/vagrant/id_rsa.pub").strip
      should == "#{keys_content}"
    }
  end

  it 'should create checkpoint' do
    checkpoint_file_path = "#{provision.project_root}/.checkpoints/environments/#{provision.environment}/steps/#{provision.step}/#{provision.node.hostname}.yml"
    expect(File.exist?(checkpoint_file_path)).to eq(true)
    prepared_node_content = File.read(checkpoint_file_path).gsub(/\s+/, ' ').strip
    ouput_template = Tilt::ERBTemplate.new('spec/fixtures/node/provisioned_node_0.test.erb')
    prepared_node_expected_content = ouput_template.render(nil, node: provision.node).gsub(/\s+/, ' ').strip
    expect(prepared_node_content).to eq(prepared_node_expected_content)
  end
end