require 'spec_helper'

require_relative '../spec/factories/environment.rb'

describe 'Test 02: Bebox::EnvironmentWizard' do

  subject { Bebox::EnvironmentWizard.new }

  let(:environment) { build(:environment) }

  before :each do
    $stdout.stub(:write)
  end

  after :all do
    environment.remove
  end

  context '00: environment not exist' do
    it 'creates a new environment with wizard' do
      Bebox::Environment.any_instance.stub(:create) { true }
      output = subject.create_new_environment(environment.project_root, environment.name)
      expect(output).to eq(true)
    end
  end

  context '01: environment exist' do
    before :all do
      environment.create
    end

    it 'removes an environment with wizard' do
      Bebox::Environment.any_instance.stub(:remove) { true }
      $stdin.stub(:gets).and_return('y')
      output = subject.remove_environment(environment.project_root, environment.name)
      expect(output).to eq(true)
    end
  end
end