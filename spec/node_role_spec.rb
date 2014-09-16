require 'spec_helper'
require_relative '../spec/factories/project.rb'
require_relative '../spec/factories/role.rb'
require_relative '../spec/factories/node.rb'
require_relative '../spec/factories/provision.rb'

describe 'Bebox::Node, Bebox::Role association' do

  let(:project) { build(:project) }
  let(:role) { build(:role) }
  let(:node) { build(:node) }
  let(:lib_path) { Pathname(__FILE__).dirname.parent + 'lib' }
  let(:fixtures_path) { Pathname(__FILE__).dirname.parent + 'spec/fixtures' }

  before :all do
    FakeFS::FileSystem.clone(fixtures_path)
    FakeFS::FileSystem.clone("#{lib_path}/templates")
    FakeFS::FileSystem.clone("#{lib_path}/deb")
    FakeFS.activate!
    FakeCmd.on!
    FakeCmd.add 'bundle', 0, true
    FakeCmd do
      project.create
      node.create
    end
    FakeCmd.off!
  end

  after :all do
    FakeCmd.clear!
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
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