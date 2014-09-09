require 'spec_helper'
require_relative '../spec/factories/role.rb'
require_relative '../spec/factories/profile.rb'

describe 'Test 14: Associate roles and profiles' do

  let(:role) { build(:role) }
  let(:profile) { build(:profile) }

  before :all do
    role.create
    profile.create
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