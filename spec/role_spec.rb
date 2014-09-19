require 'spec_helper'

describe 'Bebox::Role', :fakefs do

  # include Wizard helper methods
  include Bebox::WizardsHelper

  let(:project) { build(:project) }
  subject { build(:role) }
  let(:temporary_role_profile) {Bebox::Profile.list(subject.project_root).first}
  let(:fixtures_path) { Pathname(__FILE__).dirname.parent + 'spec/fixtures' }

  before :all do
    FakeCmd.on!
    FakeCmd.add 'bundle', 0, true
    FakeCmd do
      project.create
      subject.create
    end
    FakeCmd.off!
  end

  context '00: role creation' do

    it 'validates the role name' do
      # Test not valid reserved words
      Bebox::RESERVED_WORDS.each{|reserved_word| expect(valid_puppet_class_name?(reserved_word)).to be (false)}
      # Test not valid start by undescore
      expect(valid_puppet_class_name?('_role_0')).to be (false)
      # Test not valid contain Upper letter
      expect(valid_puppet_class_name?('Role_0')).to be (false)
      # Test not valid contain dash character
      expect(valid_puppet_class_name?('role-0')).to be (false)
      # Test valid name not contains reserved words, start with letter, contains only downcase letters, numbers and undescores
      expect(valid_puppet_class_name?(subject.name)).to be (true)
    end

    it 'creates the role directories' do
      expect(Dir.exist?("#{subject.path}")).to be (true)
      expect(Dir.exist?("#{subject.path}/manifests")).to be (true)
    end

    it 'generates the manifests file' do
      output_file = File.read("#{subject.path}/manifests/init.pp").strip
      expected_content = File.read("#{fixtures_path}/puppet/roles/manifests/init.pp.test").strip
      expect(output_file).to eq(expected_content)
    end
  end

  context '01: role list' do
    it 'list the roles' do
      current_roles = [subject.name]
      roles = Bebox::Role.list(subject.project_root)
      expect(roles).to include(*current_roles)
    end
  end

  context '02: self methods' do
    it 'counts the number of roles in the project' do
      roles_count = Bebox::Role.roles_count(subject.project_root)
      expect(roles_count).to eq(4)
    end

    it 'adds a profile to a role' do
      profile_include = "include profiles::#{temporary_role_profile.gsub('/','::')}"
      Bebox::Role.add_profile(subject.project_root, subject.name, temporary_role_profile)
      role_content = File.read("#{subject.path}/manifests/init.pp").strip
      expect(role_content).to include(profile_include)
    end

    it 'list the profiles in a role' do
      expected_profiles = [temporary_role_profile]
      profiles = Bebox::Role.list_profiles(subject.project_root, subject.name)
      expect(profiles).to eq(expected_profiles)
    end

    it 'checks if a role contains a given profile' do
      profile_in_role = Bebox::Role.profile_in_role?(subject.project_root, subject.name, temporary_role_profile)
      expect(profile_in_role).to eq(true)
    end

    it 'removes a profile from a role' do
      profile_include = "include profiles::#{temporary_role_profile.gsub('/','::')}"
      Bebox::Role.remove_profile(subject.project_root, subject.name, temporary_role_profile)
      role_content = File.read("#{subject.path}/manifests/init.pp").strip
      expect(role_content).to_not include(profile_include)
    end
  end

  context '03: role deletion' do
    it 'deletes the role directory' do
      subject.remove
      expect(Dir.exist?("#{subject.path}")).to be (false)
    end
  end
end