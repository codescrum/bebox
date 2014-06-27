require 'spec_helper'
require_relative '../spec/factories/profile.rb'

describe 'test_11: Bebox::Profile' do

  describe 'Manage profiles' do

    subject { build(:profile) }

    context 'profile creation' do
      it 'should create profile directories' do
        subject.create_profile_directory
        expect(Dir.exist?("#{subject.path}")).to be (true)
        expect(Dir.exist?("#{subject.path}/manifests")).to be (true)
      end
      it 'should generate the manifests file' do
        subject.generate_manifests_file
        output_file = File.read("#{subject.path}/manifests/init.pp").strip
        expected_content = File.read('spec/fixtures/puppet/profiles/manifests/init.pp.test').strip
        expect(output_file).to eq(expected_content)
      end
      it 'should generate the Puppetfile' do
        subject.generate_puppetfile
        output_file = File.read("#{subject.path}/Puppetfile").strip
        expected_content = File.read('spec/fixtures/puppet/profiles/Puppetfile.test').strip
        expect(output_file).to eq(expected_content)
      end
    end

    context 'profile list' do
      it 'should list profiles' do
        current_profiles = [subject.name]
        profiles = Bebox::Profile.list(subject.project_root)
        expect(profiles).to include(*current_profiles)
      end
    end

    context 'profile deletion' do
      it 'should delete profile directory' do
        subject.remove
        expect(Dir.exist?("#{subject.path}")).to be (false)
      end
    end
  end
end