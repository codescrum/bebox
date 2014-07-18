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

class profiles::base::security::ssh {
  # Obtain ssh parameters from hiera
  $ssh_parameters = hiera('ssh::server', {})
  $port = $ssh_parameters[port]
  $password_authentication = $ssh_parameters[password_authentication]
  $pubkey_authentication = $ssh_parameters[pubkey_authentication]
  $permit_root_login = $ssh_parameters[permit_root_login]

  # Instance the ssh::server class with hiera parameters
  class { '::ssh::server':
    port => $port,
    password_authentication => $password_authentication,
    pubkey_authentication => $pubkey_authentication,
    permit_root_login => $permit_root_login,
  }
}