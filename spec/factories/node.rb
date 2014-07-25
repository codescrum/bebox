FactoryGirl.define do
  factory :node, :class => Bebox::Node do
    environment   'vagrant'
    project_root  "#{Dir.pwd}/tmp/bebox_pname"
    hostname      'node0.server1.test'
    ip            YAML.load_file('spec/support/config_specs.yaml')['test_ip']

    initialize_with { new(environment, project_root, hostname, ip) }

    trait :created do
      after(:build) do |node|
        node.create
      end
    end

    trait :removed do
      after(:build) do |node|
        node.remove
      end
    end
  end
end