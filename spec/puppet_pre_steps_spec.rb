require 'spec_helper'
require_relative '../spec/factories/role.rb'
require_relative '../spec/factories/profile.rb'
require_relative '../spec/factories/puppet.rb'

describe 'Test 11: Puppet pre apply step' do

  let(:puppet) { build(:puppet, step: 'step-2') }
  let(:role) { build(:role) }
  let(:profile) { build(:profile) }
  let(:profiles) { [profile.name] }

  before :all do
    role.create
    profile.create
    Bebox::Role.add_profile(role.project_root, role.name, profile.name)
    `cp spec/fixtures/puppet/profiles/profile_0/Puppetfile_with_modules.test #{puppet.project_root}/puppet/profiles/profile_0/Puppetfile`
  end

  it 'should generate a Puppetfile' do
    Bebox::Puppet.generate_puppetfile(puppet.project_root, puppet.step, [profile.name])
    output_file = File.read("#{puppet.project_root}/puppet/steps/#{Bebox::Puppet.step_name(puppet.step)}/Puppetfile").gsub(/\s+/, ' ').strip
    expected_content = File.read("spec/fixtures/puppet/steps/#{puppet.step}/Puppetfile.test").gsub(/\s+/, ' ').strip
    expect(output_file).to eq(expected_content)
  end

  it 'should generate the roles and profiles modules' do
    Bebox::Puppet.generate_roles_and_profiles(puppet.project_root, puppet.step, role.name, [profile.name])
    # Expect the role is created
    output_file = File.read("#{puppet.project_root}/puppet/steps/#{Bebox::Puppet.step_name(puppet.step)}/modules/roles/manifests/#{role.name}.pp").gsub(/\s+/, ' ').strip
    expected_content = File.read("spec/fixtures/puppet/steps/#{puppet.step}/modules/roles/manifests/#{role.name}.pp.test").gsub(/\s+/, ' ').strip
    expect(output_file).to eq(expected_content)
    # Expect the profiles are created
    profiles.each do |profile_name|
      output_file = File.read("#{puppet.project_root}/puppet/steps/#{Bebox::Puppet.step_name(puppet.step)}/modules/profiles/manifests/#{profile_name}.pp").gsub(/\s+/, ' ').strip
      expected_content = File.read("spec/fixtures/puppet/steps/#{puppet.step}/modules/profiles/manifests/#{profile_name}.pp.test").gsub(/\s+/, ' ').strip
      expect(output_file).to eq(expected_content)
    end
  end
end