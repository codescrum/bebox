require 'spec_helper'

describe 'Bebox::Node', :fakefs do

  let(:project) { build(:project) }
  subject { build(:node) }
  let(:fixtures_path) { Pathname(__FILE__).dirname.parent + 'spec/fixtures' }

  before :all do
    FakeCmd.on!
    FakeCmd.add 'bundle', 0, true
    FakeCmd do
      project.create
    end
    FakeCmd.off!
  end

  context 'node creation' do

    before :all do
      subject.create
    end

    it 'creates the serverspec node' do
      expect(Dir.exist?("#{subject.project_root}/spec/#{subject.hostname}")).to be true
    end

    it 'creates the serverspec connectors' do
      expect(File.exist?("#{subject.project_root}/spec/#{subject.hostname}/vagrant_connector.rb")).to be true
      expect(File.exist?("#{subject.project_root}/spec/#{subject.hostname}/puppet_connector.rb")).to be true
    end

    it 'creates the serverspec spec files' do
      expect(File.exist?("#{subject.project_root}/spec/#{subject.hostname}/phase-1_prepare_spec.rb")).to be true
      Bebox::PROVISION_STEPS.each do |step|
        expect(File.exist?("#{subject.project_root}/spec/#{subject.hostname}/phase-2_#{step}_prepare_spec.rb")).to be true
      end
    end

    it 'creates hiera data template' do
      Bebox::PROVISION_STEPS.each do |step|
        expect(File.exist?("#{subject.project_root}/puppet/steps/#{step}/hiera/data/#{subject.hostname}.yaml")).to eq(true)
      end
    end

    it 'creates node in manifests file' do
      Bebox::PROVISION_STEPS.each do |step|
        content = File.read("#{fixtures_path}/puppet/steps/#{step}/manifests/site_with_node.pp.test").gsub(/\s+/, ' ').strip
        output = File.read("#{subject.project_root}/puppet/steps/#{step}/manifests/site.pp").gsub(/\s+/, ' ').strip
        expect(output).to eq(content)
      end
    end

    it 'creates checkpoint' do
      node_checkpoint_path = "#{subject.project_root}/.checkpoints/environments/#{subject.environment}/phases/phase-0/#{subject.hostname}.yml"
      expect(File.exist?(node_checkpoint_path)).to be (true)
      node_content = File.read(node_checkpoint_path).gsub(/\s+/, ' ').strip
      ouput_template = Tilt::ERBTemplate.new("#{fixtures_path}/node/node_0.test.erb")
      node_output_content = ouput_template.render(nil, node: subject).gsub(/\s+/, ' ').strip
      expect(node_content).to eq(node_output_content)
    end

    it 'list the current nodes' do
      current_nodes = [subject.hostname]
      nodes = Bebox::Node.list(subject.project_root, subject.environment, 'phase-0')
      expect(nodes).to include(*current_nodes)
    end

    it 'gets a checkpoint parameter' do
      hostname = subject.checkpoint_parameter_from_file('phase-0', 'hostname')
      expect(hostname).to eq(subject.hostname)
    end
  end

  context 'self methods' do
    it 'obtains the nodes in a given environment and phase' do
      expected_nodes = [subject.hostname]
      object_nodes = Bebox::Node.nodes_in_environment(subject.project_root, subject.environment, 'phase-0')
      expect(object_nodes.map{|node| node.hostname}).to include(*expected_nodes)
    end

    it 'obtains a node provision description state' do
      message = "Allocated at #{subject.checkpoint_parameter_from_file('phase-0', 'created_at')}"
      description_state = Bebox::Node.node_provision_state(subject.project_root, subject.environment, subject.hostname)
      expect(description_state).to eq(message)
    end

    it 'obtains a state description for a checkpoint' do
      checkpoints = %w{phase-0 phase-1 phase-2/steps/step-0 phase-2/steps/step-1 phase-2/steps/step-2 phase-2/steps/step-3}
      expected_descriptions = ['Allocated',  'Prepared', 'Provisioned step-0',
        'Provisioned step-1', 'Provisioned step-2', 'Provisioned step-3']
      descriptions = []
      checkpoints.each do |checkpoint|
        descriptions << Bebox::Node.state_from_checkpoint(checkpoint)
      end
      expect(descriptions).to include(*expected_descriptions)
    end

    it 'counts the nodes for types' do
      nodes_count = Bebox::Node.count_all_nodes_by_type(subject.project_root, 'phase-0')
      expect(nodes_count).to eq(1)
    end
  end

  context 'node deletion' do
    before :all do
      subject.remove
    end

    it 'removes serverspec node directory' do
      expect(Dir.exist?("#{subject.project_root}/spec/#{subject.hostname}")).to be (false)
    end

    it 'removes the checkpoints' do
      checkpoint_phases = %w{phase-0 phase-1 phase-2/steps/step-0 phase-2/steps/step-1 phase-2/steps/step-2 phase-2/steps/step-3}
      checkpoint_phases.each do |checkpoint_phase|
        expect(File.exist?("#{subject.project_root}/.checkpoints/environments/#{subject.environment}/phases/#{checkpoint_phase}/#{subject.hostname}.yml")).to be (false)
      end
    end

    it 'not list any nodes' do
      nodes = Bebox::Node.list(subject.project_root, subject.environment, 'phase-0')
      expect(nodes.count).to eq(0)
    end

    it 'removes hiera data' do
      Bebox::PROVISION_STEPS.each do |step|
        expect(File.exist?("#{subject.project_root}/puppet/steps/#{step}/hiera/data/#{subject.hostname}.yaml")).to be (false)
      end
    end

    it 'removes node from manifests' do
      Bebox::PROVISION_STEPS.each do |step|
        content = File.read("#{fixtures_path}/puppet/steps/#{step}/manifests/site.pp.test").gsub(/\s+/, ' ').strip
        output = File.read("#{subject.project_root}/puppet/steps/#{step}/manifests/site.pp").gsub(/\s+/, ' ').strip
        expect(output).to eq(content)
      end
    end
  end
end