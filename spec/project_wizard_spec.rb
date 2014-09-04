require 'spec_helper'
require 'progressbar'

require_relative '../spec/factories/project.rb'

describe 'Test 00: Create a new project with the wizard' do

  describe 'Project data provision' do

    subject { Bebox::ProjectWizard.new }

    let(:project_name) { 'bebox-pname' }
    let(:parent_path) { "#{Dir.pwd}/tmp" }
    let(:http_box_uri) {'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box'}
    let(:local_box_uri) {"#{Dir.pwd}/spec/fixtures/test_box.box"}
    let(:bebox_boxes_path) {File.expand_path(Bebox::ProjectWizard::BEBOX_BOXES_PATH)}

    after :all do
      `rm #{bebox_boxes_path}/test_box.box`
    end

    it 'creates a project from wizard' do
      Bebox::Project.any_instance.stub(:create) { true }
      if File.exist?("#{bebox_boxes_path}/ubuntu-server-12042-x64-vbox4210-nocm.box")
        $stdin.stub(:gets).and_return('ubuntu-server-12042-x64-vbox4210-nocm.box', '1')
      else
        $stdin.stub(:gets).and_return("#{Dir.pwd}/ubuntu-server-12042-x64-vbox4210-nocm.box", '1')
      end
      output = subject.create_new_project(project_name)
      expect(output).to eq(true)
    end

    it 'gest a valid box uri from user' do
      $stdin.stub(:gets).and_return(local_box_uri, 'y')
      subject.get_valid_box_uri(nil)
      expect(File.symlink?("#{bebox_boxes_path}/test_box.box")).to eq(true)
    end

    it 'checks for project existence' do
      output = subject.project_exists?(parent_path, project_name)
      expect(output).to eq(false)
    end

    it 'setup the bebox boxes directory' do
      subject.bebox_boxes_setup
      expect(Dir.exist?("#{bebox_boxes_path}/tmp")).to eq(true)
      expect(Dir["#{bebox_boxes_path}/tmp/*"].count).to eq(0)
    end

    it 'validates an http box uri' do
      output = subject.uri_valid?(http_box_uri)
      expect(output).to eq(true)
    end

    it 'validates a local-file box uri' do
      output = subject.uri_valid?(local_box_uri)
      expect(output).to eq(true)
    end

    it 'links to a local file box' do
      subject.set_box(local_box_uri)
      expect(File.symlink?("#{bebox_boxes_path}/test_box.box")).to eq(true)
    end

    it 'checks for a local file box existence' do
      expect(subject.box_exists?(local_box_uri)).to eq(true)
    end

    it 'links to a remote file box' do
      remote_box_uri = 'https://github.com/codescrum/bebox/blob/master/LICENSE'
      subject.set_box(remote_box_uri)
      expect(File.exists?("#{bebox_boxes_path}/LICENSE")).to eq(true)
      `rm #{bebox_boxes_path}/LICENSE`
    end

  end
end