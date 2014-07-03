require 'spec_helper'

describe 'test_14: Puppet pre apply Service layer step-2' do

  let(:project_root) { "#{Dir.pwd}/tmp/pname" }
  let(:step) { 'step-2' }
  let(:node) { 'node0.server1.test' }
  let(:role) { Bebox::Puppet.role_from_node(project_root, step, node) }
  let(:profiles) { Bebox::Puppet.profiles_from_role(project_root, role) }

  before :all do
    `cp spec/fixtures/puppet/profiles/profile_0/Puppetfile_with_modules.test #{project_root}/puppet/profiles/profile_0/Puppetfile`
  end

  it 'should generate a Puppetfile' do
    Bebox::Puppet.generate_puppetfile(project_root, step, profiles)
    output_file = File.read("#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/Puppetfile").strip
    expected_content = File.read("spec/fixtures/puppet/steps/#{step}/Puppetfile.test").strip
    expect(output_file).to eq(expected_content)
  end

  it 'should generate the roles and profiles modules' do
    Bebox::Puppet.generate_roles_and_profiles(project_root, step, role, profiles)
    # Expect the role is created
    output_file = File.read("#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/modules/roles/manifests/#{role}.pp").strip
    expected_content = File.read("spec/fixtures/puppet/steps/#{step}/modules/roles/manifests/#{role}.pp.test").strip
    expect(output_file).to eq(expected_content)
    # Expect the profiles are created
    profiles.each do |profile|
      output_file = File.read("#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/modules/profiles/manifests/#{profile}.pp").strip
      expected_content = File.read("spec/fixtures/puppet/steps/#{step}/modules/profiles/manifests/#{profile}.pp.test").strip
      expect(output_file).to eq(expected_content)
    end
  end
end