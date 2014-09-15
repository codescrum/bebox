require 'spec_helper'
require 'fakefs/safe'
require_relative '../spec/factories/project.rb'
require_relative '../spec/factories/environment.rb'

describe 'Test 08: Bebox::Environment' do

  describe 'Environment management' do

    let(:project) { build(:project) }
    subject { build(:environment) }
    let(:lib_path) { Pathname(__FILE__).dirname.parent + 'lib' }
    let(:fixtures_path) { Pathname(__FILE__).dirname.parent + 'spec/fixtures' }

    before :all do
      FakeFS::FileSystem.clone(fixtures_path)
      FakeFS::FileSystem.clone("#{lib_path}/templates")
      FakeFS::FileSystem.clone("#{lib_path}/deb")
      FakeFS.activate!
      project.create
    end

    after :all do
      FakeFS.deactivate!
      FakeFS::FileSystem.clear
    end

    it 'list the current environments' do
      current_environments = %w{vagrant staging production}
      environments = Bebox::Environment.list(subject.project_root)
      expect(environments).to include(*current_environments)
    end

    context 'environment creation' do
      before :all do
        subject.create
      end

      it 'creates checkpoints' do
        expected_directories = [subject.name, 'phases', 'phase-0', 'phase-1', 'phase-2',
          'steps', 'step-0', 'step-1', 'step-2', 'step-3']
        directories = []
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/*/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
      end

      it 'sgenerates a capistrano base' do
        expected_files = %w{steps keys}
        files = Dir["#{subject.project_root}/config/environments/#{subject.name}/*/"].map { |f| File.basename(f) }
        expect(files.flatten).to include(*expected_files)
      end

      it 'generates the deploy files' do
        # Generate capistrano recipe for environment
        deploy_content = File.read("#{subject.project_root}/config/environments/#{subject.name}/deploy.rb").gsub(/\s+/, ' ').strip
        deploy_output_content = File.read("#{fixtures_path}/config/deploy/environment.test").gsub(/\s+/, ' ').strip
        expect(deploy_content).to eq(deploy_output_content)
        # Generate capistrano specific steps recipes
        Bebox::PROVISION_STEPS.each do |step|
          content = File.read("#{fixtures_path}/config/deploy/steps/#{step}.test")
          output = File.read("#{subject.project_root}/config/environments/#{subject.name}/steps/#{step}.rb")
          expect(output).to eq(content)
        end
      end

      it 'generates a hiera data file' do
        Bebox::PROVISION_STEPS.each do |step|
          content = File.read("#{fixtures_path}/puppet/steps/#{step}/hiera/data/#{subject.name}.yaml.test")
          output = File.read("#{subject.project_root}/puppet/steps/#{Bebox::Provision.step_name(step)}/hiera/data/#{subject.name}.yaml")
          expect(output).to eq(content)
        end
      end
    end

    context 'environment deletion' do
      before :all do
        subject.remove
      end

      it 'removes checkpoints' do
        environment_directories = [subject.name, 'phases', 'phase-0', 'phase-1', 'phase-2',
          'steps', 'step-0', 'step-1', 'step-2', 'step-3']
        directories = []
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/*/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to_not include(*environment_directories)
      end

      it 'removes the environment config' do
        expect(Dir.exist?("#{subject.project_root}/config/environments/#{subject.name}")).to be (false)
      end

      it 'removes the hiera node files' do
        Bebox::PROVISION_STEPS.each do |step|
          expect(File.exist?("#{subject.project_root}/puppet/steps/#{Bebox::Provision.step_name(step)}/hiera/data/#{subject.name}.yaml")).to be (false)
        end
      end
    end

    context 'self methods' do
      it 'checks for environment access keys' do
        access = Bebox::Environment.check_environment_access(subject.project_root, 'vagrant')
        expect(access).to eq(true)
      end

      it 'obtains a vagrant box base' do
        environment_existence = Bebox::Environment.environment_exists?(subject.project_root, 'vagrant')
        expect(environment_existence).to eq(true)
      end
    end
  end
end