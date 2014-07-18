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

class profiles::base::security::fail2ban {
  # Obtain fail2ban parameters from hiera
  $fail2ban_parameters = hiera('fail2ban', {})
  $bantime = $fail2ban_parameters[bantime]
  $maxretry = $fail2ban_parameters[maxretry]
  $mailto = $fail2ban_parameters[destemail]

  # Instance the fail2ban class with hiera parameters
  class { '::fail2ban':
    bantime => $bantime,
    maxretry => $maxretry,
    mailto => $mailto,
  }
}
