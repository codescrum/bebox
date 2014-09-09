require 'spec_helper'
require_relative 'factories/node.rb'

describe 'Test 00: Bebox::Cli' do

  before :each do
    # $stderr.stub(:write)
  end

  it 'shows the help for general commands' do
    argv = []
    output = capture(:stdout) { cli_command(argv, :success) }
    expected_content = File.read("spec/fixtures/commands/general/help.test").gsub(/\s+/, ' ').strip
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
      expected_content = File.read("spec/fixtures/commands/project/help.test").gsub(/\s+/, ' ').strip
      expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
    end

    context '02: environment commands' do

      it 'shows the help for environment commands' do
        argv = ['help', 'environment']
        output = capture(:stdout) { cli_command(argv, :success) }
        expected_content = File.read("spec/fixtures/commands/project/environment/help.test").gsub(/\s+/, ' ').strip
        expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
      end

      it 'list environments' do
        Bebox::Environment.stub(:list) { ['a', 'b', 'c'] }
        argv = ['environment', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/Current environments:.*?a.*?b.*?c/im)
      end

      it 'fails to create a new environment without name' do
        Bebox::EnvironmentWizard.any_instance.stub(:send) { true }
        argv = ['environment', 'new']
        output = capture(:stdout) { cli_command(argv, :failure) }
        expect(output).to match(/You did not supply an environment/)
      end

      it 'creates a new environment with name' do
        Bebox::EnvironmentWizard.any_instance.stub(:send) { true }
        argv = ['environment', 'new', 'a']
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
        argv = ['environment', 'remove', 'a']
        capture(:stdout) { cli_command(argv, :success) }
      end
    end

    context '03: node commands' do

      let(:node) { build(:node) }

      before :each do
        Bebox::Environment.stub(:list) { [node.environment] }
      end

      it 'shows the help for node commands' do
        argv = ['help', 'node']
        output = capture(:stdout) { cli_command(argv, :success) }
        expected_content = File.read("spec/fixtures/commands/project/node/help.test").gsub(/\s+/, ' ').strip
        expect(output.gsub(/\s+/, ' ').strip).to eq(expected_content)
      end

      it 'list nodes' do
        Bebox::Node.stub(:list) { [node.hostname] }
        argv = ['node', 'list']
        output = capture(:stdout) { cli_command(argv, :success) }
        expect(output).to match(/Nodes for '#{node.environment}' environment:.*?#{node.hostname}/m)
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