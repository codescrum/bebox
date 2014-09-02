require 'spec_helper'
require_relative '../spec/factories/project.rb'

describe 'Test 07: Bebox::Project' do

  describe 'Project creation' do

    subject { build(:project) }
    let(:temporary_project) { build(:project, name: 'temporary_project') }

    before :all do
      subject.create
      temporary_project.create
    end

    it 'creates the project directory' do
      expect(Dir.exist?(subject.path)).to be true
    end

    it 'destroys a temporary project' do
      temporary_project.destroy
      expect(Dir.exist?(temporary_project.path)).to be false
    end

    context '00: Project config files creation' do
      it 'creates the support directories' do
        expected_directories = ['templates', 'roles', 'profiles']
        directories = []
        directories << Dir["#{subject.path}/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/*/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
      end

      it 'creates the config deploy directories' do
        expect(Dir.exist?("#{subject.path}/config/environments")).to be (true)
      end

      it 'generates a .bebox file' do
        dotbebox_content = File.read("#{subject.path}/.bebox").gsub(/\s+/, ' ').strip
        ouput_template = Tilt::ERBTemplate.new('spec/fixtures/dot_bebox.test.erb')
        dotbebox_expected_content = ouput_template.render(nil, created_at: subject.created_at, bebox_path: Dir.pwd).gsub(/\s+/, ' ').strip
        expect(dotbebox_content).to eq(dotbebox_expected_content)
      end

      it 'generates a .gitignore file' do
        expected_content = File.read("#{subject.path}/.gitignore")
        output_file = File.read('spec/fixtures/dot_gitignore.test')
        expect(output_file).to eq(expected_content)
      end

      it 'generates a .ruby-version file' do
        ruby_version = (RUBY_PATCHLEVEL == 0) ? RUBY_VERSION : "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
        version = File.read("#{subject.path}/.ruby-version").strip
        expect(version).to eq(ruby_version)
      end

      it 'creates a Capfile' do
        expected_content = File.read("#{subject.path}/Capfile")
        output_file = File.read('spec/fixtures/Capfile.test')
        expect(output_file).to eq(expected_content)
      end

      it 'generates the deploy files' do
        # Generate deploy.rb file
        config_deploy_content = File.read("#{subject.path}/config/deploy.rb").gsub(/\s+/, ' ').strip
        config_deploy_output_content = File.read("spec/fixtures/config/deploy.test").gsub(/\s+/, ' ').strip
        expect(config_deploy_content).to eq(config_deploy_output_content)
      end

      it 'creates a Gemfile' do
        content = File.read("#{subject.path}/Gemfile").gsub(/\s+/, ' ').strip
        output = File.read("spec/fixtures/Gemfile.test").gsub(/\s+/, ' ').strip
        expect(output).to eq(content)
      end
    end

    context '01: Create puppet base' do
      it 'generates the SO dependencies files' do
        content = File.read("#{subject.path}/puppet/prepare/dependencies/ubuntu/packages")
        output = File.read("spec/fixtures/puppet/ubuntu_dependencies.test")
        expect(output).to eq(content)
      end

      it 'copy the puppet installation files' do
        expect(Dir.exist?("#{subject.path}/puppet/lib/deb/puppet_3.6.0")).to be (true)
        expect(Dir["#{subject.path}/puppet/lib/deb/puppet_3.6.0/*"].count).to eq(18)
      end

      it 'generates the step directories' do
        expected_directories = ['prepare', 'profiles', 'roles', 'steps',
          '0-fundamental', '1-users', '2-services', '3-security',
          'hiera', 'manifests', 'modules', 'data']
        directories = []
        directories << Dir["#{subject.path}/puppet/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/puppet/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/puppet/*/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/puppet/*/*/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
      end

      it 'copy the default roles and profiles' do
        expected_roles_directories = ['fundamental', 'security', 'users']
        expected_profiles_directories = ['profiles', 'base', 'fundamental', 'ruby', 'manifests', 'sudo', 'users', 'security', 'fail2ban', 'iptables', 'ssh', 'sysctl']
        directories = Dir["#{subject.path}/puppet/roles/*/"].map { |f| File.basename(f) }.uniq
        expect(directories).to include(*expected_roles_directories)
        directories = Dir["#{subject.path}/puppet/profiles/**/"].map { |f| File.basename(f) }.uniq
        expect(directories).to include(*expected_profiles_directories)
      end

      context '02: generate steps templates' do
        it 'generates the manifests templates' do
          Bebox::PROVISION_STEPS.each do |step|
            content = File.read("spec/fixtures/puppet/steps/#{step}/manifests/site.pp.test")
            output = File.read("#{subject.path}/puppet/steps/#{Bebox::Provision.step_name(step)}/manifests/site.pp")
            expect(output).to eq(content)
          end
        end
        it 'generates the hiera config template' do
          Bebox::PROVISION_STEPS.each do |step|
            content = File.read("spec/fixtures/puppet/steps/#{step}/hiera/hiera.yaml.test")
            output = File.read("#{subject.path}/puppet/steps/#{Bebox::Provision.step_name(step)}/hiera/hiera.yaml")
            expect(output).to eq(content)
          end
        end
        it 'generates the hiera data common' do
          Bebox::PROVISION_STEPS.each do |step|
            content = File.read("spec/fixtures/puppet/steps/#{step}/hiera/data/common.yaml.test")
            output = File.read("#{subject.path}/puppet/steps/#{Bebox::Provision.step_name(step)}/hiera/data/common.yaml")
            expect(output).to eq(content)
          end
        end
      end
    end

    context '03: checkpoints' do
      it 'creates checkpoints directories' do
        expected_directories = ['.checkpoints', 'environments']
        directories = []
        directories << Dir["#{subject.path}/.checkpoints/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/.checkpoints/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
      end
    end

    context '04: bundle project' do
      it 'install project dependencies' do
        expect(File).to exist("#{subject.path}/Gemfile.lock")
      end
    end

    context '05: create default environments' do
      it 'generates the deploy environment files' do
        subject.environments.each do |environment|
          config_deploy_vagrant_content = File.read("#{subject.path}/config/environments/#{environment.name}/deploy.rb").gsub(/\s+/, ' ').strip
          config_deploy_vagrant_output_content = File.read("spec/fixtures/config/deploy/#{environment.name}.test").gsub(/\s+/, ' ').strip
          expect(config_deploy_vagrant_content).to eq(config_deploy_vagrant_output_content)
        end
      end

      it 'creates environments checkpoints' do
        expected_directories = ['vagrant', 'staging', 'production', 'phases', 'phase-0', 'phase-1', 'phase-2',
          'steps', 'step-0', 'step-1', 'step-2', 'step-3']
        directories = []
        directories << Dir["#{subject.path}/.checkpoints/environments/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/.checkpoints/environments/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/.checkpoints/environments/*/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/.checkpoints/environments/*/*/*/*/"].map { |f| File.basename(f) }
        directories << Dir["#{subject.path}/.checkpoints/environments/*/*/*/*/*/"].map { |f| File.basename(f) }
        expect(directories.flatten).to include(*expected_directories)
      end

      it 'creates environments capistrano base' do
        subject.environments.each do |environment|
          expect(Dir.exist?("#{subject.path}/config/environments/#{environment.name}")).to be (true)
        end
        expect(File.exist?("#{subject.path}/config/environments/vagrant/keys/id_rsa")).to be (true)
        expect(File.exist?("#{subject.path}/config/environments/vagrant/keys/id_rsa.pub")).to be (true)
      end
    end

    context '06: self methods' do
      it 'obtains a vagrant box provider' do
        vagrant_box_provider = Bebox::Project.vagrant_box_provider_from_file(subject.path)
        expect(vagrant_box_provider).to eq(subject.vagrant_box_provider)
      end

      it 'obtains a vagrant box base' do
        vagrant_box_base = Bebox::Project.vagrant_box_base_from_file(subject.path)
        expect(vagrant_box_base).to eq(subject.vagrant_box_base)
      end

      it 'obtains the SO dependencies' do
        expected_dependencies = "git-core build-essential curl whois openssl libxslt1-dev autoconf bison libreadline5 libsqlite3-dev"
        dependencies = Bebox::Project.so_dependencies
        expect(dependencies).to eq(expected_dependencies)
      end
    end
  end
end