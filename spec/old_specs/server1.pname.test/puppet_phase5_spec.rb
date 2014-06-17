require 'spec_helper'
require_relative 'vagrant_spec_helper.rb'
require_relative '../factories/puppet.rb'

describe 'Phase 05: Puppet installed in vagrant machine' do

	# let(:puppet) { build(:puppet, :installed) }
	let(:puppet) { build(:puppet) }

	before(:all) do
		puppet.install
	end

	describe package('puppet') do
		it { should be_installed }
	end

end