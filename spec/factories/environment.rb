FactoryGirl.define do
  factory :environment, :class => Bebox::Environment do
  	name 'vagrant'
  	project FactoryGirl.build(:project, :dependency_installed)
    initialize_with { new(name, project.path, project.servers, project.vbox_path, project.vagrant_box_base_name, project.vagrant_box_provider) }

    trait :with_vagrant_up do
      after(:build) { |environment| environment.up }
    end

    trait :with_common_dev do
      after(:build) do |environment|
      	environment.up
      	environment.install_common_dev
      end
    end
  end
end