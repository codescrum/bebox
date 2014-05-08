FactoryGirl.define do
  factory :builder, :class => Bebox::Builder do
    project_name "pname"
    servers [FactoryGirl.build(:server)]
    vbox_uri "http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box"
    vagrant_box_base_name "test"
    current_pwd "#{Dir.pwd}/tmp"

    initialize_with { new(project_name, servers, vbox_uri, vagrant_box_base_name, current_pwd) }
  end
end