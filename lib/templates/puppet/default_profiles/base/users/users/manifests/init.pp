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

class profiles::base::users::users {
  # Module users internally load parameters from hiera
  include ::users
}