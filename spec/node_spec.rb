require 'spec_helper'
require_relative '../spec/factories/node.rb'

describe 'Test 04: Bebox::Node' do

  describe 'Nodes management' do

    subject { build(:node) }

    context 'node creation' do
      it 'should create checkpoint' do
        subject.create_node_checkpoint
        expect(File.exist?("#{subject.project_root}/.checkpoints/environments/#{subject.environment}/nodes/#{subject.hostname}.yml")).to be (true)
        node_content = File.read("#{subject.project_root}/.checkpoints/environments/#{subject.environment}/nodes/#{subject.hostname}.yml").gsub(/\s+/, ' ').strip
        ouput_template = Tilt::ERBTemplate.new('spec/fixtures/node/node_0.test.erb')
        node_output_content = ouput_template.render(nil, ip_address: subject.ip).gsub(/\s+/, ' ').strip
        expect(node_content).to eq(node_output_content)
      end

      it 'should list the current nodes' do
        current_nodes = [subject.hostname]
        nodes = Bebox::Node.list(subject.project_root, subject.environment, 'nodes')
        expect(nodes).to include(*current_nodes)
      end

      it 'should create hiera data template' do
        subject.create_hiera_template
        Bebox::PUPPET_STEPS.each do |step|
          expect(File.exist?("#{subject.project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/hiera/data/#{subject.hostname}.yaml")).to eq(true)
        end
      end

      it 'should create node in manifests file' do
        subject.create_manifests_node
        Bebox::PUPPET_STEPS.each do |step|
          content = File.read("spec/fixtures/puppet/steps/#{step}/manifests/site_with_node.pp.test").gsub(/\s+/, ' ').strip
          output = File.read("#{subject.project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp").gsub(/\s+/, ' ').strip
          expect(output).to eq(content)
        end
      end
    end

    context 'node deletion' do
      it 'should remove checkpoint' do
        subject.remove_checkpoints
        expect(File.exist?("#{subject.project_root}/.checkpoints/environments/#{subject.environment}/nodes/#{subject.hostname}.yml")).to be (false)
      end

      it 'should not list any nodes' do
        nodes = Bebox::Node.list(subject.project_root, subject.environment, 'nodes')
        expect(nodes.count).to eq(0)
      end

      it 'should remove hiera data' do
        subject.remove_hiera_template
        Bebox::PUPPET_STEPS.each do |step|
          expect(File.exist?("#{subject.project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/hiera/data/#{subject.hostname}.yaml")).to be (false)
        end
      end

      it 'should remove node from manifests' do
        subject.remove_manifests_node
        Bebox::PUPPET_STEPS.each do |step|
          content = File.read("spec/fixtures/puppet/steps/#{step}/manifests/site.pp.test").gsub(/\s+/, ' ').strip
          output = File.read("#{subject.project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp").gsub(/\s+/, ' ').strip
          expect(output).to eq(content)
        end
      end
    end
  end
end