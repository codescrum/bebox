require 'spec_helper'

require_relative '../spec/factories/node.rb'

describe 'Test 04: Manage nodes with the wizard' do

  subject { Bebox::NodeWizard }

  let(:project_root) { "#{Dir.pwd}/tmp/pname" }
  let(:environment) { "vagrant" }
  let(:node_hostname) { "node_0.server1.test" }
  let(:node_ip) { "192.168.0.70" }

  it 'should check node existence' do
    output = subject.node_exists?(project_root, environment, node_hostname)
    expect(output).to eq(false)
  end

  it 'should list no nodes' do
    current_nodes = []
    nodes = subject.list_nodes(project_root, environment, 'nodes')
    expect(nodes).to include(*current_nodes)
  end

  it 'the ip should be free' do
    expect(subject.free_ip?(node_ip)).to eq(true)
  end
end