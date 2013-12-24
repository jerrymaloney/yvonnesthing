sudo puppet apply puppet/manifests/default.pp --modulepath puppet/modules
sudo mkdir /usr/local/lib/node_modules/yvonnesthing
sudo cp src/* /usr/local/lib/node_modules/yvonnesthing/.
sudo service yvonnesthing restart
