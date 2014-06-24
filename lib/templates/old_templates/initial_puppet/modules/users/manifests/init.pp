class users {

  $hiera_users = hiera("user_accounts")
  each($hiera_users) |$value| {
    $name = $value[name]
    $email = $value[email]
    $uid = $value[uid]
    $key = $value[key]
    users::user { $name:
      email => $email,
      uid => $uid,
      key => $key,
    }
  }
}
