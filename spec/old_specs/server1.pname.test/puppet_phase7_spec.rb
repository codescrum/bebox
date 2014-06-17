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
    it 'should create Puppetfile in project' do
      expected_content = File.read("#{puppet.environment.project.path}/puppet/Puppetfile").gsub(/\s+/, ' ').strip
      output_file = File.read("spec/fixtures/Puppetfile.test").gsub(/\s+/, ' ').strip
      expect(output_file).to eq(expected_content)
    end
  end

  context 'should download the configured modules' do

    module_dir = '/home/puppet/puppet/current/modules'

    describe file("#{module_dir}/rbenv") do
      it { should be_directory }
    end

    describe file("#{module_dir}/nginx") do
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