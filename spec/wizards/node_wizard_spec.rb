require 'spec_helper'

require_relative '../factories/node.rb'

describe 'Bebox::NodeWizard' do

  subject { Bebox::NodeWizard.new }

  let(:node) { build(:node) }

  before :each do
    $stdout.stub(:write)
  end

  context 'node not exist' do

    before :each do
      subject.stub(:node_exists?) { false }
    end

    it 'creates a node with wizard' do
      Bebox::Node.any_instance.stub(:create) { true }
      # First try with a non-free IP (127.0.0.1) and then the free
      $stdin.stub(:gets).and_return(node.hostname, '127.0.0.1', node.ip)
      output = subject.create_new_node(node.project_root, node.environment)
      expect(output).to eq(true)
    end

    it 'can not remove a node if not exist any' do
      Bebox::Node.stub(:list) { [] }
      output = subject.remove_node(node.project_root, node.environment, node.hostname)
      expect(output).to eq(true)
    end

    it 'can not prepare a node if not exist any' do
      subject.stub(:check_nodes_to_prepare) { [] }
      output = subject.prepare(node.project_root, node.environment)
      expect(output).to eq(true)
    end
  end

  context 'node exist' do

    before :each do
      subject.stub(:node_exists?) { true }
    end

    it 'removes a node with wizard' do
      Bebox::Node.stub(:list) { [node.hostname] }
      Bebox::Node.any_instance.stub(:remove) { true }
      $stdin.stub(:gets).and_return('1', 'y')
      output = subject.remove_node(node.project_root, node.environment, node.hostname)
      expect(output).to eq(true)
    end

    it 'prepares a node with wizard' do
      Bebox::Node.any_instance.stub(:prepare) { true }
      subject.stub(:check_nodes_to_prepare) { [node] }
      Bebox::Node.stub(:regenerate_deploy_file) { true }
      Bebox::VagrantHelper.stub(:generate_vagrantfile) { true }
      Bebox::VagrantHelper.stub(:up_vagrant_nodes) { true }
      subject.stub(:prepare_vagrant) { true }
      output = subject.prepare(node.project_root, node.environment)
      expect(output).to eq(true)
    end

    it 'creates a node with wizard' do
      Bebox::Node.any_instance.stub(:create) { true }
      # First try with an existing hostname and then an inexisting
      $stdin.stub(:gets).and_return(node.hostname, 'localhost', node.ip)
      output = subject.create_new_node(node.project_root, node.environment)
      expect(output).to eq(true)
    end

    it 'sets the role for a node' do
      Bebox::Role.stub(:list) {['a']}
      Bebox::Node.stub(:list) {[node]}
      Bebox::Provision.stub(:associate_node_role) { true }
      $stdin.stub(:gets).and_return('1', '1')
      output = subject.set_role(node.project_root, node.environment)
      expect(output).to eq(true)
    end

    it 'checks for a no prepared_node with wizard' do
      Bebox::Node.stub(:nodes_in_environment) { [node] }
      Bebox::Node.stub(:list) { [] }
      Bebox::Node.any_instance.stub(:checkpoint_parameter_from_file) { '' }
      output = subject.check_nodes_to_prepare(node.project_root, node.environment)
      expect(output).to eq([node])
    end

    it 'checks for an already prepared_node with wizard' do
      Bebox::Node.stub(:nodes_in_environment) { [node] }
      Bebox::Node.stub(:list) { [node.hostname] }
      Bebox::Node.any_instance.stub(:checkpoint_parameter_from_file) { '' }
      $stdin.stub(:gets).and_return('n')
      output = subject.check_nodes_to_prepare(node.project_root, node.environment)
      expect(output).to eq([])
    end
  end

  it 'checks for node existence' do
    output = subject.node_exists?(node.project_root, node.environment, node.hostname)
    expect(output).to eq(false)
  end

  it 'checks for free IP' do
    expect(subject.free_ip?(node.ip)).to eq(true)
  end
end