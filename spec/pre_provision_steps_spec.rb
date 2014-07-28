require 'spec_helper'
require_relative '../spec/factories/role.rb'
require_relative '../spec/factories/profile.rb'
require_relative '../spec/factories/provision.rb'

describe 'Test 11: Pre provision apply step' do

  let(:provision) { build(:provision, step: 'step-2') }
  let(:role) { build(:role) }
  let(:profile) { build(:profile) }
  let(:profiles) { [profile.relative_path] }

  before :all do
    role.create
    profile.create
    Bebox::Role.add_profile(role.project_root, role.name, profile.relative_path)
    `cp spec/fixtures/puppet/profiles/#{profile.relative_path}/Puppetfile_with_modules.test #{profile.absolute_path}/Puppetfile`
  end

  it 'should generate a Puppetfile' do
    Bebox::Provision.generate_puppetfile(provision.project_root, provision.step, [profile.relative_path])
    output_file = File.read("#{provision.project_root}/puppet/steps/#{Bebox::Provision.step_name(provision.step)}/Puppetfile").gsub(/\s+/, ' ').strip
    expected_content = File.read("spec/fixtures/puppet/steps/#{provision.step}/Puppetfile.test").gsub(/\s+/, ' ').strip
    expect(output_file).to eq(expected_content)
  end

  it 'should generate the roles and profiles modules' do
    Bebox::Provision.generate_roles_and_profiles(provision.project_root, provision.step, role.name, [profile.relative_path])
    # Expect the role is created
    output_file = File.read("#{provision.project_root}/puppet/steps/#{Bebox::Provision.step_name(provision.step)}/modules/roles/manifests/#{role.name}.pp").gsub(/\s+/, ' ').strip
    expected_content = File.read("spec/fixtures/puppet/steps/#{provision.step}/modules/roles/manifests/#{role.name}.pp.test").gsub(/\s+/, ' ').strip
    expect(output_file).to eq(expected_content)
    # Expect the profiles are created
    profiles.each do |profile_name|
      output_file = File.read("#{provision.project_root}/puppet/steps/#{Bebox::Provision.step_name(provision.step)}/modules/profiles/manifests/#{profile_name}.pp").gsub(/\s+/, ' ').strip
      expected_content = File.read("spec/fixtures/puppet/steps/#{provision.step}/modules/profiles/manifests/#{profile_name}.pp.test").gsub(/\s+/, ' ').strip
      expect(output_file).to eq(expected_content)
    end
  end
end