require 'spec_helper'

require_relative '../spec/factories/environment.rb'

describe 'test_02: Manage environments with the wizard' do

  subject { Bebox::EnvironmentWizard }

  let(:project_root) { "#{Dir.pwd}/tmp/pname" }

  it 'should check environment existence' do
    output = subject.environment_exists?(project_root, 'vagrant')
    expect(output).to eq(true)
  end

  it 'should list current environments' do
    current_environments = %w{vagrant staging production}
    environments = subject.list_environments(project_root)
    expect(environments).to include(*current_environments)
  end

end