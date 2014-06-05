require_relative '../factories/environment.rb'

FactoryGirl.define do
  factory :puppet, :class => Bebox::Puppet do
    yaml_modules = YAML.load(File.read('config/modules.yaml'))
    available_modules = yaml_modules['common_modules'].keys
  	environment FactoryGirl.build(:environment)
    initialize_with { new(environment, available_modules) }

    trait :installed do
      after(:build) { |puppet| puppet.install }
    end

    trait :apply_users do
      after(:build) do |puppet|
      	puppet.install
      	puppet.apply_users
      end
    end

    trait :deploy_puppet_user do
      after(:build) do |puppet|
        puppet.install
        puppet.apply_users
        puppet.deploy
      end
    end

  end
end