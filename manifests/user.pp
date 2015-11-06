define users::user (
  $name,
  $home,
  $uid ,
  $dotfilesrepo,
  $ensure     = present,
  $gitname    = "$title",
  $gitemail   = "$email",
  $managehome = true,
  $groups     = [],
  $password   = 'undef',
  $ssh_keys   = {},
  $email      = 'undef',
  $shell      = '/bin/bash'
  ) {
  user { $title:
    ensure     => $ensure,
    name       => $name,
    managehome => $managehome,
    home       => $home,
    uid        => $uid,
    groups     => $groups,
    password   => $password,
    shell      => $shell,
  }

  if $ensure == 'present' {
    if $ssh_keys {
      $ssh_defaults = {
        'ensure' => 'present',
        'type'   => 'ssh-rsa',
        'user'   => $name,
        require  => User["$title"],
      } create_resources(ssh_authorized_key, $ssh_keys, $ssh_defaults)
    }

    if $email {
      mailalias { "${title}-mailalias":
        name      => $name,
        ensure    => present,
        recipient => $email,
        require   => User["$title"],
      }
    }

    if $dotfilesrepo {
      file { "$home/.dotfiles":
        ensure => directory,
        path   => "$home/.dotfiles",
        owner  => $name,
        group  => $name,
      }
      vcsrepo { "${home}/.dotfiles":
        ensure   => latest,
        revision => master,
        path     => "${home}/.dotfiles",
        provider => git,
        source   => $dotfilesrepo,
        user     => $name,
        require  => User["$title"],
      }
    }

    if $gitname {
      exec { "${title}-gitname":
        command     => "git config --global user.name '$title'",
        path        => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        unless      => "grep name .gitconfig",
        user        => "$name",
        cwd         => "/home/${name}/",
        environment => ["HOME=/home/$name"],
        require     => [ User["$title"], Package['git'] ],
      }
    }

    if $gitemail {
      exec { "${title}-gitemail":
        command     => "git config --global user.email $email",
        path        => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        unless      => "grep email .gitconfig",
        user        => "$name",
        cwd         => "/home/${name}/",
        environment => ["HOME=/home/$name"],
        require     => [ User["$title"], Package['git'] ],
      }
    }

  }
}
