require 'spec_helper'
require_relative 'puppet_spec_helper.rb'
require_relative '../factories/puppet.rb'

describe 'Phase 07: Puppet bundle modules' do

  let(:puppet) { build(:puppet) }

  before(:all) do
    puppet.setup_modules
  end

  describe file('/home/puppet/puppet/current/Puppetfile') do
    it { should be_file }
    its(:content) {
      puppetfile_content = File.read("spec/fixtures/Puppetfile.test")
      should == puppetfile_content
    }
  end

  context 'should download the configured modules' do

    module_dir = '/home/puppet/puppet/current/modules'

    describe file("#{module_dir}/rbenv") do
      it { should be_directory }
    end

    describe file("#{module_dir}/nginx") do
      it { should be_directory }
    end

    describe file("#{module_dir}/nodejs") do
      it { should be_directory }
    end

    describe file("#{module_dir}/redis") do
      it { should be_directory }
    end

    describe file("#{module_dir}/mysql") do
      it { should be_directory }
    end

    describe file("#{module_dir}/postgresql") do
      it { should be_directory }
    end

    describe file("#{module_dir}/mongodb") do
      it { should be_directory }
    end

    describe file("#{module_dir}/newrelic") do
      it { should be_directory }
    end

    describe file("#{module_dir}/postfix") do
      it { should be_directory }
    end
  end

end