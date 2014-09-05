require 'spec_helper'

require_relative '../spec/factories/node.rb'

describe 'Test 04: Bebox::NodeWizard' do

  subject { Bebox::NodeWizard.new }

  let(:project_root) { "#{Dir.pwd}/tmp/bebox-pname" }
  let(:environment) { "vagrant" }
  let(:node_hostname) { "node_0.server1.test" }
  let(:node_ip) { YAML.load_file('spec/support/config_specs.yaml')['test_ip'] }

  before :each do
    $stdout.stub(:write)
  end

  context '00: node not exist' do

    it 'creates a node with wizard' do
      Bebox::Node.any_instance.stub(:create) { true }
      # First try with a non-free IP (127.0.0.1) and then the free
      $stdin.stub(:gets).and_return(node_hostname, '127.0.0.1', node_ip)
      output = subject.create_new_node(project_root, environment)
      expect(output).to eq(true)
    end

    it 'removes a node with wizard' do
      Bebox::Node.any_instance.stub(:remove) { true }
      output = subject.remove_node(project_root, environment, node_hostname)
      expect(output).to eq(true)
    end

    it 'prepares a node with wizard' do
      output = subject.prepare(project_root, environment)
      expect(output).to eq(true)
    end
  end

  context '01: node exist' do
    let(:node) { build(:node) }

    before :all do
      node.create
    end

    after :all do
      node.remove
    end

    it 'creates a node with wizard' do
      Bebox::Node.any_instance.stub(:create) { true }
      # First try with an existing hostname and then an inexisting
      $stdin.stub(:gets).and_return(node.hostname, 'localhost', node.ip)
      output = subject.create_new_node(project_root, environment)
      expect(output).to eq(true)
    end

    it 'removes a node with wizard' do
      Bebox::Node.any_instance.stub(:remove) { true }
      $stdin.stub(:gets).and_return('1', 'y')
      output = subject.remove_node(project_root, environment, node_hostname)
      expect(output).to eq(true)
    end

    it 'sets the role for a node' do
      Bebox::Provision.stub(:associate_node_role) { true }
      $stdin.stub(:gets).and_return('1', '1')
      output = subject.set_role(project_root, environment)
      expect(output).to eq(true)
    end

    it 'prepares a node with wizard' do
      Bebox::Node.any_instance.stub(:prepare) { true }
      Bebox::Node.stub(:regenerate_deploy_file) { true }
      Bebox::VagrantHelper.stub(:generate_vagrantfile) { true }
      Bebox::VagrantHelper.stub(:up_vagrant_nodes) { true }
      subject.stub(:prepare_vagrant) { true }
      output = subject.prepare(project_root, environment)
      expect(output).to eq(true)
    end

    it 'checks for an already prepared_node with wizard' do
      Bebox::Node.stub(:list) { [node.hostname] }
      Bebox::Node.any_instance.stub(:checkpoint_parameter_from_file) { '' }
      $stdin.stub(:gets).and_return('n')
      output = subject.check_nodes_to_prepare(project_root, environment)
      expect(output).to eq([])
    end
  end


  it 'checks for node existence' do
    output = subject.node_exists?(project_root, environment, node_hostname)
    expect(output).to eq(false)
  end

  it 'checks for free IP' do
    expect(subject.free_ip?(node_ip)).to eq(true)
  end
end