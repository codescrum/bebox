FactoryGirl.define do
  factory :project, :class => Bebox::Project do
    name "pname"
    servers [FactoryGirl.build(:server)]
    vbox_uri "#{Dir.pwd}/ubuntu-server-12042-x64-vbox4210-nocm.box"
    vagrant_box_base_name "test"
    parent_path "#{Dir.pwd}/tmp"

    initialize_with { new(name, servers, vbox_uri, vagrant_box_base_name, parent_path) }

    trait :created do
      after(:build) { |project| project.create }
    end

    trait :dependency_installed do
      after(:build) do |project|
      	project.create
      	project.setup_bundle
      end
    end

    trait :with_vagrant_up do
      after(:build) do |project|
      	project.create
      	project.setup_bundle
      	project.run_vagrant_environment
      end
    end
  end
end