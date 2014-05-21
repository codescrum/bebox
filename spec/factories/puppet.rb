FactoryGirl.define do
  factory :puppet, :class => Bebox::Puppet do
  	environment FactoryGirl.build(:environment, :with_common_dev)
    initialize_with { new(environment) }

    trait :installed do
      after(:build) { |puppet| puppet.install }
    end

  end
end