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
  include users
}