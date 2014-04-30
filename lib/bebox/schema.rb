class Schema
  class << self
    def create_folders
      `mkdir config && mkdir config/deploy && mkdir config/templates`
    end

    def create_files(hosts, vbox_uri)
      create_vagrant_file
    end

    def create_vagrant_file

    end

    def config_local_hosts_file(hosts, vbox_uri)
      servers = hosts.map(&:hostname)
      template = Tilt::ERBTemplate.new("#{Dir.pwd}/config/templates/local_hosts.erb")
      nameservers = template.render(servers)
      is_hosts_configured = true
      nameservers.each_line.with_index do |hostname, index|
        unless index==0
          is_hosts_configured &= run_locally("if grep -q '#{hostname}' '#{local_hosts_file_location}/hosts'; then echo 'true'; else echo 'false'; fi").strip == 'true'
        end
      end
      puts is_hosts_configured
      if is_hosts_configured
        puts 'the host file is already configured'
      else
        puts 'Configuring hosts file'
        run_locally "#{sudo} cp #{local_hosts_file_location}/hosts #{local_hosts_file_location}/hosts_.test"
        run_locally "#{sudo} chmod 777 #{local_hosts_file_location}/hosts_.test"
        # Write the template
        File.open("#{local_hosts_file_location}/hosts_.test", 'a') {|f| f.write nameservers}
        run_locally "#{sudo} mv #{local_hosts_file_location}/hosts_.test #{local_hosts_file_location}/hosts"
      end
    end

    def create_local_host_template
      File::open("#{Dir.pwd}/config/templates/local_hosts.erb", "w") do |f|
        #f << EOF
        #  # -*- mode: ruby -*-
        #  # vi: set ft=ruby :
        #
        #  Vagrant.configure("2") do |config|
        #  <% self.each_with_index do |server, index| %>
        #    config.vm.define :node_<%= index %> do |node|
        #      node.vm.box = "ubuntu1204x64_<%= index %>"
        #      node.vm.hostname = "<%= server['hostname'] %>"
        #      node.vm.network :public_network, :bridge => 'en0: Ethernet', :auto_config => false
        #      node.vm.provision :shell, :inline => "sudo ifconfig eth1 <%= server['ipaddress'] %> netmask 255.255.255.0 up"
        #    end
        #  <% end %>
        #  end
        #EOF
      end
    end
  end
end
Schema.create_local_host_template