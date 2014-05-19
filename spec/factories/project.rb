FactoryGirl.define do
  factory :project, :class => Bebox::Project do
    name "pname"
    servers [FactoryGirl.build(:server)]
    vbox_uri "http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box"
    vagrant_box_base_name "test"
    parent_path "#{Dir.pwd}/tmp"

    initialize_with { new(name, servers, vbox_uri, vagrant_box_base_name, parent_path) }
  end
end