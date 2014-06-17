require 'spec_helper'
require_relative '../spec/factories/server.rb'

describe 'Phase 00: Bebox::Server' do

  subject { build(:server) }

  describe '#ip' do
    it 'returns the ip' do
      expect(subject.ip).to eq('192.168.0.70')
    end
  end

  describe '#hostname' do
    its 'returns the hostname' do
      expect(subject.hostname).to eq('server1.pname.test')
    end
  end

  context 'check it out if the input is valid' do
    it 'returns true because the ip is free' do
      expect(subject.ip_free?).to eq(true)
    end

    it 'returns false because the ip is not free' do
      subject.ip = '127.0.0.1'
      expect(subject.ip_free?).to eq(false)
    end

    it 'should raise ip is already taken error' do
      subject.ip = '127.0.0.1'
      subject.ip_free?
      expect(subject.errors.full_messages.first).to eq("Ip is already taken!")
    end

  end
end