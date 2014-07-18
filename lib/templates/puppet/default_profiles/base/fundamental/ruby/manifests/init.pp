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

class profiles::base::fundamental::ruby {
  # Get rbenv options from hiera
  $rbenv_install_hash = { 'rbenv_install' => hiera('rbenv::install', {}) }
  $rbenv_compile_hash = hiera('rbenv::compile', {})
  $rbenv_gem_hash = hiera('rbenv::gem', {})
  # Install rbenv, ruby version and gems from options
  create_resources('rbenv::install', $rbenv_install_hash)
  create_resources('rbenv::compile', $rbenv_compile_hash)
  create_resources('rbenv::gem', $rbenv_gem_hash)
}