FactoryGirl.define do
  factory :profile, :class => Bebox::Profile do
    project_root  "#{Dir.pwd}/tmp/pname"
    name          'profile_0'

    initialize_with { new(name, project_root) }

  end
end