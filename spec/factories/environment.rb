FactoryGirl.define do
  factory :environment, :class => Bebox::Environment do
    name "pname_env"
    project_root "#{Dir.pwd}/tmp/bebox-pname"

    initialize_with { new(name, project_root) }
  end
end