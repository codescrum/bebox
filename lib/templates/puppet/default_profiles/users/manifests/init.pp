# The profile class include the classes instantiation or
# puppet/modules type resource definitions.
# It can include hiera calls for the parametter setting.
# Example:
# class profiles::fooserver {
#   $fooport = hiera("fooserver_port")
#   class { "fooserver":
#     port  => $fooport
#   }
# }

class profiles::users {
  include ::users

  # Configure agent forwarding for application user
  $ssh_forwarding_hash = hiera_hash('ssh::client_rules', {})
  class { 'ssh::client':
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