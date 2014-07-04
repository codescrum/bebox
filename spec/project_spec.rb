require 'spec_helper'
require_relative '../spec/factories/project.rb'

describe 'Test 01: Bebox::Project' do

  describe 'Project creation' do

    subject { build(:project) }

    it 'should create the project directory' do
      subject.create_project_directory
      expect(Dir.exist?(subject.path)).to be true
    end

    context '00: Project config files creation' do
      it 'should create the templates directories' do
        directories_expected = ['templates', 'roles', 'profiles']
        subject.create_templates_directories
        directories = []
        directories << Dir["#{subject.path}/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/*/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*directories_expected)
      end

      it 'should create config deploy directories' do
        directories_expected = ['config', 'deploy', 'keys', 'environments']
        subject.create_config_deploy_directories
        directories = []
        directories << Dir["#{subject.path}/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/*/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*directories_expected)
      end

      it 'should generate a .bebox file' do
        subject.generate_dot_bebox_file
        expected_content = File.read("#{subject.path}/.bebox")
        output_file = File.read('spec/fixtures/dot_bebox.test')
        expect(output_file).to eq(expected_content)
      end

      it 'should generate a .ruby-version file' do
        subject.generate_ruby_version
        version = File.read("#{subject.path}/.ruby-version").strip
        expect(version).to eq '2.1.0'
      end

      it 'should create a Capfile' do
        subject.create_capfile
        expected_content = File.read("#{subject.path}/Capfile")
        output_file = File.read('spec/fixtures/Capfile.test')
        expect(output_file).to eq(expected_content)
      end

      it 'should generate deploy file' do
        subject.generate_deploy_file
        config_deploy_content = File.read("#{subject.path}/config/deploy.rb").gsub(/\s+/, ' ').strip
        config_deploy_output_content = File.read("spec/fixtures/config/deploy.test").gsub(/\s+/, ' ').strip
        expect(config_deploy_content).to eq(config_deploy_output_content)
      end

      it 'should create Gemfile' do
        subject.create_gemfile
        content = File.read("#{subject.path}/Gemfile")
        output = File.read("spec/fixtures/Gemfile.test")
        expect(output).to eq(content)
      end
    end

    context '01: Create puppet base' do
      it 'should generate SO dependencies files' do
        subject.generate_so_dependencies_files
        content = File.read("#{subject.path}/puppet/prepare/dependencies/ubuntu/packages")
        output = File.read("spec/fixtures/puppet/ubuntu_dependencies.test")
        expect(output).to eq(content)
      end

      it 'should copy puppet install files' do
        subject.copy_puppet_install_files
        expect(Dir.exist?("#{subject.path}/puppet/lib/deb/puppet_3.6.0")).to be (true)
        expect(Dir["#{subject.path}/puppet/lib/deb/puppet_3.6.0/*"].count).to eq(18)
      end

      it 'should generate steps directories' do
        expected_directories = ['prepare', 'profiles', 'roles', 'steps',
          '0-fundamental', '1-users', '2-services', '3-security',
          'hiera', 'manifests', 'modules', 'data']
        subject.generate_steps_directories
        directories = []
        directories << Dir["#{subject.path}/puppet/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/puppet/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/puppet/*/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/puppet/*/*/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
      end

      it 'should copy the default roles and profiles' do
        expected_directories = ['fundamental', 'security', 'users']
        subject.copy_default_roles_profiles
        directories = Dir["#{subject.path}/puppet/roles/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
        directories = Dir["#{subject.path}/puppet/profiles/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
      end

      context '02: generate steps templates' do
        before :all do
          subject.generate_steps_templates
        end
        it 'should generate manifests template' do
          puppet_steps = %w{step-0 step-1 step-2 step-3}
          puppet_steps.each do |step|
            content = File.read("spec/fixtures/puppet/steps/#{step}/manifests/site.pp.test")
            output = File.read("#{subject.path}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp")
            expect(output).to eq(content)
          end
        end
        it 'should generate hiera template' do
          puppet_steps = %w{step-0 step-1 step-2 step-3}
          puppet_steps.each do |step|
            content = File.read("spec/fixtures/puppet/steps/#{step}/hiera/hiera.yaml.test")
            output = File.read("#{subject.path}/puppet/steps/#{Bebox::Puppet.step_name(step)}/hiera/hiera.yaml")
            expect(output).to eq(content)
          end
        end
        it 'should generate hiera data common' do
          puppet_steps = %w{step-0 step-1 step-2 step-3}
          puppet_steps.each do |step|
            content = File.read("spec/fixtures/puppet/steps/#{step}/hiera/data/common.yaml.test")
            output = File.read("#{subject.path}/puppet/steps/#{Bebox::Puppet.step_name(step)}/hiera/data/common.yaml")
            expect(output).to eq(content)
          end
        end
      end
    end

    context '03: checkpoints' do
      it 'should create checkpoints directories' do
        expected_directories = ['.checkpoints', 'environments']
        subject.create_checkpoints
        directories = []
        directories << Dir["#{subject.path}/.checkpoints/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/.checkpoints/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
      end
    end

    context '04: bundle project' do
      it 'should install dependencies' do
        subject.bundle_project
        expect(File).to exist("#{subject.path}/Gemfile.lock")
        expect(Dir).to exist("#{subject.path}/.bundle")
      end
    end

    context '05: create default environments' do

      before(:all) do
        subject.create_default_environments
      end

      it 'should generate deploy files' do
        subject.environments.each do |environment|
          config_deploy_vagrant_content = File.read("#{subject.path}/config/deploy/#{environment.name}.rb").gsub(/\s+/, ' ').strip
          config_deploy_vagrant_output_content = File.read("spec/fixtures/config/deploy/#{environment.name}.test").gsub(/\s+/, ' ').strip
          expect(config_deploy_vagrant_content).to eq(config_deploy_vagrant_output_content)
        end
      end

      it 'should create checkpoints' do
        expected_directories = ['vagrant', 'staging', 'production', 'nodes', 'prepared_nodes',
          'steps', 'step-0', 'step-1', 'step-2', 'step-3']
        directories = []
        directories << Dir["#{subject.path}/.checkpoints/environments/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/.checkpoints/environments/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/.checkpoints/environments/*/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
      end

      it 'should create capistrano base' do
        subject.environments.each do |environment|
          expect(Dir.exist?("#{subject.path}/config/keys/environments/#{environment.name}")).to be (true)
        end
        expect(File.exist?("#{subject.path}/config/keys/environments/vagrant/id_rsa")).to be (true)
        expect(File.exist?("#{subject.path}/config/keys/environments/vagrant/id_rsa.pub")).to be (true)
      end
    end
  end
end