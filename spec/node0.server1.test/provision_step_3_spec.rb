require 'spec_helper'
require_relative '../factories/provision.rb'
require_relative '../puppet_spec_helper.rb'

describe 'Test 20: Apply provision for security layer step-3' do

  let(:provision) { build(:provision, step: 'step-3') }
  let(:security_profiles) {['base/security/fail2ban', 'base/security/iptables', 'base/security/ssh', 'base/security/sysctl']}

  before(:all) do
    Bebox::Provision.generate_puppetfile(provision.project_root, provision.step, security_profiles)
    Bebox::Provision.generate_roles_and_profiles(provision.project_root, provision.step, 'security', security_profiles)
    provision.apply
  end

  context 'fail2ban module' do
    describe service('fail2ban') do
      it { should be_enabled }
    end
  end

  context 'ssh' do
    describe file('/etc/ssh/sshd_config') do
      its(:content) { should match /PermitRootLogin no/ }
      its(:content) { should match /PubkeyAuthentication yes/ }
      its(:content) { should match /PasswordAuthentication no/ }
    end

  end

  context 'iptables' do
    describe iptables do
      let(:disable_sudo) { false }
      it { should have_rule('-A INPUT -m comment --comment "000 INPUT allow related and established" -m state --state RELATED,ESTABLISHED -j ACCEPT') }
      it { should have_rule('-A INPUT -p icmp -m comment --comment "001 accept all icmp requests" -j ACCEPT') }
      it { should have_rule('-A INPUT -i lo -p tcp -m comment --comment "002 allow loopback" -j ACCEPT') }
      it { should have_rule('-A INPUT -p tcp -m multiport --dports 80 -m comment --comment "100 allow httpd:80" -m state --state NEW -j ACCEPT') }
      it { should have_rule('-A INPUT -p tcp -m multiport --dports 22 -m comment --comment "100 allow ssh" -m state --state NEW -j ACCEPT') }
      it { should have_rule('-A INPUT -m comment --comment "998 deny all other requests" -j REJECT --reject-with icmp-host-prohibited') }
      it { should have_rule('-A FORWARD -m comment --comment "999 deny all other requests" -j REJECT --reject-with icmp-host-prohibited') }
    end
  end

  context 'sysctl' do
    describe command('sysctl -a') do
      its(:stdout) { should match /net.ipv4.conf.default.rp_filter = 1/ }
      its(:stdout) { should match /net.ipv4.icmp_echo_ignore_broadcasts = 1/ }
      its(:stdout) { should match /net.ipv4.conf.all.accept_source_route = 0/ }
      its(:stdout) { should match /net.ipv6.conf.all.accept_source_route = 0/ }
      its(:stdout) { should match /net.ipv4.conf.default.accept_source_route = 0/ }
      its(:stdout) { should match /net.ipv6.conf.default.accept_source_route = 0/ }
      its(:stdout) { should match /net.ipv4.conf.all.send_redirects = 0/ }
      its(:stdout) { should match /net.ipv4.conf.default.send_redirects = 0/ }
      its(:stdout) { should match /net.ipv4.tcp_syncookies = 1/ }
      its(:stdout) { should match /net.ipv4.tcp_max_syn_backlog = 2048/ }
      its(:stdout) { should match /net.ipv4.tcp_synack_retries = 2/ }
      its(:stdout) { should match /net.ipv4.tcp_syn_retries = 5/ }
      its(:stdout) { should match /net.ipv4.conf.all.log_martians = 1/ }
      its(:stdout) { should match /net.ipv4.icmp_ignore_bogus_error_responses = 1/ }
      its(:stdout) { should match /net.ipv4.conf.all.accept_redirects = 0/ }
      its(:stdout) { should match /net.ipv6.conf.all.accept_redirects = 0/ }
      its(:stdout) { should match /net.ipv4.conf.default.accept_redirects = 0/ }
      its(:stdout) { should match /net.ipv6.conf.default.accept_redirects = 0/ }
      its(:stdout) { should match /net.ipv4.icmp_echo_ignore_all = 1/ }
    end
  end

  it 'should create checkpoint' do
    checkpoint_file_path = "#{provision.project_root}/.checkpoints/environments/#{provision.environment}/phases/phase-2/steps/#{provision.step}/#{provision.node.hostname}.yml"
    expect(File.exist?(checkpoint_file_path)).to eq(true)
    prepared_node_content = File.read(checkpoint_file_path).gsub(/\s+/, ' ').strip
    ouput_template = Tilt::ERBTemplate.new('spec/fixtures/node/provisioned_node_0.test.erb')
    prepared_node_expected_content = ouput_template.render(nil, node: provision.node).gsub(/\s+/, ' ').strip
    expect(prepared_node_content).to eq(prepared_node_expected_content)
  end
end