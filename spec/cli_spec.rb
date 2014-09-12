require 'spec_helper'
require 'tilt'
require_relative 'factories/environment.rb'
require_relative 'factories/node.rb'
require_relative 'factories/profile.rb'
require_relative 'factories/role.rb'

describe 'Test 00: Bebox::Cli' do

  include FastGettext::Translation

  let(:environment) { build(:environment) }
  let(:node) { build(:node) }
  let(:profile) { build(:profile) }
  let(:role) { build(:role) }
  let(:version) { Bebox::VERSION }
  let(:program_desc) { _('cli.desc') }

  before :each do
    $stderr.stub(:write)
  end

  it 'shows the help for general commands' do
    argv = []
    output = capture(:stdout) { cli_command(argv, :success) }
    new_desc = _('cli.project.new.desc')
    command_output_template = Tilt::ERBTemplate.new('spec/fixtures/commands/general_help.erb.test')
    expected_content = command_output_template.render(nil, version: version, program_desc: program_desc, new_desc: new_desc).gsub(/\s+/, ' ').strip
    expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
  end

  context '00: general commands' do
    it 'shows error for new without project name' do
      argv = ['new']
      output = capture(:stdout) { cli_command(argv, :failure) }
      expect(output).to match(/#{_('cli.project.new.name_arg_missing')}/)
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
      Bebox::Environment.stub(:list) {['a', 'b', 'c']}
      argv = []
      output = capture(:stdout) { cli_command(argv, :success) }
      env_desc = _('cli.environment.desc')
      node_desc = _('cli.node.desc')
      command_output_template = Tilt::ERBTemplate.new('spec/fixtures/commands/in_project_help.erb.test')
      expected_content = command_output_template.render(nil, version: version, program_desc: program_desc, env_desc: env_desc, node_desc: node_desc).gsub(/\s+/, ' ').strip
      expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
    end

    context '02: environment commands' do

      it 'shows the help for environment commands' do
        argv = ['help', 'environment']
        output = capture(:stdout) { cli_command(argv, :success) }
        env_desc = _('cli.environment.desc')
        list_desc = _('cli.environment.list.desc')
        new_desc = _('cli.environment.new.desc')
        remove_desc = _('cli.environment.remove.desc')
        command_output_template = Tilt::ERBTemplate.new('spec/fixtures/commands/environment_help.erb.test')
        expected_content = command_output_template.render(nil, env_desc: env_desc, new_desc: new_desc, list_desc: list_desc, remove_desc: remove_desc).gsub(/\s+/, ' ').strip
        expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
      end

      it 'list environments' do
        Bebox::Environment.stub(:list) { [environment.name] }
        argv = ['environment', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/#{_('cli.environment.list.current_envs')}.*?#{environment.name}/im)
      end

      it 'not list environments if there are not any' do
        Bebox::Environment.stub(:list) { [] }
        argv = ['environment', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/#{_('cli.environment.list.current_envs')}.*?#{_('cli.environment.list.no_envs')}/im)
      end

      it 'fails to create a new environment without name' do
        Bebox::EnvironmentWizard.any_instance.stub(:send) { true }
        argv = ['environment', 'new']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/#{_('cli.environment.name_arg_missing')}/)
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
        expect(output).to match(/#{_('cli.environment.name_arg_missing')}/)
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
        node_desc = _('cli.node.desc')
        list_desc = _('cli.node.list.desc')
        new_desc = _('cli.node.new.desc')
        remove_desc = _('cli.node.remove.desc')
        env_flag_desc = _('cli.node.list.env_flag_desc')
        command_output_template = Tilt::ERBTemplate.new('spec/fixtures/commands/node_help.erb.test')
        expected_content = command_output_template.render(nil, node_desc: node_desc, new_desc: new_desc,
          list_desc: list_desc, remove_desc: remove_desc, env_flag_desc: env_flag_desc).gsub(/\s+/, ' ').strip
        expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
      end

      it 'list nodes if there are any' do
        Bebox::Node.stub(:list) { [node.hostname] }
        argv = ['node', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/#{_('cli.node.list.env_nodes_title')%{environment: node.environment}}.*?#{node.hostname}/m)
      end

      it 'not list nodes if there are not any' do
        Bebox::Node.stub(:list) { [] }
        argv = ['node', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/#{_('cli.node.list.env_nodes_title')%{environment: node.environment}}.*?#{_('cli.node.list.no_nodes')}/m)
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
        expect(output).to match(/#{_('cli.prepare.not_vagrant')}/m)
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
        profile_desc = _('cli.profile.desc')
        list_desc = _('cli.profile.list.desc')
        new_desc = _('cli.profile.new.desc')
        remove_desc = _('cli.profile.remove.desc')
        command_output_template = Tilt::ERBTemplate.new('spec/fixtures/commands/profile_help.erb.test')
        expected_content = command_output_template.render(nil, profile_desc: profile_desc,
          new_desc: new_desc, list_desc: list_desc, remove_desc: remove_desc).gsub(/\s+/, ' ').strip
        expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
      end

      it 'list profiles if there are any' do
        Bebox::ProfileWizard.any_instance.stub(:list_profiles) { [profile.name] }
        argv = ['profile', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/#{_('cli.profile.list.current_profiles')}.*?#{profile.name}/m)
      end

      it 'not list profiles if there are not any' do
        Bebox::ProfileWizard.any_instance.stub(:list_profiles) { [] }
        argv = ['profile', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/#{_('cli.profile.list.no_profiles')}/m)
      end

      it 'can not create a new profile without name' do
        argv = ['profile', 'new']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/#{_('cli.profile.new.name_arg_missing')}/)
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
        role_desc = _('cli.role.desc')
        list_desc = _('cli.role.list.desc')
        new_desc = _('cli.role.new.desc')
        remove_desc = _('cli.role.remove.desc')
        add_profile_desc = _('cli.role.add_profile.desc')
        remove_profile_desc = _('cli.role.remove_profile.desc')
        list_profiles_desc = _('cli.role.list_profiles.desc')
        command_output_template = Tilt::ERBTemplate.new('spec/fixtures/commands/role_help.erb.test')
        expected_content = command_output_template.render(nil, role_desc: role_desc, new_desc: new_desc,
          list_desc: list_desc, remove_desc: remove_desc, add_profile_desc: add_profile_desc,
          remove_profile_desc: remove_profile_desc, list_profiles_desc: list_profiles_desc).gsub(/\s+/, ' ').strip
        expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
      end

      it 'list roles if there are any' do
        Bebox::Role.stub(:list) { [role.name] }
        argv = ['role', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/#{_('cli.role.list.current_roles')}.*?#{role.name}/m)
      end

      it 'not list roles if there are not any' do
        Bebox::Role.stub(:list) { [] }
        argv = ['role', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/#{_('cli.role.list.no_roles')}/m)
      end

      it 'can not create a new role without name' do
        argv = ['role', 'new']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/#{_('cli.role.new.name_arg_missing')}/)
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
        expect(output).to match(/#{_('cli.role.list_profiles.name_arg_missing')}/m)
      end

      it 'can not list role profiles if role not exist' do
        Bebox::Role.stub(:list_profiles) { [] }
        Bebox::RoleWizard.any_instance.stub(:role_exists?) { false }
        argv = ['role', 'list_profiles', role.name]
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/#{_('cli.role.list_profiles.name_not_exist')%{role: role.name}}/m)
      end

      it 'not list role profiles if there are not any' do
        Bebox::RoleWizard.any_instance.stub(:role_exists?) { true }
        Bebox::Role.stub(:list_profiles) { [] }
        argv = ['role', 'list_profiles', role.name]
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/#{_('cli.role.list_profiles.no_profiles')%{role: role.name}}/m)
      end

      it 'list role profiles if there are any' do
        Bebox::RoleWizard.any_instance.stub(:role_exists?) { true }
        Bebox::Role.stub(:list_profiles) { [profile.name] }
        argv = ['role', 'list_profiles', role.name]
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/#{_('cli.role.list_profiles.current_profiles')%{role: role.name}}.*?#{profile.name}/m)
      end
    end

    context '07: provision commands' do

      before :each do
        Bebox::Node.stub(:count_all_nodes_by_type) { 1 }
      end

      it 'can not apply provision if the step is not supplied' do
        argv = ['apply']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/#{_('cli.provision.name_missing')}/m)
      end

      it 'can not apply provision if the step is not valid' do
        argv = ['apply', 'step']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/#{_('cli.provision.name_invalid')}/m)
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