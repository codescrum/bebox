FactoryGirl.define do
  factory :environment, :class => Bebox::Environment do
    name "pname_env"
    project_root "#{Dir.pwd}/tmp/bebox_pname"

    initialize_with { new(name, project_root) }

    trait :created do
      after(:build) do |environment|
        environment.create
      end
    end

    trait :removed do
      after(:build) do |environment|
        environment.remove
      end
    end
  end
end