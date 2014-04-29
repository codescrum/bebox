require 'spec_helper'

describe 'Host' do
  describe '#new' do
    it 'should creates a new host' do
      expect(Host.class).to eq(Host.class)
    end
  end
end