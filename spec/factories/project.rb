require_relative '../factories/server.rb'

FactoryGirl.define do
  factory :project, :class => Bebox::Project do
    name "pname"
    servers [FactoryGirl.build(:server)]
    vbox_uri "#{Dir.pwd}/ubuntu-server-12042-x64-vbox4210-nocm.box"
    vagrant_box_base_name "test"
    parent_path "#{Dir.pwd}/tmp"

    initialize_with { new(name, servers, vbox_uri, vagrant_box_base_name, parent_path, 'virtualbox', ['vagrant', 'production']) }

    trait :created do
      after(:build) { |project| project.create }
    end

    trait :dependency_installed do
      after(:build) do |project|
      	project.create
      	project.install_dependencies
      end
    end
  end
end