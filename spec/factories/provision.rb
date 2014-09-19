
FactoryGirl.define do
  factory :provision, :class => Bebox::Provision do
    project_root  "#{Dir.pwd}/tmp/bebox-vagrant_box_test"
    environment   'vagrant'
    node          FactoryGirl.build(:node)
    step          'step-0'

    initialize_with { new(project_root, environment, node, step) }

  end
end