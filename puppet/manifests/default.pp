# main puppet manifest for node.js box
include epel
include nodejs

# You might want to put something here configuring the firewall 
# to allow access to the port needed for the application.
# For example, to open up port 443:
include firewall
firewall { '100 allow 443':
  state  => ['NEW'],
  dport  => '443',
  proto  => 'tcp',
  action => 'accept',
}

firewall { '100 allow 80':
  state  => ['NEW'],
  dport  => '80',
  proto  => 'tcp',
  action => 'accept',
}
# Thanks to Jason Hancock for guidance on this!
# http://geek.jasonhancock.com/2011/10/11/managing-iptables-firewalls-with-puppet/

package { 'forever':
  ensure   => installed,
  provider => 'npm',
  require  => Package['nodejs'],
}

file { '/etc/rc.d/init.d/yvonnesthing':
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
  content => template('yvonnesthing/service.erb'),
}

service { 'yvonnesthing':
  ensure => "running",
  require => File['/etc/rc.d/init.d/yvonnesthing']
}
