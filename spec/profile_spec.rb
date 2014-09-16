require 'spec_helper'

describe 'Bebox::Profile', :fakefs do

  # include Wizards helper methods
  include Bebox::WizardsHelper

  subject { build(:profile) }
  let(:project) { build(:project) }
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

  context 'profile creation' do

    it 'validates the profile name' do
      # Test not valid reserved words
      Bebox::RESERVED_WORDS.each{|reserved_word| expect(valid_puppet_class_name?(reserved_word)).to be (false)}
      # Test not valid start by undescore
      expect(valid_puppet_class_name?('_profile_0')).to be (false)
      # Test not valid contain Upper letter
      expect(valid_puppet_class_name?('Profile_0')).to be (false)
      # Test not valid contain dash character
      expect(valid_puppet_class_name?('profile-0')).to be (false)
      # Test valid name not contains reserved words, start with letter, contains only downcase letters, numbers and undescores
      expect(valid_puppet_class_name?(subject.name)).to be (true)
    end

    it 'cleans the profile path' do
      # Profile path with slash
      expect(Bebox::Profile.cleanpath('/')).to eq ('')
      # Profile path with multiple slashes
      expect(Bebox::Profile.cleanpath('///basic//test///')).to eq ('basic/test')
      # Subject path is correct so would be the same
      expect(Bebox::Profile.cleanpath(subject.path)).to eq (subject.path)
    end

    it 'creates profile directories' do
      expect(Dir.exist?("#{subject.absolute_path}/manifests")).to be (true)
    end

    it 'generates the manifests file' do
      output_file = File.read("#{subject.absolute_path}/manifests/init.pp").strip
      expected_content = File.read("#{fixtures_path}/puppet/profiles/#{subject.relative_path}/manifests/init.pp.test").strip
      expect(output_file).to eq(expected_content)
    end

    it 'generates the Puppetfile' do
      output_file = File.read("#{subject.absolute_path}/Puppetfile").strip
      expected_content = File.read("#{fixtures_path}/puppet/profiles/#{subject.relative_path}/Puppetfile.test").strip
      expect(output_file).to eq(expected_content)
    end
  end

  context 'profile list' do
    it 'list the profiles' do
      current_profiles = [subject.relative_path]
      profiles = Bebox::Profile.list(subject.project_root)
      expect(profiles).to include(*current_profiles)
    end
  end

  context 'profile deletion' do
    it 'deletes the profile directory' do
      subject.remove
      expect(Dir.exist?("#{subject.absolute_path}")).to be (false)
    end
  end

  context 'self methods' do
    it 'counts the number of profiles in the project' do
      profiles_count = Bebox::Profile.profiles_count(subject.project_root)
      expect(profiles_count).to eq(9)
    end

    it 'validates a profile with path' do
      path = 'basic/test'
      valid_path = Bebox::Profile.valid_pathname?(path)
      expect(valid_path).to eq(true)
    end
  end
end