require 'spec_helper'

require_relative '../spec/factories/provision.rb'

describe 'Test 14: Bebox::ProvisionWizard' do

  subject { Bebox::ProvisionWizard.new }

  let(:provision) { build(:provision) }

  context '00: apply step' do
    it 'apply a step with wizard' do
      Bebox::Provision.any_instance.stub_chain(:apply, :success?) { true }
      outputs = subject.apply_step(provision.project_root, provision.environment, provision.step)
      expect(outputs).to eq([true])
    end

    it 're-apply a step with wizard' do
      Bebox::Node.stub(:nodes_in_environment) { [provision.node] }
      Bebox::Node.stub(:list) { [provision.node.hostname] }
      Bebox::Node.any_instance.stub(:checkpoint_parameter_from_file) { '' }
      Bebox::Provision.any_instance.stub_chain(:apply, :success?) { true }
      $stdin.stub(:gets).and_return('y')
      outputs = subject.apply_step(provision.project_root, provision.environment, provision.step)
      expect(outputs).to eq([true])
    end

    it 'obtains the previous checkpoint for a node' do
      steps = %w{prepared_nodes step-0 step-1 step-2 step-3}
      expected_checkpoints = ['nodes',  'prepared_nodes', 'steps/step-0', 'steps/step-1', 'steps/step-2']
      checkpoints = []
      steps.each do |step|
        checkpoints << subject.previous_checkpoint(step)
      end
      expect(checkpoints).to include(*expected_checkpoints)
    end
  end
end