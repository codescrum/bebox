require 'spec_helper'

describe Builder do
# TODO  update host file /etc/hosts
# TODO  generate the vagrant files
  it 'should be create a local_host.erb' do
    Builder.create_local_host_template
  end
end