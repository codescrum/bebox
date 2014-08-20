require 'spec_helper'
require_relative '../spec/factories/profile.rb'
require_relative '../lib/bebox/wizards/wizards_helper'

describe 'Test 08: Bebox::Profile' do

  # include Wizard helper methods
  include Bebox::WizardsHelper

  describe 'Manage profiles' do

    subject { build(:profile) }

    before :all do
      subject.create
    end

    context '00: profile creation' do

      it 'should validate the profile name' do
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

      it 'should clean the profile path' do
        # Profile path with slash
        expect(Bebox::Profile.cleanpath('/')).to eq ('')
        # Profile path with multiple slashes
        expect(Bebox::Profile.cleanpath('///basic//test///')).to eq ('basic/test')
        # Subject path is correct so would be the same
        expect(Bebox::Profile.cleanpath(subject.path)).to eq (subject.path)
      end

      it 'should create profile directories' do
        expect(Dir.exist?("#{subject.absolute_path}/manifests")).to be (true)
      end

      it 'should generate the manifests file' do
        output_file = File.read("#{subject.absolute_path}/manifests/init.pp").strip
        expected_content = File.read("spec/fixtures/puppet/profiles/#{subject.relative_path}/manifests/init.pp.test").strip
        expect(output_file).to eq(expected_content)
      end

      it 'should generate the Puppetfile' do
        output_file = File.read("#{subject.absolute_path}/Puppetfile").strip
        expected_content = File.read("spec/fixtures/puppet/profiles/#{subject.relative_path}/Puppetfile.test").strip
        expect(output_file).to eq(expected_content)
      end
    end

    context '01: profile list' do
      it 'should list profiles' do
        current_profiles = [subject.relative_path]
        profiles = Bebox::Profile.list(subject.project_root)
        expect(profiles).to include(*current_profiles)
      end
    end

    context '02: profile deletion' do
      it 'should delete profile directory' do
        subject.remove
        expect(Dir.exist?("#{subject.absolute_path}")).to be (false)
      end
    end
  end
end