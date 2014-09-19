require 'spec_helper'
require_relative 'vagrant_connector.rb'

describe 'Test 02: Prepares a vagrant node', :vagrant do

  let(:node) { build(:node, ip: YAML.load_file("#{Dir.pwd}/spec/vagrant/support/config_specs.yaml")['test_ip']) }

  before(:all) do
    node.prepare
  end

  describe interface('eth1') do
    it { should have_ipv4_address(node.ip) }
  end

  describe host('node0.server1.test') do
    it { should be_resolvable }
    it { should be_reachable.with( :port => 22 ) }
  end

  describe user('vagrant') do
    it { should exist }
  end

  describe command('hostname') do
    it 'should configure the hostname' do
      should return_stdout node.hostname
    end
  end

  describe command("dpkg -s #{Bebox::Project.so_dependencies} | grep Status") do
    it 'should install ubuntu dependencies' do
      should return_stdout /(Status: install ok installed\s*){#{Bebox::Project.so_dependencies.split(' ').size}}/
    end
  end

  describe package('puppet') do
    it { should be_installed }
  end

  it 'should create checkpoint' do
    checkpoint_file_path = "#{node.project_root}/.checkpoints/environments/vagrant/phases/phase-1/#{node.hostname}.yml"
    expect(File.exist?(checkpoint_file_path)).to be (true)
    prepared_node_content = File.read(checkpoint_file_path).gsub(/\s+/, ' ').strip
    output_template = Tilt::ERBTemplate.new("#{Dir.pwd}/spec/fixtures/node/prepared_node_0.test.erb")
    prepared_node_expected_content = output_template.render(nil, node: node).gsub(/\s+/, ' ').strip
    expect(prepared_node_content).to eq(prepared_node_expected_content)
  end
end