module Bebox
  class PrepuppetBuilder

    UBUNTU_DEPENDENCIES = %w(git-core build-essential)
    attr_accessor :stages, :builder, :new_project_root

    def initialize(builder, stages)
      self.stages = stages
      self.builder = builder
      @new_project_root = "#{builder.current_pwd}/#{builder.project_name}"
    end

    def prepare_boxes
      system "cd #{@new_project_root} && BUNDLE_GEMFILE=Gemfile bundle exec cap deploy:prepare"
    end

    # Install capistrano for the project
    def setup_capistrano
      create_capfile
      create_deploy_files
    end

    # Create Gemfile for the project and run bundle_install
    def setup_bundle
      create_gemfile
      system "cd #{@new_project_root} && BUNDLE_GEMFILE=Gemfile bundle install"
    end

    # Create Gemfile for the project
    def create_gemfile
      gemfile_content = File.read('templates/Gemfile')
      File::open("#{@new_project_root}/Gemfile", "w")do |f|
        f.write(gemfile_content)
      end
    end

    def create_deploy_files
      config_deploy_template = Tilt::ERBTemplate.new("templates/config_deploy.erb")
      File.open("#{@new_project_root}/config/deploy.rb", 'w') do |f|
        f.write config_deploy_template.render(nil, :prepuppet => self)
      end
      stages.each do |stage|
        template_name = (stage == 'vagrant') ? "vagrant" : "stage"
        config_deploy_template = Tilt::ERBTemplate.new("templates/config_deploy_#{template_name}.erb")
        File.open("#{@new_project_root}/config/deploy/#{stage}.rb", 'w') do |f|
          f.write config_deploy_template.render(nil, :prepuppet => self)
        end
      end
    end

    # Create Capfile for the project
    def create_capfile
      capfile_content = File.read('templates/Capfile')
      File::open("#{@new_project_root}/Capfile", "w")do |f|
        f.write(capfile_content)
      end
    end
  end
end