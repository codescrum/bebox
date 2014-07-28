require 'spec_helper'
require_relative '../spec/factories/environment.rb'

describe 'Test 02: Bebox::Environment' do

  describe 'Environment management' do

    subject { build(:environment) }

    it 'should list the current environments' do
      current_environments = %w{vagrant staging production}
      environments = Bebox::Environment.list(subject.project_root)
      expect(environments).to include(*current_environments)
    end

    context 'environment creation' do

      it 'should create checkpoints' do
        expected_directories = [subject.name, 'nodes', 'prepared_nodes',
          'steps', 'step-0', 'step-1', 'step-2', 'step-3']
        subject.create_checkpoints
        directories = []
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
      end

      it 'should generate capistrano base' do
        subject.create_capistrano_base
        expect(Dir.exist?("#{subject.project_root}/config/keys/environments/#{subject.name}")).to be (true)
      end

      it 'should generate deploy file' do
        subject.generate_deploy_file
        deploy_content = File.read("#{subject.project_root}/config/deploy/#{subject.name}.rb").gsub(/\s+/, ' ').strip
        deploy_output_content = File.read("spec/fixtures/config/deploy/environment.test").gsub(/\s+/, ' ').strip
        expect(deploy_content).to eq(deploy_output_content)
      end

      it 'should generate hiera data file' do
        subject.generate_hiera_template
        Bebox::PROVISION_STEPS.each do |step|
          content = File.read("spec/fixtures/puppet/steps/#{step}/hiera/data/#{subject.name}.yaml.test")
          output = File.read("#{subject.project_root}/puppet/steps/#{Bebox::Provision.step_name(step)}/hiera/data/#{subject.name}.yaml")
          expect(output).to eq(content)
        end
      end
    end

    context 'environment deletion' do

      it 'should remove checkpoints' do
        environment_directories = [subject.name, 'nodes', 'prepared_nodes',
          'steps', 'step-0', 'step-1', 'step-2', 'step-3']
        subject.remove_checkpoints
        directories = []
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.project_root}/.checkpoints/environments/#{subject.name}/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to_not include(*environment_directories)
      end

      it 'should remove capistrano base' do
        subject.remove_capistrano_base
        expect(Dir.exist?("#{subject.project_root}/config/keys/environments/#{subject.name}")).to be (false)
      end

      it 'should remove deploy file' do
        subject.remove_deploy_file
        expect(File.exist?("#{subject.project_root}/config/deploy/#{subject.name}.rb")).to be (false)
      end

      it 'should remove deploy file' do
        subject.remove_hiera_template
        Bebox::PROVISION_STEPS.each do |step|
          expect(File.exist?("#{subject.project_root}/puppet/steps/#{Bebox::Provision.step_name(step)}/hiera/data/#{subject.name}.yaml")).to be (false)
        end
      end
    end
  end
end