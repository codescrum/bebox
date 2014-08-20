require 'spec_helper'
require_relative '../spec/factories/role.rb'
require_relative '../lib/bebox/wizards/wizards_helper'

describe 'Test 07: Bebox::Role' do

  # include Wizard helper methods
  include Bebox::WizardsHelper

  describe 'Manage roles' do

    subject { build(:role) }

    before :all do
      subject.create
    end

    context '00: role creation' do

      it 'should validate the role name' do
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

      it 'should create role directories' do
        expect(Dir.exist?("#{subject.path}")).to be (true)
        expect(Dir.exist?("#{subject.path}/manifests")).to be (true)
      end

      it 'should generate the manifests file' do
        output_file = File.read("#{subject.path}/manifests/init.pp").strip
        expected_content = File.read('spec/fixtures/puppet/roles/manifests/init.pp.test').strip
        expect(output_file).to eq(expected_content)
      end
    end

    context '01: role list' do
      it 'should list roles' do
        current_roles = [subject.name]
        roles = Bebox::Role.list(subject.project_root)
        expect(roles).to include(*current_roles)
      end
    end

    context '02: role deletion' do
      it 'should delete role directory' do
        subject.remove
        expect(Dir.exist?("#{subject.path}")).to be (false)
      end
    end
  end
end