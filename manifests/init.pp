class users {

  $user = hiera_hash('realuser', {})

  create_resources('users::user', $user)

}
