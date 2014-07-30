require 'spec_helper'
# require 'vcr'

require_relative '../spec/factories/project.rb'

describe 'Test 00: Create a new project with the wizard' do

  describe 'Project data provision' do

    subject { Bebox::ProjectWizard.new }

    let(:project_name) { 'bebox-pname' }
    let(:parent_path) { "#{Dir.pwd}/tmp" }
    let(:http_box_uri) {'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box'}
    let(:local_box_uri) {"#{Dir.pwd}/spec/fixtures/test_box.box"}
    let(:bebox_boxes_path) {File.expand_path(Bebox::ProjectWizard::BEBOX_BOXES_PATH)}

    it 'should check project existence' do
      output = subject.project_exists?(parent_path, project_name)
      expect(output).to eq(false)
    end

    it 'should setup the bebox boxes directory' do
      subject.bebox_boxes_setup
      expect(Dir.exist?("#{bebox_boxes_path}/tmp")).to eq(true)
      expect(Dir["#{bebox_boxes_path}/tmp/*"].count).to eq(0)
    end

    it 'should validate an http box uri' do
      output = subject.uri_valid?(http_box_uri)
      expect(output).to eq(true)
    end

    it 'should validate a local-file box uri' do
      output = subject.uri_valid?(local_box_uri)
      expect(output).to eq(true)
    end

    # it 'should download an http box' do
    #   VCR.use_cassette('box_download') do
    #     subject.set_box(http_box_uri)
    #   end
    #   expect(File.exist?("#{bebox_boxes_path}/ubuntu-server-12042-x64-vbox4210-nocm.box")).to eq(true)
    # end

    it 'should link a local file box' do
      subject.set_box(local_box_uri)
      expect(File.symlink?("#{bebox_boxes_path}/test_box.box")).to eq(true)
    end
  end
end