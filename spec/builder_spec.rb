require 'spec_helper'

describe Bebox::Builder do
# TODO  update host file /etc/hosts
# TODO  generate the vagrant files
  subject{Bebox::Builder.new(@servers, @vbox_uri, @vagrant_box_base_name, "#{Dir.pwd }/tmp")}

  context 'folder' do

    it 'should create the directories' do
      directories_expected = ['config', 'deploy', 'templates']
      subject.create_directories
      directories = []
      directories << Dir["#{subject.new_project_root}/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.new_project_root}/*/*/"].map { |f| File.basename(f) }
      expect(directories.flatten).to include(*directories_expected)
    end
  end
  context 'files' do
    before :each do
      subject.create_directories
      #@servers = 3.times{|index| Bebox::Server.new("192.168.0.78#{index}", "server#{index}.pname.test")}
    end
    it 'should create local_host.rb template' do
      ############################
      content_expected = <<-RUBY
<% self.each do |server| %>

<%= server.ip %>   <%= server.hostname %>
<% end %>
      RUBY
      ############################
      subject.create_local_host_template
      output_file = File.read("#{Dir.pwd }/tmp/config/templates/local_hosts.erb")
      expect(output_file).to eq(content_expected)
    end
  end
end