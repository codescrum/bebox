require 'spec_helper'
require_relative '../spec/factories/profile.rb'

describe 'Test 08: Bebox::Profile' do

  describe 'Manage profiles' do

    subject { build(:profile) }

    before :all do
      subject.create
    end

    context '00: profile creation' do

      it 'should validate the profile name' do
        # Test not valid reserved words
        Bebox::RESERVED_WORDS.each{|reserved_word| expect(Bebox::Profile.valid_name?(reserved_word)).to be (false)}
        # Test not valid start by undescore
        expect(Bebox::Profile.valid_name?('_profile_0')).to be (false)
        # Test not valid contain Upper letter
        expect(Bebox::Profile.valid_name?('Profile_0')).to be (false)
        # Test not valid contain dash character
        expect(Bebox::Profile.valid_name?('profile-0')).to be (false)
        # Test valid name not contains reserved words, start with letter, contains only downcase letters, numbers and undescores
        expect(Bebox::Profile.valid_name?(subject.name)).to be (true)
      end

      it 'should create profile directories' do
        expect(Dir.exist?("#{subject.path}")).to be (true)
        expect(Dir.exist?("#{subject.path}/manifests")).to be (true)
      end

      it 'should generate the manifests file' do
        output_file = File.read("#{subject.path}/manifests/init.pp").strip
        expected_content = File.read("spec/fixtures/puppet/profiles/#{subject.name}/manifests/init.pp.test").strip
        expect(output_file).to eq(expected_content)
      end

      it 'should generate the Puppetfile' do
        output_file = File.read("#{subject.path}/Puppetfile").strip
        expected_content = File.read("spec/fixtures/puppet/profiles/#{subject.name}/Puppetfile.test").strip
        expect(output_file).to eq(expected_content)
      end
    end

    context '01: profile list' do
      it 'should list profiles' do
        current_profiles = [subject.name]
        profiles = Bebox::Profile.list(subject.project_root)
        expect(profiles).to include(*current_profiles)
      end
    end

    context '02: profile deletion' do
      it 'should delete profile directory' do
        subject.remove
        expect(Dir.exist?("#{subject.path}")).to be (false)
      end
    end
  end
end