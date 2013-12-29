# = Class: leptonica params
class leptonica::params {
  
  $gcc_version = $operatingsystemmajrelease ? {
    5 => '4.4.7-4',
    6 => '4.4.7-4.el6',
  }
  
}
