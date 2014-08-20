require 'tilt'

module Bebox
  module FilesHelper

    def self.included(base)
      base.extend(self)
    end

    # Generate a file from a template
    def generate_file_from_template(template_path, file_path, options)
      write_content_to_file(file_path, render_erb_template(template_path, options))
    end

    # Render a template for file content
    def render_erb_template(template_path, options)
      Tilt::ERBTemplate.new(template_path).render(nil, options)
    end

    # Write content to a file
    def write_content_to_file(file_path, content)
      File.open(file_path, 'w') do |f|
        f.write content
      end
    end
  end
end