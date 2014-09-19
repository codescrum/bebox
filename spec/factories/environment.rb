FactoryGirl.define do
  factory :environment, :class => Bebox::Environment do
    name "vagrant_box_test_env"
    project_root "#{Dir.pwd}/tmp/bebox-vagrant_box_test"

    initialize_with { new(name, project_root) }
  end
end