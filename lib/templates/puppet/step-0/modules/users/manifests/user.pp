
define users::user($email, $uid, $key)  {
  $username = $title

  $groups = ["root", "sudo"]

  user { $username:
    ensure     => present,
    comment    => "${email}",
    home       => "/home/${username}",
    shell      => "/bin/bash",
    groups     => $groups,
    membership => "inclusive",
    uid        => $uid,
    managehome => true,
    # Generated from openssl passwd -1 in the server
    # by default 'bebox'
    password   => '$1$x3VGbtoD$igWgkE/f.P3QpQjOZcTBz/'
  }

  group { $username:
    gid     => $uid,
    require => User[$username],
  }

  file { "/home/${username}/":
    ensure  => directory,
    owner   => $username,
    group   => $username,
    mode    => 0644,
    require => [ User[$username], Group[$username] ]
  }

  file { "/home/${username}/.ssh":
    ensure  => directory,
    owner   => $username,
    group   => $username,
    mode    => 0600,
    require => File["/home/${username}/"],
  }

  file { "/home/${username}/.ssh/authorized_keys":
    ensure  => present,
    owner   => $username,
    group   => $username,
    mode    => 0600,
    require => File["/home/${username}/.ssh"],
    content => $key,
  }
}
