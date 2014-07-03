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

class profiles::fundamental {
  include stdlib
  include users
  include install_sudo
  include rbenv
}

class install_sudo {
  class { 'sudo':
    purge               => false,
    config_file_replace => false,
  }
}

class rbenv {
  $rbenv_install_hash = { 'rbenv_install' => hiera('rbenv::install', {}) }
  $rbenv_compile_hash = hiera('rbenv::compile', {})
  $rbenv_gem_hash = hiera('rbenv::gem', {})
  create_resources('rbenv::install', $rbenv_install_hash)
  create_resources('rbenv::compile', $rbenv_compile_hash)
  create_resources('rbenv::gem', $rbenv_gem_hash)
}