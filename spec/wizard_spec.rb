require 'spec_helper'

describe 'Wizard' do
  describe '#process' do
    it 'should create 3 machines with their ips and hostnames' do
      expect().to eq(3)
    end
  end
end