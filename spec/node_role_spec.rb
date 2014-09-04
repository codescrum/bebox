require 'spec_helper'
require_relative '../spec/factories/role.rb'
require_relative '../spec/factories/node.rb'
require_relative '../spec/factories/provision.rb'

describe 'Test 13: Associate node and role' do

  let(:role) { build(:role) }
  let(:nodes) { [build(:node)] }

  context 'set role' do
    it 'should add a role to a node' do
      node = nodes.first
      Bebox::Provision.associate_node_role(node.project_root, node.environment, node.hostname, role.name)
      expected_content = File.read('spec/fixtures/puppet/steps/step-2/manifests/site_with_node_role_association.pp.test').strip
      output_file = File.read("#{node.project_root}/puppet/steps/2-services/manifests/site.pp").strip
      expect(output_file).to eq(expected_content)
    end

    it 'gets the role from a node' do
      node = nodes.first
      expected_role = Bebox::Provision.role_from_node(node.project_root, 'step-2', node.hostname)
      expect(expected_role).to include(role.name)
    end
  end
end