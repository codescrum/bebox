require 'spec_helper'
require_relative 'puppet_connector.rb'

describe 'Test 05: Apply provision for service layer step-2', :vagrant do

  let(:node) { build(:node, ip: YAML.load_file("#{Dir.pwd}/spec/vagrant/support/config_specs.yaml")['test_ip']) }
  let(:provision) { build(:provision, step: 'step-2') }
  let(:role) { build(:role) }
  let(:profile) { build(:profile) }

  before :all do
    role.create
    profile.create
    Bebox::Provision.associate_node_role(node.project_root, node.environment, node.hostname, role.name)
    Bebox::Role.add_profile(role.project_root, role.name, profile.relative_path)
    `cp #{Dir.pwd}/spec/fixtures/puppet/profiles/#{profile.relative_path}/manifests/init_with_content.pp.test #{profile.absolute_path}/manifests/init.pp`
    `cp #{Dir.pwd}/spec/fixtures/puppet/hiera/data/#{provision.node.hostname}.yaml.test #{provision.project_root}/puppet/steps/step-2/hiera/data/#{provision.node.hostname}.yaml`
    `cp #{Dir.pwd}/spec/fixtures/puppet/profiles/#{profile.relative_path}/Puppetfile_with_modules.test #{profile.absolute_path}/Puppetfile`
    profiles = Bebox::Provision.profiles_from_role(provision.project_root, role.name)
    Bebox::Provision.generate_puppetfile(provision.project_root, provision.step, profiles)
    Bebox::Provision.generate_roles_and_profiles(provision.project_root, provision.step, 'role_0', [profile.relative_path])
    provision.apply
  end

  context 'should download the configured modules' do

    module_dir = '/home/puppet/code/shared/librarian-puppet/step-2/modules'

    describe file("#{module_dir}/rbenv") do
      it { should be_directory }
    end

    describe file("#{module_dir}/nginx") do
      it { should be_directory }
    end

    describe file("#{module_dir}/redis") do
      it { should be_directory }
    end

    describe file("#{module_dir}/roles") do
      it { should be_directory }
    end

    describe file("#{module_dir}/profiles") do
      it { should be_directory }
    end
  end

  context 'should install some packages' do
    context 'wkhtmltopdf' do
      describe package('wkhtmltopdf') do
        it { should be_installed }
      end
    end

    context 'imagemagick' do
      describe package('imagemagick') do
        it { should be_installed }
      end
    end

    context 'htop' do
      describe package('htop') do
        it { should be_installed }
      end
    end
  end

  it 'should create checkpoint' do
    checkpoint_file_path = "#{provision.project_root}/.checkpoints/environments/#{provision.environment}/phases/phase-2/steps/#{provision.step}/#{provision.node.hostname}.yml"
    expect(File.exist?(checkpoint_file_path)).to eq(true)
    prepared_node_content = File.read(checkpoint_file_path).gsub(/\s+/, ' ').strip
    ouput_template = Tilt::ERBTemplate.new("#{Dir.pwd}/spec/fixtures/node/provisioned_node_0.test.erb")
    prepared_node_expected_content = ouput_template.render(nil, node: provision.node).gsub(/\s+/, ' ').strip
    expect(prepared_node_content).to eq(prepared_node_expected_content)
  end
end