require 'spec_helper'
require_relative '../spec/factories/project.rb'
require_relative '../spec/factories/role.rb'
require_relative '../spec/factories/profile.rb'

describe 'Bebox::Role, Bebox::Profile association' do

  let(:project) { build(:project) }
  let(:role) { build(:role) }
  let(:profile) { build(:profile) }
  let(:lib_path) { Pathname(__FILE__).dirname.parent + 'lib' }

  before :all do
    FakeFS::FileSystem.clone(Pathname(__FILE__).dirname.parent + 'spec/fixtures')
    FakeFS::FileSystem.clone("#{lib_path}/templates")
    FakeFS::FileSystem.clone("#{lib_path}/deb")
    FakeFS.activate!
    FakeCmd.on!
    FakeCmd.add 'bundle', 0, true
    FakeCmd do
      project.create
      role.create
      profile.create
    end
    FakeCmd.off!
  end

  after :all do
    FakeCmd.clear!
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
  end

  context 'add profiles' do
    it 'should add a profile to a role' do
      role_content = "include profiles::#{profile.namespace_name}"
      Bebox::Role.add_profile(role.project_root, role.name, profile.relative_path)
      output_file = File.read("#{role.path}/manifests/init.pp").strip
      expect(output_file).to include(role_content)
    end
  end

  context 'list profiles' do
    it 'should list profiles' do
      current_profiles = [profile.relative_path]
      profiles = Bebox::Role.list_profiles(role.project_root, role.name)
      expect(profiles).to include(*current_profiles)
    end
  end

  context 'remove profiles' do
    it 'should delete profile in a role' do
      role_content = "include profiles::#{profile.namespace_name}"
      Bebox::Role.remove_profile(role.project_root, role.name, profile.relative_path)
      output_file = File.read("#{role.path}/manifests/init.pp").strip
      expect(output_file).to_not include(role_content)
    end
  end
end