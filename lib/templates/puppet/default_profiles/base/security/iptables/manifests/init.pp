# The profile class include the classes instantiation or
# puppet/modules type resource definitions.
# It can include hiera calls for the parametter setting.
# Example:
# class profiles::category::technology {
#   $technology_parameters = hiera("technology")
#   $parameter1 = technology_parameters[parameter1]
#   ...
#   class { "technology_resource":
#     parameter1  => $parameter1
#     ...
#   }
# }

class profiles::base::security::iptables {
  # Make the rules persist after shutdown
  package { 'iptables-persistent':
    ensure => present
  }
  resources { "firewall":
    purge => true,
    require => Package['iptables-persistent'],
  }
  # Obtain iptables parameters from hiera and create firewall rules
  $firewall_rules_hash = hiera('firewall', {})
  create_resources('firewall', $firewall_rules_hash)
}
