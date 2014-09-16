require 'spec_helper'
require 'progressbar'

describe 'Bebox::ProjectWizard' do

  describe 'Project data provision' do

    subject { Bebox::ProjectWizard.new }

    let(:project_name) { 'bebox-pname' }
    let(:parent_path) { "#{Dir.pwd}/tmp" }
    let(:http_box_uri) {'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box'}
    let(:local_box_uri) {"#{Dir.pwd}/spec/fixtures/test_box.box"}
    let(:bebox_boxes_path) { Bebox::ProjectWizard::BEBOX_BOXES_PATH }

    before :each do
      $stdout.stub(:write)
    end

    after :all do
      FakeFS::FileSystem.clear
    end

    it 'not create a project that already exist' do
      subject.stub(:project_exists?) { true }
      output = subject.create_new_project(project_name)
      expect(output).to eq(false)
    end

    it 'creates a project with wizard' do
      Bebox::Project.any_instance.stub(:create) { true }
      subject.stub(:bebox_boxes_setup)
      subject.stub(:choose_box) { 'test_box.box' }
      subject.stub(:get_valid_box_uri) { 'test_box.box' }
      subject.stub(:choose_option) { 'virtualbox' }
      output = subject.create_new_project(project_name)
      expect(output).to eq(true)
    end

    it 'checks for project existence' do
      FakeFS do
        output = subject.project_exists?(parent_path, project_name)
        expect(output).to eq(Dir.exists?("#{Dir.pwd}/tmp/#{project_name}"))
      end
    end

    it 'setup the bebox boxes directory' do
      FakeFS do
        subject.bebox_boxes_setup
        expect(Dir.exist?("#{bebox_boxes_path}/tmp")).to eq(true)
        expect(Dir["#{bebox_boxes_path}/tmp/*"].count).to eq(0)
      end
    end

    it 'chooses a box from a menu' do
      $stdin.stub(:gets).and_return('1')
      output = subject.choose_box(['test_box.box'])
      expect(output).to eq('test_box.box')
    end

    it 'not chooses a box from a menu' do
      $stdin.stub(:gets).and_return('2')
      output = subject.choose_box(['test_box.box'])
      expect(output).to eq(nil)
    end

    it 'gets a valid box uri from user when box not exist' do
      subject.stub(:set_box) { true }
      subject.stub(:ask_uri) { local_box_uri }
      subject.stub(:box_exists?) { false }
      output = subject.get_valid_box_uri(nil)
      expect(output).to eq(true)
    end

    it 'gets a valid box uri from user when box already exist' do
      subject.stub(:set_box) { true }
      subject.stub(:ask_uri) { local_box_uri }
      subject.stub(:box_exists?) { true }
      $stdin.stub(:gets).and_return('y')
      output = subject.get_valid_box_uri(nil)
      expect(output).to eq(true)
    end

    it 'asks for a uri that is valid' do
      subject.stub(:uri_valid?) { true }
      $stdin.stub(:gets).and_return(local_box_uri)
      output = subject.ask_uri
      expect(output).to eq(local_box_uri)
    end

    it 'validates a local uri' do
      output = subject.uri_valid?(local_box_uri)
      expect(output).to eq(true)
    end

    it 'validates a remote uri' do
      output = subject.uri_valid?(http_box_uri)
      expect(output).to eq(true)
    end

    it 'links to a local file box' do
      FakeFS do
        subject.set_box(local_box_uri)
        expect(File.symlink?("#{bebox_boxes_path}/test_box.box")).to eq(true)
      end
    end

    it 'checks for a local file box existence' do
      FakeFS do
        expect(subject.box_exists?(local_box_uri)).to eq(true)
      end
    end

    it 'links to a remote file box' do
      FakeFS do
        remote_box_uri = 'https://github.com/codescrum/bebox/blob/master/LICENSE'
        subject.set_box(remote_box_uri)
        expect(File.exists?("#{bebox_boxes_path}/LICENSE")).to eq(true)
      end
    end
  end
end