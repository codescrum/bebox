require 'spec_helper'

describe Bebox::Server do
  subject{Bebox::Server.new(ip: @ip, hostname: @hostname)}
  #let(:ip){'192.168.0.10'}
  #let(:hostname){'server1.projectname.test'}

  describe '#ip' do
    it 'returns the ip' do
      @ip = '192.168.0.10'
      expect(subject.ip).to eq('192.168.0.10')
    end
  end

  describe '#hostname' do
    its 'returns the hostname' do
      @hostname = 'server1.projectname.test'
      expect(subject.hostname).to eq('server1.projectname.test')
    end
  end

  context 'check it out if the input are valid' do
    it 'returns true because the ip is free' do
      @ip = '192.168.0.54'
      expect(subject.ip_free?).to eq(true)
    end

    it 'returns false because the ip is free' do
      @ip = '127.0.0.1'
      expect(subject.ip_free?).to eq(false)
    end

    it 'returns true if the hostname' do
     #
    end

    it 'should raise ip is already taken error' do
      @ip = '127.0.0.1'
      subject.ip_free?
      expect(subject.errors.full_messages.first).to eq("Ip is already taken!")
    end

  end
end