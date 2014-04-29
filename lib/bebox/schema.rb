class Schema
  class << self
    def create_folders
      `mkdir config && mkdir config/deploy && mkdir config/templates`
    end

    def create_files

    end
  end
end