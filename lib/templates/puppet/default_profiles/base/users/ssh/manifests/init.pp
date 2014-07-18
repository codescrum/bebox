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

class profiles::base::users::ssh {
  # Configure agent forwarding for application user
  $ssh_forwarding_hash = hiera_hash('ssh::client_rules', {})
  class { '::ssh::client':
    storeconfigs_enabled => false,
    options => $ssh_forwarding_hash
  }
}

# define profiles::users::get_forwarding_rules (
#   $ssh_forwarding_hash = {},
#   ) {
#   $forwarding_hosts = {}
#   each($ssh_forwarding_hash) |$user, $user_forwarding_hash| {
#     $hosts = $user_forwarding_hash[hosts]
#     each($hosts) |$host, $value| {
#       $host_hash = { "Host $host" => { 'User' => $user, 'ForwardAgent' => $value, 'StrictHostKeyChecking' => 'no' } }
#       $forwarding_hosts += $host_hash
#     }
#   }
#   profiles::users::forwarding { 'forwardinghosts':
#     forwarding_hosts => $forwarding_hosts,
#   }
# }

# define profiles::users::forwarding (
#   $forwarding_hosts = {},
#   ){
#   class { 'ssh::client':
#     storeconfigs_enabled => false,
#     options => $forwarding_hosts
#   }
# }