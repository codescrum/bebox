require 'spec_helper'
require_relative '../puppet_spec_helper.rb'
require_relative '../factories/puppet.rb'

describe 'test_15: Puppet apply Service layer step-2' do

  let(:puppet) { build(:puppet, step: 'step-2') }

  before(:all) do
    `cp spec/fixtures/puppet/profiles/profile_0/manifests/init.pp.test #{puppet.project_root}/puppet/profiles/profile_0/manifests/init.pp`
    `cp spec/fixtures/puppet/hiera/data/#{puppet.node.hostname}.yaml.test #{puppet.project_root}/puppet/steps/#{Bebox::Puppet.step_name(puppet.step)}/hiera/data/#{puppet.node.hostname}.yaml`
    Bebox::Puppet.generate_puppetfile(puppet.project_root, puppet.step, ['profile_0'])
    Bebox::Puppet.generate_roles_and_profiles(puppet.project_root, puppet.step, 'role_0', ['profile_0'])
    puppet.apply
  end

  context 'should download the configured modules' do

    module_dir = '/home/puppet/code/shared/librarian-puppet/2-services/modules'

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
end