FactoryGirl.define do
  factory :node, :class => Bebox::Node do
    environment   'vagrant'
    project_root  "#{Dir.pwd}/tmp/bebox-pname"
    hostname      'node0.server1.test'
    ip            '192.168.0.81'

    initialize_with { new(environment, project_root, hostname, ip) }

    trait :created do
      after(:build) do |node|
        node.create
      end
    end
  end
end