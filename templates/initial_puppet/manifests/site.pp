node default {
	include stdlib
  include users
	class { 'sudo':
	  purge               => false,
	  config_file_replace => false,
  }
  include sudo
}