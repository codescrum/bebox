require_relative '../puppet'
require_relative '../node'
require 'highline/import'

module Bebox
  class PuppetWizard

    # Apply a step for the nodes in a environment
    def self.apply_step(project_root, environment, step)
      # Check if environment has configured the ssh keys
      if Bebox::Environment.check_environment_access(project_root, environment)
        # Check already in step nodes
        nodes_to_step = check_nodes_to_step(project_root, environment, step)
        binding.pry
        # Output the nodes that are ready for provisioning step-N
        if nodes_to_step.count > 0
          say("\nProvisioning #{step} in nodes: \n")
          nodes_to_step.each{|node| say(node.hostname)}
          say("\n")
          # Apply the nodes provisioning for step-N
          nodes_to_step.each do |node|
            role = Bebox::Puppet.role_from_node(project_root, step, node.hostname)
            profiles = Bebox::Puppet.profiles_from_role(project_root, role) unless role.nil?
            Bebox::Puppet.generate_puppetfile(project_root, step, profiles) unless profiles.nil?
            Bebox::Puppet.generate_roles_and_profiles(project_root, step, role, profiles)
            puppet = Bebox::Puppet.new(project_root, environment, node, step)
            puppet.apply
          end
        else
          say("\nThere are no nodes for provision in #{step}. Nothing done.\n\n")
        end
      else
        say("\nPlease add the ssh key pair (id_rsa, id_rsa.pub) in config/keys/environments/#{environment} to do this step.")
      end
    end

    # Check the nodes already in step and ask confirmation to re-do-it
    def self.check_nodes_to_step(project_root, environment, step)
      nodes_to_step = []
      nodes = Bebox::Node.nodes_in_environment(project_root, environment, previous_checkpoint(step))
      in_step_nodes = Bebox::Node.list(project_root, environment, "steps/#{step}")
      nodes.each do |node|
        if in_step_nodes.include?(node.hostname)
          nodes_to_step << node if confirm_node_step?(node, step)
        else
          nodes_to_step << node
        end
      end
      nodes_to_step
    end

    # Obtain the previous checkpoint (step/phase) for a node
    def self.previous_checkpoint(step)
      case step
        when 'prepared_nodes'
          'nodes'
        when 'step-0'
          'prepared_nodes'
        when 'step-1'
          'steps/step-0'
        when 'step-2'
          'steps/step-1'
        when 'step-3'
          'steps/step-2'
      end
    end

    # Ask for confirmation of node step
    def self.confirm_node_step?(node, step)
      say("The node #{node.hostname} is already in #{step}. Do you want to re-provision it?")
      response =  ask("(y/n)")do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end
  end
end