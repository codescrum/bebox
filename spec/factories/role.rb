FactoryGirl.define do
  factory :role, :class => Bebox::Role do
    project_root  "#{Dir.pwd}/tmp/bebox-vagrant_box_test"
    name          'role_0'

    initialize_with { new(name, project_root) }

  end
end