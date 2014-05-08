FactoryGirl.define do
  factory :server, :class => Bebox::Server do
    ip {'192.168.0.70'}
    hostname {'server1.projectname.test'}
  end
end