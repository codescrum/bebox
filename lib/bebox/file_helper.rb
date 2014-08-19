require 'tilt'

module Bebox
  module FileHelper
    # Generate a file from a template
    def generate_file_from_template(template_path, file_path, options)
      template = Tilt::ERBTemplate.new(template_path)
      File.open(file_path, 'w') do |f|
        f.write template.render(nil, options)
      end
    end
  end
end