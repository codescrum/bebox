require 'spec_helper'

describe 'Bebox::EnvironmentWizard' do

  subject { Bebox::EnvironmentWizard.new }

  let(:environment) { build(:environment) }

  before :each do
    $stdout.stub(:write)
  end

  context 'environment not exist' do

    before :each do
      Bebox::Environment.stub(:environment_exists?) { false }
    end

    it 'creates a new environment with wizard' do
      Bebox::Environment.any_instance.stub(:create) { true }
      output = subject.create_new_environment(environment.project_root, environment.name)
      expect(output).to eq(true)
    end
  end

  context 'environment exist' do

    before :each do
      Bebox::Environment.stub(:environment_exists?) { true }
    end

    it 'removes an environment with wizard' do
      Bebox::Environment.any_instance.stub(:remove) { true }
      $stdin.stub(:gets).and_return('y')
      output = subject.remove_environment(environment.project_root, environment.name)
      expect(output).to eq(true)
    end
  end
end