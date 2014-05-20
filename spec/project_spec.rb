require 'spec_helper'

describe Bebox::Project do

  describe 'Project creation' do

    subject { build(:project) }

    it 'should create the project directory' do
      subject.create_project_directory
      expect(Dir.exist?(subject.path)).to be true
    end

    it 'should create the project subdirectories' do
      directories_expected = ['config', 'deploy']
      subject.create_subdirectories
      directories = []
      directories << Dir["#{subject.path}/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/*/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/*/*/*/"].map { |f| File.basename(f) }
      expect(directories.flatten).to include(*directories_expected)
    end
  end

  describe 'Project dependency installation' do

    subject { build(:project, :created) }

    it 'should create Gemfile in project' do
      subject.create_gemfile
      expected_content = File.read("templates/Gemfile")
      output_file = File.read("#{subject.path}/Gemfile")
      expect(output_file).to eq(expected_content)
    end
    it 'should install dependencies' do
      subject.create_gemfile
      subject.setup_bundle
      expect(File).to exist("#{subject.path}/Gemfile.lock")
      expect(Dir).to exist("#{subject.path}/.bundle")
    end
  end

  describe 'Run vagrant boxes for project', :slow do

    subject { build(:project, :dependency_installed) }

    # after(:all) do
    #   subject.halt_vagrant_nodes
    #   subject.remove_vagrant_boxes
    # end

    it 'should create Vagrantfile' do
      subject.generate_vagrantfile
      output_file = File.read("#{subject.path}/Vagrantfile").gsub(/\s+/, ' ').strip
      output_file_test = File.read("spec/fixtures/Vagrantfile.test").gsub(/\s+/, ' ').strip
      expect(output_file).to eq(output_file_test)
    end

    it 'should add the boxes to vagrant' do
      vagrant_box_names_expected = ['test_0']
      subject.generate_vagrantfile
      subject.add_vagrant_boxes
      expect(subject.installed_vagrant_box_names).to include(*vagrant_box_names_expected)
    end

    it 'should up the vagrant boxes' do
      subject.run_vagrant_environment
      vagrant_status = subject.vagrant_nodes_status
      nodes_running = true
      subject.servers.size.times{|i| nodes_running &= (vagrant_status =~ /node_#{i}\s+running/)}
      expect(nodes_running).to eq(true)
    end
  end
end