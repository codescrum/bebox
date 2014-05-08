module Bebox
  class PrepuppetBuilder

    attr_accessor :stages, :builder, :new_project_root

    def initialize(builder, stages)
      self.stages = stages
      self.builder = builder
      @new_project_root = "#{builder.current_pwd}/#{builder.project_name}"
    end

    # Install capistrano for the project
    def setup_capistrano

    end

    # Create Gemfile for the project and run bundle_install
    def setup_bundle
      create_deploy_file
      Bundler.with_clean_env { system "cd #{@new_project_root} && bundle install" }
    end

    # Create Gemfile for the project
    def create_deploy_file
      gemfile_content = File.read('templates/Gemfile')
      File::open("#{@new_project_root}/Gemfile", "w")do |f|
        f.write(gemfile_content)
      end
    end
  end
end