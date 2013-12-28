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



# needed for tesseract-ocr
package { 'autoconf':
}

package { 'automake':
}

package { 'libtool':
}

package { 'libpng10-devel':  # originally libpng12-dev
}

package { 'libjpeg-turbo-devel':  # originally libjpeg62-dev
}

package { 'libtiff-devel':  # originally libtiff4-dev
}

package { 'zlib-devel':  # originally zlib1g-dev
}

exec { 'install tesseract prereqs':
  command => '/bin/echo "tesseract prereqs installed through package manager"',
  require => [ 
               Package['autoconf'],
               Package['automake'],
               Package['libtool'],
               Package['libpng10-devel'],
               Package['libjpeg-turbo-devel'],
               Package['libtiff-devel'],
               Package['zlib-devel'],
             ]
}

# compile leptonica
exec { "retrieve leptonica":
  cwd     => "/tmp",
  command => "/usr/bin/wget http://www.leptonica.org/source/leptonica-1.69.tar.gz -O /tmp/leptonica-1.69.tar.gz",
  creates => "/tmp/leptonica-1.69.tar.gz",
  timeout => 3600,
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
               Exec['untar leptonica'],
               Exec['install tesseract prereqs'],
             ]
}
exec { 'make leptonica':
  cwd     => '/tmp/leptonica-1.69',
  command => '/usr/bin/make',
  creates => '/tmp/leptonica-1.69/src/adaptmap.o',
  require => Exec['configure leptonica'],
}
exec { 'install leptonica':
  cwd     => '/tmp/leptonica-1.69',
  command => '/usr/bin/make install',
  creates => '/usr/local/lib/liblept.so.3.0.0',
  require => Exec['make leptonica'],
}


# compile tesseract
exec { "retrieve tesseract":
  cwd     => "/tmp",
  command => "/usr/bin/wget https://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.02.tar.gz -O /tmp/tesseract-ocr-3.02.02.tar.gz",
  creates => "/tmp/tesseract-ocr-3.02.02.tar.gz",
  timeout => 3600,
}
exec { 'untar tesseract':
  cwd     => "/tmp",
  command => "/bin/tar xzf /tmp/tesseract-ocr-3.02.02.tar.gz",
  creates => "/tmp/tesseract-ocr",
  require => Exec['retrieve tesseract'],
}
exec { 'autogen tesseract':
  cwd     => '/tmp/tesseract-ocr',
  command => '/tmp/tesseract-ocr/autogen.sh',
  creates => '/tmp/tesseract-ocr/config/ltmain.sh',
  require => [ 
               Exec['install tesseract prereqs'],
               Exec['install leptonica'],
               Exec['untar tesseract'],
             ]
}
exec { 'configure tesseract':
  cwd     => '/tmp/tesseract-ocr',
  command => '/tmp/tesseract-ocr/configure',
  creates => '/tmp/tesseract-ocr/config.status',
  require => Exec['autogen tesseract'],
}
exec { 'make tesseract':
  cwd     => '/tmp/tesseract-ocr',
  command => '/usr/bin/make',
  creates => '/tmp/tesseract-ocr/ccmain/adaptations.o',
  require => Exec['configure tesseract'],
}
exec { 'install tesseract':
  cwd     => '/tmp/tesseract-ocr',
  command => '/usr/bin/make install',
  creates => '/usr/local/bin/tesseract',
  require => Exec['make tesseract'],
}
exec { 'ldconfig tesseract':
  cwd     => '/tmp/tesseract-ocr',
  command => '/sbin/ldconfig',
  require => Exec['install tesseract'],
}

# get language data
exec { "retrieve langauge data":
  cwd     => "/tmp",
  command => "/usr/bin/wget http://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.eng.tar.gz -O /tmp/tesseract-ocr-3.02.eng.tar.gz",
  creates => "/tmp/tesseract-ocr-3.02.eng.tar.gz",
  timeout => 3600,
  require => Exec['install tesseract'],
}
exec { 'install langauge data':
  cwd     => "/tmp",
  command => "/bin/tar xzf /tmp/tesseract-ocr-3.02.eng.tar.gz -C /usr/local/share/tessdata/  --strip-components 2",  # strip-components removes the 'tesseract-ocr/tessdata/' from the path inside the tar file
  creates => "/usr/local/share/tessdata/eng.cube.bigrams",
  require => Exec['retrieve langauge data'],
}


