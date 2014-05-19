require 'spec_helper'

describe Bebox::Project do

  subject { build(:project) }

  describe 'Directory' do
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
end