require 'pry'
module Bebox
  class ProvisionWizard
    include Bebox::Logger
    include Bebox::WizardsHelper
    # Apply a step for the nodes in a environment
    def apply_step(project_root, environment, step)
      # Check if environment has configured the ssh keys
      (return warn _('wizard.provision.ssh_key_advice')%{environment: environment}) unless Bebox::Environment.check_environment_access(project_root, environment)
      nodes_to_step = Bebox::Node.nodes_in_environment(project_root, environment, previous_checkpoint(step))
      # Check if there are nodes for provisioning step-N
      (return warn _('wizard.provision.no_provision_nodes')%{step: step}) unless nodes_to_step.count > 0
      nodes_for_provisioning(nodes_to_step, step)
      # Apply the nodes provisioning for step-N
      in_step_nodes = Bebox::Node.list(project_root, environment, "phase-2/steps/#{step}")
      outputs = []
      nodes_to_step.each do |node|
        next unless check_node_to_step(node, in_step_nodes, step)
        outputs << provision_step_in_node(project_root, environment, step, in_step_nodes, node)
      end
      return outputs
    end

    def provision_step_in_node(project_root, environment, step, in_step_nodes, node)
      title _('wizard.provision.title')%{step: step, hostname: node.hostname}
      generate_pre_provision_files(project_root, step, node)
      provision = Bebox::Provision.new(project_root, environment, node, step)
      output = provision.apply.success?
      output ? (ok _('wizard.provision.apply_success')%{hostname: node.hostname, step: step}) : (error _('wizard.provision.apply_failure')%{step: step, hostname: node.hostname})
      return output
    end

    def generate_pre_provision_files(project_root, step, node)
      role = Bebox::Provision.role_from_node(project_root, step, node.hostname)
      profiles = Bebox::Provision.profiles_from_role(project_root, role) unless role.nil?
      # Before apply generate the Puppetfile with modules from all associated profiles
      Bebox::Provision.generate_puppetfile(project_root, step, profiles) unless profiles.nil?
      # Before apply generate the roles and profiles modules structure for puppet step
      Bebox::Provision.generate_roles_and_profiles(project_root, step, role, profiles)
    end

    def check_node_to_step(node, in_step_nodes, step)
      return true unless in_step_nodes.include?(node.hostname)
      confirm_action?(_('wizard.provision.confirm_reprovision')%{hostname: node.hostname, step: step, start: node.checkpoint_parameter_from_file('phase-2/steps/' + step, 'started_at'), end: node.checkpoint_parameter_from_file('phase-2/steps/' + step, 'finished_at')})
    end

    def nodes_for_provisioning(nodes, step)
      title _('wizard.provision.nodes_title')%{step: step}
      nodes.each{|node| msg(node.hostname)}
      linebreak
    end

    # Obtain the previous checkpoint (step/phase) for a node
    def previous_checkpoint(step)
      case step
        when 'phase-1'
          'phase-0'
        when 'step-0'
          'phase-1'
        when 'step-1'
          'phase-2/steps/step-0'
        when 'step-2'
          'phase-2/steps/step-1'
        when 'step-3'
          'phase-2/steps/step-2'
      end
    end
  end
end