# test that tesseract is working correctly
exec { "retrieve jpg image of text":
  cwd     => "/tmp",
  command => "/usr/bin/wget http://upload.wikimedia.org/wikipedia/commons/5/5f/Dr._Jekyll_and_Mr._Hyde_Text.jpg -O /tmp/jekyll.jpg",
  creates => "/tmp/jekyll.jpg",
  timeout => 3600,
  #require => Exec['install langauge data'],
}
exec { "run ocr on jpg image of text":
  cwd     => "/tmp",
  command => "/usr/local/bin/tesseract /tmp/jekyll.jpg /tmp/jekyll",
  creates => "/tmp/jekyll.txt",
  timeout => 3600,
  require => Exec['retrieve jpg image of text'],
}
file { '/tmp/jekyll-correct.txt':
  content => template('yvonnesthing/jekyll-correct.txt.erb'),
}
exec { "compare jpg ocr run with golden":
  # failure returns error like "change from notrun to 0 failed: /usr/bin/diff /tmp/jekyll.txt /tmp/jekyll-correct.txt returned 1 instead of one of [0]"
  cwd     => "/tmp",
  command => "/usr/bin/diff /tmp/jekyll.txt /tmp/jekyll-correct.txt",
  require => Exec['run ocr on jpg image of text'],
}

exec { "retrieve tiff image of text":
  cwd     => "/tmp",
  command => "/usr/bin/wget https://sites.google.com/site/cff2doc/phototest.tif -O /tmp/lazydog.tiff",
  creates => "/tmp/lazydog.tiff",
  timeout => 3600,
  #require => Exec['install langauge data'],
}
exec { "run ocr on tiff image of text":
  cwd     => "/tmp",
  command => "/usr/local/bin/tesseract /tmp/lazydog.tiff /tmp/lazydog",
  creates => "/tmp/lazydog.txt",
  timeout => 3600,
  require => Exec['retrieve tiff image of text'],
}
file { '/tmp/lazydog-correct.txt':
  content => template('yvonnesthing/lazydog-correct.txt.erb'),
}
exec { "compare tiff ocr run with golden":
  # failure returns error like "change from notrun to 0 failed: /usr/bin/diff /tmp/lazydog.txt /tmp/lazydog-correct.txt returned 1 instead of one of [0]"
  cwd     => "/tmp",
  command => "/usr/bin/diff /tmp/lazydog.txt /tmp/lazydog-correct.txt",
  require => Exec['run ocr on tiff image of text'],
}

## TODO: png files don't work -- something to look into perhaps
#exec { "retrieve png image of text":
#  cwd     => "/tmp",
#  command => "/usr/bin/wget http://upload.wikimedia.org/wikipedia/commons/7/75/Dan%27l_Druce%2C_Blacksmith_-_Illustrated_London_News%2C_November_18%2C_1876_-_text.png -O /tmp/druce.png",
#  creates => "/tmp/druce.png",
#  timeout => 3600,
#  #require => Exec['install langauge data'],
#}
#exec { "run ocr on png image of text":
#  cwd     => "/tmp",
#  command => "/usr/local/bin/tesseract /tmp/druce.png /tmp/druce",
#  creates => "/tmp/druce.txt",
#  timeout => 3600,
#  require => Exec['retrieve png image of text'],
#}
#file { '/tmp/druce-correct.txt':
#  content => template('yvonnesthing/druce-correct.txt.erb'),
#}
#exec { "compare png ocr run with golden":
#  # failure returns error like "change from notrun to 0 failed: /usr/bin/diff /tmp/druce.txt /tmp/druce-correct.txt returned 1 instead of one of [0]"
#  cwd     => "/tmp",
#  command => "/usr/bin/diff /tmp/druce.txt /tmp/druce-correct.txt",
#  require => Exec['run ocr on png image of text'],
#}
