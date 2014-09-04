require 'spec_helper'
require_relative '../spec/factories/node.rb'

describe 'Test 04: Bebox::Node' do

  describe 'Nodes management' do

    subject { build(:node) }

    context '00: node creation' do

      before :all do
        subject.create
      end

      it 'creates hiera data template' do
        Bebox::PROVISION_STEPS.each do |step|
          expect(File.exist?("#{subject.project_root}/puppet/steps/#{Bebox::Provision.step_name(step)}/hiera/data/#{subject.hostname}.yaml")).to eq(true)
        end
      end

      it 'creates node in manifests file' do
        Bebox::PROVISION_STEPS.each do |step|
          content = File.read("spec/fixtures/puppet/steps/#{step}/manifests/site_with_node.pp.test").gsub(/\s+/, ' ').strip
          output = File.read("#{subject.project_root}/puppet/steps/#{Bebox::Provision.step_name(step)}/manifests/site.pp").gsub(/\s+/, ' ').strip
          expect(output).to eq(content)
        end
      end

      it 'creates checkpoint' do
        expect(File.exist?("#{subject.project_root}/.checkpoints/environments/#{subject.environment}/nodes/#{subject.hostname}.yml")).to be (true)
        node_content = File.read("#{subject.project_root}/.checkpoints/environments/#{subject.environment}/nodes/#{subject.hostname}.yml").gsub(/\s+/, ' ').strip
        ouput_template = Tilt::ERBTemplate.new('spec/fixtures/node/node_0.test.erb')
        node_output_content = ouput_template.render(nil, node: subject).gsub(/\s+/, ' ').strip
        expect(node_content).to eq(node_output_content)
      end

      it 'list the current nodes' do
        current_nodes = [subject.hostname]
        nodes = Bebox::Node.list(subject.project_root, subject.environment, 'nodes')
        expect(nodes).to include(*current_nodes)
      end

      it 'gets a checkpoint parameter' do
        hostname = subject.checkpoint_parameter_from_file('nodes', 'hostname')
        expect(hostname).to eq(subject.hostname)
      end
    end

    context '01: self methods' do
      it 'obtains the nodes in a given environment and phase' do
        expected_nodes = [subject.hostname]
        object_nodes = Bebox::Node.nodes_in_environment(subject.project_root, subject.environment, 'nodes')
        expect(object_nodes.map{|node| node.hostname}).to include(*expected_nodes)
      end

      it 'obtains a node provision description state' do
        message = "Allocated at #{subject.checkpoint_parameter_from_file('nodes', 'created_at')}"
        description_state = Bebox::Node.node_provision_state(subject.project_root, subject.environment, subject.hostname)
        expect(description_state).to eq(message)
      end

      it 'obtains a state description for a checkpoint' do
        checkpoints = %w{nodes prepared_nodes steps/step-0 steps/step-1 steps/step-2 steps/step-3}
        expected_descriptions = ['Allocated',  'Prepared', 'Provisioned Fundamental step-0',
          'Provisioned Users layer step-1', 'Provisioned Services layer step-2', 'Provisioned Security layer step-3']
        descriptions = []
        checkpoints.each do |checkpoint|
          descriptions << Bebox::Node.state_from_checkpoint(checkpoint)
        end
        expect(descriptions).to include(*expected_descriptions)
      end

      it 'counts the nodes for types' do
        nodes_count = Bebox::Node.count_all_nodes_by_type(subject.project_root, 'nodes')
        expect(nodes_count).to eq(1)
      end
    end

    context '02: node deletion' do
      before :all do
        subject.remove
      end

      it 'removes the checkpoints' do
        expect(File.exist?("#{subject.project_root}/.checkpoints/environments/#{subject.environment}/nodes/#{subject.hostname}.yml")).to be (false)
      end

      it 'not list any nodes' do
        nodes = Bebox::Node.list(subject.project_root, subject.environment, 'nodes')
        expect(nodes.count).to eq(0)
      end

      it 'removes hiera data' do
        Bebox::PROVISION_STEPS.each do |step|
          expect(File.exist?("#{subject.project_root}/puppet/steps/#{Bebox::Provision.step_name(step)}/hiera/data/#{subject.hostname}.yaml")).to be (false)
        end
      end

      it 'removes node from manifests' do
        Bebox::PROVISION_STEPS.each do |step|
          content = File.read("spec/fixtures/puppet/steps/#{step}/manifests/site.pp.test").gsub(/\s+/, ' ').strip
          output = File.read("#{subject.project_root}/puppet/steps/#{Bebox::Provision.step_name(step)}/manifests/site.pp").gsub(/\s+/, ' ').strip
          expect(output).to eq(content)
        end
      end
    end
  end
end