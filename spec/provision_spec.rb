require 'spec_helper'

describe 'Bebox::Provision', :fakefs do

  let(:project) { build(:project) }
  let(:provision) { build(:provision, step: 'step-2') }
  let(:role) { build(:role) }
  let(:profile) { build(:profile) }
  let(:profiles) { Bebox::Provision.profiles_from_role(provision.project_root, role.name) }
  let(:fixtures_path) { Pathname(__FILE__).dirname.parent + 'spec/fixtures' }

  before :all do
    FakeCmd.on!
    FakeCmd.add 'bundle', 0, true
    FakeCmd do
      project.create
      role.create
      profile.create
      Bebox::Role.add_profile(role.project_root, role.name, profile.relative_path)
      FileUtils.cp "#{fixtures_path}/puppet/profiles/#{profile.relative_path}/manifests/init_with_content.pp.test", "#{profile.absolute_path}/manifests/init.pp"
      FileUtils.cp "#{fixtures_path}/puppet/profiles/#{profile.relative_path}/Puppetfile_with_modules.test", "#{profile.absolute_path}/Puppetfile"
      FileUtils.cp "#{fixtures_path}/puppet/hiera/data/#{provision.node.hostname}.yaml.test", "#{provision.project_root}/puppet/steps/#{provision.step_name}/hiera/data/#{provision.node.hostname}.yaml"
    end
    FakeCmd.off!
  end

  context 'pre provision' do
    it 'should generate a Puppetfile' do
      Bebox::Provision.generate_puppetfile(provision.project_root, provision.step, profiles)
      output_file = File.read("#{provision.project_root}/puppet/steps/#{Bebox::Provision.step_name(provision.step)}/Puppetfile").gsub(/\s+/, ' ').strip
      expected_content = File.read("#{fixtures_path}/puppet/steps/#{provision.step}/Puppetfile.test").gsub(/\s+/, ' ').strip
      expect(output_file).to eq(expected_content)
    end

    it 'should generate the roles and profiles modules' do
      Bebox::Provision.generate_roles_and_profiles(provision.project_root, provision.step, role.name, [profile.relative_path])
      # Expect the role is created
      output_file = File.read("#{provision.project_root}/puppet/steps/#{Bebox::Provision.step_name(provision.step)}/modules/roles/manifests/#{role.name}.pp").gsub(/\s+/, ' ').strip
      expected_content = File.read("#{fixtures_path}/puppet/steps/#{provision.step}/modules/roles/manifests/#{role.name}.pp.test").gsub(/\s+/, ' ').strip
      expect(output_file).to eq(expected_content)
      # Expect the profiles are created
      [profile.relative_path].each do |profile_name|
        output_file = File.read("#{provision.project_root}/puppet/steps/#{Bebox::Provision.step_name(provision.step)}/modules/profiles/manifests/#{profile_name}.pp").gsub(/\s+/, ' ').strip
        expected_content = File.read("#{fixtures_path}/puppet/profiles/#{profile.relative_path}/manifests/init_with_content.pp.test").gsub(/\s+/, ' ').strip
        expect(output_file).to eq(expected_content)
      end
    end
  end

  context 'provision' do

    before :all do
      FakeCmd.on!
      FakeCmd do
        provision.apply
      end
    end

    it 'should create checkpoint' do
      checkpoint_file_path = "#{provision.project_root}/.checkpoints/environments/#{provision.environment}/phases/phase-2/steps/#{provision.step}/#{provision.node.hostname}.yml"
      expect(File.exist?(checkpoint_file_path)).to eq(true)
      prepared_node_content = File.read(checkpoint_file_path).gsub(/\s+/, ' ').strip
      ouput_template = Tilt::ERBTemplate.new("#{fixtures_path}/node/provisioned_node_0.test.erb")
      prepared_node_expected_content = ouput_template.render(nil, node: provision.node).gsub(/\s+/, ' ').strip
      expect(prepared_node_content).to eq(prepared_node_expected_content)
    end
  end
end