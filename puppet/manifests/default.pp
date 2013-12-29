include epel

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

include tesseract
