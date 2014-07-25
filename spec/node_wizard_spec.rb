require 'spec_helper'

require_relative '../spec/factories/node.rb'

describe 'Test 03: Manage nodes with the wizard' do

  subject { Bebox::NodeWizard.new }

  let(:project_root) { "#{Dir.pwd}/tmp/bebox_pname" }
  let(:environment) { "vagrant" }
  let(:node_hostname) { "node_0.server1.test" }
  let(:node_ip) { YAML.load_file('spec/support/config_specs.yaml')['test_ip'] }

  it 'should check node existence' do
    output = subject.node_exists?(project_root, environment, node_hostname)
    expect(output).to eq(false)
  end

  it 'the ip should be free' do
    expect(subject.free_ip?(node_ip)).to eq(true)
  end
end