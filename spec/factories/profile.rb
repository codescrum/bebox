FactoryGirl.define do
  factory :profile, :class => Bebox::Profile do
    project_root  "#{Dir.pwd}/tmp/bebox-vagrant_box_test"
    name          'profile_0'
    path          'test'

    initialize_with { new(name, project_root, path) }

  end
end