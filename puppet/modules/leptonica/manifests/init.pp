# = Class: leptonica
#
# Compiles and installs leptonica. http://www.leptonica.org/source/README.html
#
class leptonica {
  require leptonica::params
  
  package { 'gcc':
    ensure => $gcc_version,
  }
  
  /*****************************************************************************
   * COMPILE: http://www.leptonica.org/source/README.html#BUILDING             *
   *****************************************************************************/
  exec { 'retrieve leptonica':
    cwd     => "/tmp",
    command => "/usr/bin/wget http://www.leptonica.org/source/leptonica-1.69.tar.gz -O /tmp/leptonica-1.69.tar.gz",
    creates => "/tmp/leptonica-1.69.tar.gz",
    timeout => 600,
  }
  
  exec { 'untar leptonica':
    cwd     => "/tmp",
    command => "/bin/tar xzf /tmp/leptonica-1.69.tar.gz",
    creates => "/tmp/leptonica-1.69",
    require => Exec['retrieve leptonica'],
  }
  
  exec { 'configure leptonica':
    cwd     => '/tmp/leptonica-1.69',
    command => '/tmp/leptonica-1.69/configure',
    require => [ 
                 Package['gcc'],
                 Exec['untar leptonica'],
               ]
  }
  
  exec { 'make leptonica':
    cwd     => '/tmp/leptonica-1.69',
    command => '/usr/bin/make',
    creates => '/tmp/leptonica-1.69/src/adaptmap.o',
    require => Exec['configure leptonica'],
    timeout => 900,
  }
  
  exec { 'install leptonica':
    cwd     => '/tmp/leptonica-1.69',
    command => '/usr/bin/make install',
    creates => '/usr/local/lib/liblept.so.3.0.0',
    require => Exec['make leptonica'],
  }
}
