require 'spec_helper'

require_relative '../factories/role.rb'
require_relative '../factories/profile.rb'

describe 'Test 03: Bebox::RoleWizard' do

  subject { Bebox::RoleWizard.new }

  let(:role) { build(:role) }
  let(:profile) { build(:profile) }

  before :each do
    $stdout.stub(:write)
  end

  it 'checks if a role exists' do
    output = subject.role_exists?(role.project_root, role.name)
    expect(output).to eq(false)
  end

  context '00: role not exist' do

    before :each do
      subject.stub(:role_exists?) { false }
    end

    it 'creates a new role with wizard' do
      Bebox::Role.any_instance.stub(:create) { true }
      output = subject.create_new_role(role.project_root, role.name)
      expect(output).to eq(true)
    end

    it 'can not removes a role if not exist any role' do
      Bebox::Role.stub(:list) {[]}
      output = subject.remove_role(role.project_root)
      expect(output).to eq(nil)
    end
  end

  context '01: role exist' do

    before :each do
      subject.stub(:role_exists?) { true }
    end

    it 'removes a role with wizard' do
      Bebox::Role.stub(:list) {[role.name]}
      Bebox::Role.any_instance.stub(:remove) { true }
      $stdin.stub(:gets).and_return('1', 'y')
      output = subject.remove_role(role.project_root)
      expect(output).to eq(true)
    end
  end

  context '02: role and profile exist' do

    before :each do
      subject.stub(:role_exists?) { true }
      Bebox::Profile.stub(:list) {[profile.relative_path]}
      Bebox::Role.stub(:list) {[role.name]}
    end

    it 'adds a profile to a role with wizard' do
      Bebox::Role.stub(:profile_in_role?) { false }
      Bebox::Role.stub(:add_profile) { true }
      $stdin.stub(:gets).and_return(role.name, profile.relative_path)
      output = subject.add_profile(role.project_root)
      expect(output).to eq(true)
    end

    context '03: profile included in a role' do

      it 'adds a profile to a role with wizard' do
        Bebox::Role.stub(:profile_in_role?) { true }
        $stdin.stub(:gets).and_return(role.name, profile.relative_path)
        output = subject.add_profile(role.project_root)
        expect(output).to eq(false)
      end

      it 'can not remove a profile that not exist in a role with wizard' do
        Bebox::Role.stub(:profile_in_role?) { false }
        $stdin.stub(:gets).and_return(role.name, profile.relative_path)
        output = subject.remove_profile(role.project_root)
        expect(output).to eq(false)
      end

      it 'removes a profile from a role with wizard' do
        Bebox::Role.stub(:profile_in_role?) { true }
        Bebox::Role.stub(:remove_profile) { true }
        $stdin.stub(:gets).and_return(role.name, profile.relative_path)
        output = subject.remove_profile(role.project_root)
        expect(output).to eq(true)
      end
    end
  end
end