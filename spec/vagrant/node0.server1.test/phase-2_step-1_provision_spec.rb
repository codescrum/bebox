require 'spec_helper'
require_relative 'puppet_connector.rb'

describe 'Test 04: Apply provision for users layer step-1', :vagrant do

  let(:provision) { build(:provision, step: 'step-1') }
  let(:users_profiles) {['base/users/ssh', 'base/users/users']}

  before(:all) do
    Bebox::Provision.generate_puppetfile(provision.project_root, provision.step, users_profiles)
    Bebox::Provision.generate_roles_and_profiles(provision.project_root, provision.step, 'users', users_profiles)
    provision.apply
  end

  describe user('vagrant_box_test') do
    it { should exist }
    it { should belong_to_group 'root' }
    it { should have_home_directory '/home/vagrant_box_test' }
    it { should have_login_shell '/bin/bash' }
    it { should have_uid 7001 }
  end

  describe file('/home/vagrant_box_test/.ssh/authorized_keys') do
    let(:disable_sudo) { false }
    it { should be_file }
    its(:content) {
      keys_content = File.read("#{provision.project_root}/config/environments/vagrant/keys/id_rsa.pub").strip
      should == "#{keys_content}"
    }
  end

  it 'should create checkpoint' do
    checkpoint_file_path = "#{provision.project_root}/.checkpoints/environments/#{provision.environment}/phases/phase-2/steps/#{provision.step}/#{provision.node.hostname}.yml"
    expect(File.exist?(checkpoint_file_path)).to eq(true)
    prepared_node_content = File.read(checkpoint_file_path).gsub(/\s+/, ' ').strip
    ouput_template = Tilt::ERBTemplate.new("#{Dir.pwd}/spec/fixtures/node/provisioned_node_0.test.erb")
    prepared_node_expected_content = ouput_template.render(nil, node: provision.node).gsub(/\s+/, ' ').strip
    expect(prepared_node_content).to eq(prepared_node_expected_content)
  end
end