require 'spec_helper'

require_relative '../factories/environment.rb'

describe 'Test 01: Bebox::EnvironmentWizard' do

  subject { Bebox::EnvironmentWizard.new }

  let(:environment) { build(:environment) }

  before :each do
    $stdout.stub(:write)
  end

  context '00: environment not exist' do
    it 'creates a new environment with wizard' do
      Bebox::Environment.stub(:environment_exists?) { false }
      Bebox::Environment.any_instance.stub(:create) { true }
      output = subject.create_new_environment(environment.project_root, environment.name)
      expect(output).to eq(true)
    end
  end

  context '01: environment exist' do
    it 'removes an environment with wizard' do
      Bebox::Environment.stub(:environment_exists?) { true }
      Bebox::Environment.any_instance.stub(:remove) { true }
      $stdin.stub(:gets).and_return('y')
      output = subject.remove_environment(environment.project_root, environment.name)
      expect(output).to eq(true)
    end
  end
end