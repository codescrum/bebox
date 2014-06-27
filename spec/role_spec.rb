require 'spec_helper'
require_relative '../spec/factories/role.rb'

describe 'test_10: Bebox::Role' do

  describe 'Manage roles' do

    subject { build(:role) }

    context 'role creation' do
      it 'should create role directories' do
        subject.create_role_directory
        expect(Dir.exist?("#{subject.path}")).to be (true)
        expect(Dir.exist?("#{subject.path}/manifests")).to be (true)
      end
      it 'should generate the manifests file' do
        subject.generate_manifests_file
        output_file = File.read("#{subject.path}/manifests/init.pp").strip
        expected_content = File.read('spec/fixtures/puppet/roles/manifests/init.pp.test').strip
        expect(output_file).to eq(expected_content)
      end
    end

    context 'role list' do
      it 'should list roles' do
        current_roles = [subject.name]
        roles = Bebox::Role.list(subject.project_root)
        expect(roles).to include(*current_roles)
      end
    end

    context 'role deletion' do
      it 'should delete role directory' do
        subject.remove
        expect(Dir.exist?("#{subject.path}")).to be (false)
      end
    end
  end
end