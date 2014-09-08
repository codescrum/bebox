require 'spec_helper'
require 'tilt'
require_relative '../spec/factories/node.rb'

describe 'Test 09: Bebox::Node' do

  include Bebox::VagrantHelper

  describe 'Pre-prepare nodes' do

    let(:nodes) { 1.times.map{|index| build(:node, :created, hostname: "node#{index}.server1.test")} }
    let(:project_root) { "#{Dir.pwd}/tmp/bebox-pname" }
    let(:environment) { 'vagrant' }
    let(:project_name) {'bebox-pname'}

    context 'pre vagrant prepare' do
      it 'should generate the Vagrantfile' do
        Bebox::VagrantHelper.generate_vagrantfile(nodes)
        vagrantfile_content = File.read("#{project_root}/Vagrantfile").gsub(/\s+/, ' ').strip
        ouput_template = Tilt::ERBTemplate.new('spec/fixtures/node/Vagrantfile.test.erb')
        vagrantfile_output_content = ouput_template.render(nil, ip_address: nodes.first.ip).gsub(/\s+/, ' ').strip
        expect(vagrantfile_content).to eq(vagrantfile_output_content)
      end
      it 'should regenerate the vagrant deploy file' do
        Bebox::Node.regenerate_deploy_file(project_root, environment, nodes)
        vagrant_deploy_content = File.read("#{project_root}/config/deploy/vagrant.rb").gsub(/\s+/, ' ').strip
        vagrant_deploy_output_content = File.read("spec/fixtures/node/vagrant_deploy.test").gsub(/\s+/, ' ').strip
        expect(vagrant_deploy_content).to eq(vagrant_deploy_output_content)
      end
    end

    context 'vagrant prepare' do

      let (:original_hosts_content) { File.read("#{nodes.first.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip }

      before :all do
        node = nodes.first
        puts "\nPlease provide your local password, if asked, to configure the local hosts file.".yellow
        original_hosts_content
        `sudo rm -rf #{node.local_hosts_path}/hosts_before_#{project_name}`
        prepare_vagrant(node)
      end

      describe 'Configure the hosts file' do
        it 'should create a hosts backup file' do
          node = nodes.first
          hosts_backup_file = "#{node.local_hosts_path}/hosts_before_#{project_name}"
          expect(File).to exist(hosts_backup_file)
          hosts_backup_content = File.read(hosts_backup_file).gsub(/\s+/, ' ').strip
          expect(original_hosts_content).to eq(hosts_backup_content)
        end

        it 'should add the hosts config to hosts file' do
          node = nodes.first
          hosts_content = File.read("#{node.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
          expect(hosts_content).to include(*nodes.map{|node| "#{node.ip} #{node.hostname}"})
        end
      end

      describe 'vagrant setup' do
        it 'should add the node to vagrant' do
          vagrant_box_names_expected = nodes.map{|node| "#{project_name}-#{node.hostname}"}
          node = nodes.first
          expect(installed_vagrant_box_names(node)).to include(*vagrant_box_names_expected)
        end

        it 'should up the vagrant boxes' do
          Bebox::VagrantHelper.up_vagrant_nodes(project_root)
          nodes.each{|node| expect(vagrant_box_running?(node)).to eq(true)}
        end

        it 'should connect to vagrant box through ssh' do
          connection_successful = true
          nodes.each do |node|
            `ssh -q -oStrictHostKeyChecking=no -i ~/.vagrant.d/insecure_private_key -l vagrant #{node.ip} exit`
            connection_successful &= ($?.exitstatus == 0)
          end
          expect(connection_successful).to eq(true)
        end
      end
    end
  end
end