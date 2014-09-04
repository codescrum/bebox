require 'spec_helper'
require_relative '../spec/factories/environment.rb'

describe 'Test 03: Bebox::Environment' do

  describe 'Environment management' do

    subject { build(:environment) }

    it 'list the current environments' do
      current_environments = %w{vagrant staging production}
      environments = Bebox::Environment.list(subject.project_root)
      expect(environments).to include(*current_environments)
    end

    context 'environment creation' do
      before :all do
        subject.create
      end

      it 'generates SSH keys for a given environment' do
        subject.generate_puppet_user_keys(subject.name)
        %w{id_rsa id_rsa.pub}.each do |key|
          expect(File.exist?("#{subject.project_root}/config/keys/environments/#{subject.name}/#{key}")).to be (true)
        end
      end

      it 'creates checkpoints' do
        expected_directories = [subject.name, 'nodes', 'prepared_nodes',
          'steps', 'step-0', 'step-1', 'step-2', 'step-3']
        directories = []
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
      end

      it 'generates a capistrano base' do
        expect(Dir.exist?("#{subject.project_root}/config/keys/environments/#{subject.name}")).to be (true)
      end

      it 'generates a deploy file' do
        deploy_content = File.read("#{subject.project_root}/config/deploy/#{subject.name}.rb").gsub(/\s+/, ' ').strip
        deploy_output_content = File.read("spec/fixtures/config/deploy/environment.test").gsub(/\s+/, ' ').strip
        expect(deploy_content).to eq(deploy_output_content)
      end

      it 'generates a hiera data file' do
        Bebox::PROVISION_STEPS.each do |step|
          content = File.read("spec/fixtures/puppet/steps/#{step}/hiera/data/#{subject.name}.yaml.test")
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
        environment_directories = [subject.name, 'nodes', 'prepared_nodes',
          'steps', 'step-0', 'step-1', 'step-2', 'step-3']
        directories = []
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to_not include(*environment_directories)
      end

      it 'removes the capistrano base' do
        expect(Dir.exist?("#{subject.project_root}/config/keys/environments/#{subject.name}")).to be (false)
      end

      it 'removes the deploy file' do
        expect(File.exist?("#{subject.project_root}/config/deploy/#{subject.name}.rb")).to be (false)
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