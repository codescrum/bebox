require 'bebox/provision'
require 'bebox/node'

module Bebox
  class ProvisionWizard
    include Bebox::Logger
    include Bebox::WizardsHelper
    # Apply a step for the nodes in a environment
    def apply_step(project_root, environment, step)
      # Check if environment has configured the ssh keys
      (return warn "Please add a ssh key pair (id_rsa, id_rsa.pub) in config/keys/environments/#{environment} to do this step.") unless Bebox::Environment.check_environment_access(project_root, environment)
      nodes_to_step = Bebox::Node.nodes_in_environment(project_root, environment, previous_checkpoint(step))
      # Check if there are nodes for provisioning step-N
      (return warn "There are no nodes for provision in #{step}. No changes were made.") unless nodes_to_step.count > 0
      nodes_for_provisioning(nodes_to_step, step)
      # Apply the nodes provisioning for step-N
      in_step_nodes = Bebox::Node.list(project_root, environment, "steps/#{step}")
      nodes_to_step.each do |node|
        next unless check_node_to_step(node, in_step_nodes, step)
        provision_step_in_node(project_root, environment, step, in_step_nodes, node)
      end
    end

    def provision_step_in_node(project_root, environment, step, in_step_nodes, node)
      title "Provisioning #{step} in node #{node.hostname}:"
      role = Bebox::Provision.role_from_node(project_root, step, node.hostname)
      profiles = Bebox::Provision.profiles_from_role(project_root, role) unless role.nil?
      # Before apply generate the Puppetfile with modules from all associated profiles
      Bebox::Provision.generate_puppetfile(project_root, step, profiles) unless profiles.nil?
      # Before apply generate the roles and profiles modules structure for puppet step
      Bebox::Provision.generate_roles_and_profiles(project_root, step, role, profiles)
      provision = Bebox::Provision.new(project_root, environment, node, step)
      provision.apply.success? ? (ok "Node '#{node.hostname}' provisioned to #{step}.") : (error "An error ocurred in the provision of #{step} for node '#{node.hostname}'")
    end

    def check_node_to_step(node, in_step_nodes, step)
      return true unless in_step_nodes.include?(node.hostname)
      message = "The node '#{node.hostname}' was already provisioned in #{step}"
      message += " (start: #{node.checkpoint_parameter_from_file('steps/' + step, 'started_at')} - end: #{node.checkpoint_parameter_from_file('steps/' + step, 'finished_at')})."
      message += "\nDo you want to re-provision it?"
      confirm_action?(message)
    end

    def nodes_for_provisioning(nodes, step)
      title "Nodes for provisioning #{step}:"
      nodes.each{|node| msg(node.hostname)}
      linebreak
    end

    # Obtain the previous checkpoint (step/phase) for a node
    def previous_checkpoint(step)
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
  end
end