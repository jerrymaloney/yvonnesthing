# = Class: tesseract
#
# Compiles and installs Tesseract OCR engine.
#
class tesseract inherits tesseract::params {  # has to inherit instead of require because http://docs.puppetlabs.com/puppet/3/reference/lang_classes.html#appendix-smart-parameter-defaults
  require leptonica
  
  package { 'autoconf':
    ensure => 'installed',
  }
  package { 'automake':
    ensure => 'installed',
  }
  package { 'libtool':
    ensure => 'installed',
  }
  package { $libpng_packagename:
    ensure => 'installed',
  }
  package { $libjpeg_packagename:
    ensure => 'installed',
  }
  package { $libtiff_packagename:
    ensure => 'installed',
  }
  package { $zlib_packagename:
    ensure => 'installed',
  }
  exec { 'install prereqs':
    # this is just a noop wrapper to make dependency management clearer
    command => '/bin/echo "tesseract prereqs installed through package manager"',
    require => [ 
                 Package['autoconf'],
                 Package['automake'],
                 Package['libtool'],
                 Package[$libpng_packagename],
                 Package[$libjpeg_packagename],
                 Package[$libtiff_packagename],
                 Package[$zlib_packagename],
               ]
  }
  
  
  /*****************************************************************************
   * COMPILE                                                                   *
   *****************************************************************************/
  exec { 'retrieve tesseract':
    cwd     => "/tmp",
    command => "/usr/bin/wget https://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.02.tar.gz -O /tmp/tesseract-ocr-3.02.02.tar.gz",
    creates => "/tmp/tesseract-ocr-3.02.02.tar.gz",
    timeout => 600,
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
                 Exec['install prereqs'],
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
    timeout => 900,
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
  
  
  /*****************************************************************************
   * GET LANGUAGE DATA                                                         *
   * This is the trained model that will enable us to run OCR with no training *
   * of our own.                                                               *
   * https://code.google.com/p/tesseract-ocr/wiki/Compiling#Language_Data      *
   *****************************************************************************/
  exec { "retrieve language data":
    cwd     => "/tmp",
    command => "/usr/bin/wget http://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.eng.tar.gz -O /tmp/tesseract-ocr-3.02.eng.tar.gz",
    creates => "/tmp/tesseract-ocr-3.02.eng.tar.gz",
    timeout => 600,
    require => Exec['install tesseract'],
  }
  
  exec { 'install language data':
    cwd     => "/tmp",
    command => "/bin/tar xzf /tmp/tesseract-ocr-3.02.eng.tar.gz -C /usr/local/share/tessdata/  --strip-components 2",  # strip-components removes the 'tesseract-ocr/tessdata/' from the path inside the tar file
    creates => "/usr/local/share/tessdata/eng.cube.bigrams",
    require => Exec['retrieve language data'],
  }
  
  
  /*****************************************************************************
   * TEST                                                                      *
   * Test that tesseract is working correctly by running OCR on a few things.  *
   *****************************************************************************/
  # JPEG test
  exec { "retrieve jpg image of text":
    cwd     => "/tmp",
    command => "/usr/bin/wget http://upload.wikimedia.org/wikipedia/commons/5/5f/Dr._Jekyll_and_Mr._Hyde_Text.jpg -O /tmp/jekyll.jpg",
    creates => "/tmp/jekyll.jpg",
    timeout => 15,
    require => Exec['install language data'],
  }
  
  exec { "run ocr on jpg image of text":
    cwd     => "/tmp",
    command => "/usr/local/bin/tesseract /tmp/jekyll.jpg /tmp/jekyll",
    creates => "/tmp/jekyll.txt",
    timeout => 60,
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
  
  
  # TIFF test
  exec { "retrieve tiff image of text":
    cwd     => "/tmp",
    command => "/usr/bin/wget https://sites.google.com/site/cff2doc/phototest.tif -O /tmp/lazydog.tiff",
    creates => "/tmp/lazydog.tiff",
    timeout => 15,
    require => Exec['install language data'],
  }
  
  exec { "run ocr on tiff image of text":
    cwd     => "/tmp",
    command => "/usr/local/bin/tesseract /tmp/lazydog.tiff /tmp/lazydog",
    creates => "/tmp/lazydog.txt",
    timeout => 60,
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
  # PNG test
  #exec { "retrieve png image of text":
  #  cwd     => "/tmp",
  #  command => "/usr/bin/wget http://upload.wikimedia.org/wikipedia/commons/7/75/Dan%27l_Druce%2C_Blacksmith_-_Illustrated_London_News%2C_November_18%2C_1876_-_text.png -O /tmp/druce.png",
  #  creates => "/tmp/druce.png",
  #  timeout => 15,
  #  require => Exec['install language data'],
  #}
  #
  #exec { "run ocr on png image of text":
  #  cwd     => "/tmp",
  #  command => "/usr/local/bin/tesseract /tmp/druce.png /tmp/druce",
  #  creates => "/tmp/druce.txt",
  #  timeout => 60,
  #  require => Exec['retrieve png image of text'],
  #}
  #
  #file { '/tmp/druce-correct.txt':
  #  content => template('yvonnesthing/druce-correct.txt.erb'),
  #}
  #
  #exec { "compare png ocr run with golden":
  #  # failure returns error like "change from notrun to 0 failed: /usr/bin/diff /tmp/druce.txt /tmp/druce-correct.txt returned 1 instead of one of [0]"
  #  cwd     => "/tmp",
  #  command => "/usr/bin/diff /tmp/druce.txt /tmp/druce-correct.txt",
  #  require => Exec['run ocr on png image of text'],
  #}
}
