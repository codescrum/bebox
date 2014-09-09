require 'spec_helper'
require_relative 'factories/environment.rb'
require_relative 'factories/node.rb'
require_relative 'factories/profile.rb'
require_relative 'factories/role.rb'

describe 'Test 00: Bebox::Cli' do

  let(:environment) { build(:environment) }
  let(:node) { build(:node) }
  let(:profile) { build(:profile) }
  let(:role) { build(:role) }

  before :each do
    # $stderr.stub(:write)
  end

  it 'shows the help for general commands' do
    argv = []
    output = capture(:stdout) { cli_command(argv, :success) }
    expected_content = File.read("spec/fixtures/commands/general_help.test").gsub(/\s+/, ' ').strip
    expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
  end

  context '00: general commands' do
    it 'shows error for new without project name' do
      argv = ['new']
      output = capture(:stdout) { cli_command(argv, :failure) }
      expect(output).to match(/You did not supply a project name/)
    end

    it 'executes new project command' do
      argv = ['new', 'pname']
      Bebox::ProjectWizard.any_instance.stub(:create_new_project) { true }
      capture(:stdout) { cli_command(argv, :success) }
    end
  end

  context '01: project commands' do

    before :each do
      Bebox::Cli.any_instance.stub(:inside_project?) { true }
      Bebox::Environment.stub(:environment_exists?) { true }
    end

    it 'shows the help for project commands' do
      argv = []
      output = capture(:stdout) { cli_command(argv, :success) }
      expected_content = File.read("spec/fixtures/commands/in_project_help.test").gsub(/\s+/, ' ').strip
      expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
    end

    context '02: environment commands' do

      it 'shows the help for environment commands' do
        argv = ['help', 'environment']
        output = capture(:stdout) { cli_command(argv, :success) }
        expected_content = File.read("spec/fixtures/commands/environment_help.test").gsub(/\s+/, ' ').strip
        expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
      end

      it 'list environments' do
        Bebox::Environment.stub(:list) { [environment.name] }
        argv = ['environment', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/Current environments:.*?#{environment.name}/im)
      end

      it 'not list environments if there are not any' do
        Bebox::Environment.stub(:list) { [] }
        argv = ['environment', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/Current environments:.*?There are not environments yet. You can create a new one with: 'bebox environment new' command./im)
      end

      it 'fails to create a new environment without name' do
        Bebox::EnvironmentWizard.any_instance.stub(:send) { true }
        argv = ['environment', 'new']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/You did not supply an environment/)
      end

      it 'creates a new environment with name' do
        Bebox::EnvironmentWizard.any_instance.stub(:send) { true }
        argv = ['environment', 'new', environment.name]
        capture(:stdout) { cli_command(argv, :success) }
      end

      it 'fails to remove an environment without name' do
        Bebox::EnvironmentWizard.any_instance.stub(:send) { true }
        argv = ['environment', 'remove']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/You did not supply an environment/)
      end

      it 'removes an environment with name' do
        Bebox::EnvironmentWizard.any_instance.stub(:send) { true }
        argv = ['environment', 'remove', environment.name]
        capture(:stdout) { cli_command(argv, :success) }
      end
    end

    context '03: node commands' do

      before :each do
        Bebox::Environment.stub(:list) { [node.environment] }
      end

      it 'shows the help for node commands' do
        argv = ['help', 'node']
        output = capture(:stdout) { cli_command(argv, :success) }
        expected_content = File.read("spec/fixtures/commands/node_help.test").gsub(/\s+/, ' ').strip
        expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
      end

      it 'list nodes if there are any' do
        Bebox::Node.stub(:list) { [node.hostname] }
        argv = ['node', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/Nodes for '#{node.environment}' environment:.*?#{node.hostname}/m)
      end

      it 'not list nodes if there are not any' do
        Bebox::Node.stub(:list) { [] }
        argv = ['node', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/Nodes for '#{node.environment}' environment:.*?There are not nodes yet in the environment. You can create a new one with: 'bebox node new' command./m)
      end

      it 'sets a role for a node' do
        Bebox::Profile.stub(:profiles_count) { 1 }
        Bebox::Role.stub(:roles_count) { 1 }
        Bebox::Node.stub(:count_all_nodes_by_type) { 1 }
        Bebox::NodeWizard.any_instance.stub(:send) { true }
        argv = ['node', 'set_role']
        capture(:stdout) { cli_command(argv, :success) }
      end

      it 'creates a new node' do
        Bebox::NodeWizard.any_instance.stub(:send) { true }
        argv = ['node', 'new']
        capture(:stdout) { cli_command(argv, :success) }
      end

      it 'removes a node' do
        Bebox::EnvironmentWizard.any_instance.stub(:send) { true }
        argv = ['node', 'remove']
        capture(:stdout) { cli_command(argv, :success) }
      end
    end

    context '04: prepare commands' do

      before :each do
        Bebox::Node.stub(:count_all_nodes_by_type) { 1 }
        Bebox::Node.stub(:list) { [node] }
        Bebox::Node.stub(:nodes_in_environment) { [node] }
      end

      it 'shows an error if vagrant is not installed' do
        Bebox::CommandsHelper.stub(:vagrant_installed?) { false }
        argv = ['prepare']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/Vagrant is not installed in the system. No changes were made./m)
      end

      it 'prepares a node' do
        Bebox::NodeWizard.any_instance.stub(:prepare) { true }
        argv = ['prepare']
        output = capture(:stdout) { cli_command(argv, :success) }
      end

      it 'halts a vagrant node' do
        Bebox::VagrantHelper.stub(:send) { true }
        argv = ['vagrant_halt']
        capture(:stdout) { cli_command(argv, :success) }
      end

      it 'ups a vagrant node' do
        Bebox::VagrantHelper.stub(:send) { true }
        argv = ['vagrant_up']
        capture(:stdout) { cli_command(argv, :success) }
      end
    end

    context '05: profile commands' do

      before :each do
        Bebox::Node.stub(:count_all_nodes_by_type) { 1 }
      end

      it 'shows the help for profile commands' do
        argv = ['help', 'profile']
        output = capture(:stdout) { cli_command(argv, :success) }
        expected_content = File.read("spec/fixtures/commands/profile_help.test").gsub(/\s+/, ' ').strip
        expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
      end

      it 'list profiles if there are any' do
        Bebox::ProfileWizard.any_instance.stub(:list_profiles) { [profile.name] }
        argv = ['profile', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/Current profiles:.*?#{profile.name}/m)
      end

      it 'not list profiles if there are not any' do
        Bebox::ProfileWizard.any_instance.stub(:list_profiles) { [] }
        argv = ['profile', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/There are not profiles yet. You can create a new one with: 'bebox profile new' command./m)
      end

      it 'can not create a new profile without name' do
        argv = ['profile', 'new']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/You did not supply a name/)
      end

      it 'creates a new profile with name' do
        Bebox::ProfileWizard.any_instance.stub(:create_new_profile) { true }
        argv = ['profile', 'new', profile.name]
        capture(:stdout) { cli_command(argv, :success) }
      end

      it 'removes a profile' do
        Bebox::ProfileWizard.any_instance.stub(:remove_profile) { true }
        argv = ['profile', 'remove', profile.name]
        capture(:stdout) { cli_command(argv, :success) }
      end
    end

    context '06: role commands' do

      before :each do
        Bebox::Profile.stub(:profiles_count) { 1 }
        Bebox::Role.stub(:roles_count) { 1 }
        Bebox::Node.stub(:count_all_nodes_by_type) { 1 }
      end

      it 'shows the help for role commands' do
        argv = ['help', 'role']
        output = capture(:stdout) { cli_command(argv, :success) }
        expected_content = File.read("spec/fixtures/commands/role_help.test").gsub(/\s+/, ' ').strip
        expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
      end

      it 'list roles if there are any' do
        Bebox::Role.stub(:list) { [role.name] }
        argv = ['role', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/Current roles:.*?#{role.name}/m)
      end

      it 'not list roles if there are not any' do
        Bebox::Role.stub(:list) { [] }
        argv = ['role', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/There are not roles yet. You can create a new one with: 'bebox role new' command./m)
      end

      it 'can not create a new role without name' do
        argv = ['role', 'new']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/You did not supply a name/)
      end

      it 'creates a new role with name' do
        Bebox::ProfileWizard.any_instance.stub(:create_new_role) { true }
        argv = ['role', 'new', role.name]
        capture(:stdout) { cli_command(argv, :success) }
      end

      it 'removes a role' do
        Bebox::RoleWizard.any_instance.stub(:send) { true }
        argv = ['role', 'remove']
        capture(:stdout) { cli_command(argv, :success) }
      end

      it 'can not list role profiles without a role name' do
        argv = ['role', 'list_profiles']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/You did not supply a role name./m)
      end

      it 'can not list role profiles if role not exist' do
        Bebox::RoleWizard.any_instance.stub(:role_exists?) { false }
        argv = ['role', 'list_profiles', role.name]
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/The '#{role.name}' role does not exist./m)
      end

      it 'not list role profiles if there are not any' do
        Bebox::RoleWizard.any_instance.stub(:role_exists?) { true }
        Bebox::Role.stub(:list_profiles) { [] }
        argv = ['role', 'list_profiles', role.name]
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/There are not profiles in role '#{role.name}'. You can add a new one with: 'bebox role add_profile' command./m)
      end

      it 'list role profiles if there are any' do
        Bebox::RoleWizard.any_instance.stub(:role_exists?) { true }
        Bebox::Role.stub(:list_profiles) { [profile.name] }
        argv = ['role', 'list_profiles', role.name]
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/Current profiles in '#{role.name}' role:.*?#{profile.name}/m)
      end
    end

    context '07: provision commands' do

      before :each do
        Bebox::Node.stub(:count_all_nodes_by_type) { 1 }
      end

      it 'can not apply provision if the step is not supplied' do
        argv = ['apply']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/You did not specify an step/m)
      end

      it 'can not apply provision if the step is not valid' do
        argv = ['apply', 'step']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/You did not specify a valid step/m)
      end

      it 'applies provision if the step is valid' do
        Bebox::ProvisionWizard.any_instance.stub(:apply_step) { true }
        argv = ['apply', 'step-0']
        output = capture(:stdout) { cli_command(argv, :success) }
      end

      it 'applies provision in all steps' do
        Bebox::ProvisionWizard.any_instance.stub(:apply_step) { true }
        argv = ['apply', '--all']
        output = capture(:stdout) { cli_command(argv, :success) }
      end
    end
  end
end

# Helper method to capture the STDOUT from commands
def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
  end
  result
end

# Executes a cli command and do expectation from return status
def cli_command(argv, expectation)
  begin
    Bebox::Cli.new(argv)
  rescue SystemExit => e
    if expectation == :success
      expect([0, 1]).to include(e.status)
    else
      expect([0, 1]).to_not include(e.status)
    end
  end
end