require 'spec_helper'
require 'progressbar'

require_relative '../factories/project.rb'

describe 'Test 00: Bebox::ProjectWizard' do

  describe 'Project data provision' do

    subject { Bebox::ProjectWizard.new }

    let(:project_name) { 'bebox-pname' }
    let(:parent_path) { "#{Dir.pwd}/tmp" }
    let(:http_box_uri) {'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box'}
    let(:local_box_uri) {"#{Dir.pwd}/spec/fixtures/test_box.box"}
    let(:bebox_boxes_path) {File.expand_path(Bebox::ProjectWizard::BEBOX_BOXES_PATH)}

    before :all do
      `mkdir -p #{bebox_boxes_path}/tmp`
      `rm -rf #{Dir.pwd}/tmp/bebox-pname`
    end

    before :each do
      $stdout.stub(:write)
    end

    after :all do
      `rm #{bebox_boxes_path}/test_box.box`
    end

    it 'creates a project with wizard' do
      Bebox::Project.any_instance.stub(:create) { true }
      subject.stub(:bebox_boxes_setup)
      subject.stub(:choose_box) { 'test_box.box' }
      $stdin.stub(:gets).and_return('1')
      output = subject.create_new_project(project_name)
      expect(output).to eq(true)
    end

    it 'chooses a box from a menu' do
      $stdin.stub(:gets).and_return('1')
      output = subject.choose_box(['test_box.box'])
      expect(output).to eq('test_box.box')
    end

    it 'gets a valid box uri from user' do
      $stdin.stub(:gets).and_return(local_box_uri, 'y')
      subject.get_valid_box_uri(nil)
      expect(File.symlink?("#{bebox_boxes_path}/test_box.box")).to eq(true)
    end

    it 'checks for project existence' do
      output = subject.project_exists?(parent_path, project_name)
      expect(output).to eq(Dir.exists?("#{Dir.pwd}/tmp/#{project_name}"))
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