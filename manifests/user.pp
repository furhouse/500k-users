Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

define users::user (
  $user,
  $home,
  $uid,
  $dotfilesrepo = undef,
  $ensure     = present,
  $gitname    = undef,
  $gitemail   = undef,
  $managehome = true,
  $groups     = [],
  $password   = undef,
  $smbpass    = undef,
  $ssh_keys   = {},
  $email      = undef,
  $shell      = '/bin/bash'
  ) {
  user { $title:
    ensure     => $ensure,
    name       => $user,
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
        'user'   => $user,
        require  => User["$title"],
      }
      create_resources(ssh_authorized_key, $ssh_keys, $ssh_defaults)
    }

    if $email {
      mailalias { "${title}-mailalias":
        name      => $user,
        ensure    => present,
        recipient => $email,
        require   => User["$title"],
      }
    }

    if $dotfilesrepo {
      file { "$home/.dotfiles":
        ensure => directory,
        path   => "$home/.dotfiles",
        owner  => $user,
        group  => $user,
      }
      vcsrepo { "${home}/.dotfiles":
        ensure   => latest,
        revision => master,
        path     => "${home}/.dotfiles",
        provider => git,
        source   => $dotfilesrepo,
        user     => $user,
        require  => User["$title"],
      }
    }

    if $gitname {
      exec { "${title}-gitname":
        command     => "git config --global user.name '$title'",
        path        => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        unless      => "grep name .gitconfig",
        user        => "$user",
        cwd         => "/home/${user}/",
        environment => ["HOME=/home/$user"],
        require     => [ User["$title"], Package['git'] ],
      }
    }

    if $gitemail {
      exec { "${title}-gitemail":
        command     => "git config --global user.email $email",
        path        => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        unless      => "grep email .gitconfig",
        user        => "$user",
        cwd         => "/home/${user}/",
        environment => ["HOME=/home/$user"],
        require     => [ User["$title"], Package['git'] ],
      }
    }

    if $smbpass {
      exec { "${title}-smb_user":
        command => "echo ${smbpass} | tee - | smbpasswd -a ${user} -s",
        unless  => "echo ${smbpass} | tee - | smbclient //${::hostname}/printers -U ${user}",
        path    => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        require => User["${user}"],
      }
    }

  }
}
