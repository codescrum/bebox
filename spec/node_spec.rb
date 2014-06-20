require 'spec_helper'
require_relative '../spec/factories/node.rb'

describe 'test_05: Bebox::Node' do

  describe 'Nodes management' do

    subject { build(:node) }

    context 'node creation' do
      it 'should create checkpoint' do
        subject.create
        expect(File.exist?("#{subject.project_root}/.checkpoints/environments/#{subject.environment}/nodes/#{subject.hostname}.yml")).to be (true)
        node_content = File.read("#{subject.project_root}/.checkpoints/environments/#{subject.environment}/nodes/#{subject.hostname}.yml").gsub(/\s+/, ' ').strip
        node_output_content = File.read("spec/fixtures/node/node_0.test").gsub(/\s+/, ' ').strip
        expect(node_content).to eq(node_output_content)
      end

      it 'should list the current nodes' do
        current_nodes = [subject.hostname]
        nodes = Bebox::Node.list(subject.project_root, subject.environment, 'nodes')
        expect(nodes).to include(*current_nodes)
      end
    end

    context 'node deletion' do
      it 'should remove checkpoint' do
        subject.remove
        expect(File.exist?("#{subject.project_root}/.checkpoints/environments/#{subject.environment}/nodes/#{subject.hostname}.yml")).to be (false)
      end

      it 'should not list any nodes' do
        nodes = Bebox::Node.list(subject.project_root, subject.environment, 'nodes')
        expect(nodes.count).to eq(0)
      end
    end
  end
end