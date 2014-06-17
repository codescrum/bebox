FactoryGirl.define do
  factory :project, :class => Bebox::Project do
    name "pname"
    vagrant_box_base "~/.bebox/boxes/ubuntu-server-12042-x64-vbox4210-nocm.box"
    parent_path "#{Dir.pwd}/tmp"
    vagrant_box_provider 'virtualbox'
    environments ['vagrant', 'staging', 'production']

    initialize_with { new(name, vagrant_box_base, parent_path, vagrant_box_provider, environments) }

    trait :created do
      after(:build) do |project|
        project.create
      end
    end
  end
end