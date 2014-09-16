require 'spec_helper'

describe 'Bebox::Node, Bebox::Role association', :fakefs do

  let(:project) { build(:project) }
  let(:role) { build(:role) }
  let(:node) { build(:node) }
  let(:fixtures_path) { Pathname(__FILE__).dirname.parent + 'spec/fixtures' }

  before :all do
    FakeCmd.on!
    FakeCmd.add 'bundle', 0, true
    FakeCmd do
      project.create
      node.create
    end
    FakeCmd.off!
  end

  context 'set role' do
    it 'should add a role to a node' do
      Bebox::Provision.associate_node_role(node.project_root, node.environment, node.hostname, role.name)
      expected_content = File.read("#{fixtures_path}/puppet/steps/step-2/manifests/site_with_node_role_association.pp.test").strip
      output_file = File.read("#{node.project_root}/puppet/steps/2-services/manifests/site.pp").strip
      expect(output_file).to eq(expected_content)
    end

    it 'gets the role from a node' do
      expected_role = Bebox::Provision.role_from_node(node.project_root, 'step-2', node.hostname)
      expect(expected_role).to include(role.name)
    end
  end
end