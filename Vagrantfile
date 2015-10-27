# -*- mode: ruby -*-
# # vi: set ft=ruby :

$proxy = ""
#$proxy = "10.0.2.2:8888"

Vagrant.configure(2)  do |config|

  if $proxy != ""
    config.proxy.http     = "http://" + $proxy
    config.proxy.https    = "http://" + $proxy
    config.proxy.no_proxy = "localhost,127.0.0.1"
  end

  if Vagrant.has_plugin?("vagrant-timezone")
    config.timezone.value = "Europe/Berlin"
  end
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope       = :box
    config.cache.auto_detect = true
  end

  config.vm.box = "bento/centos-7.1"

  config.vm.provider :virtualbox do |v|
     #vb.gui  = true
     v.customize ["modifyvm", :id, "--audio",  "none"]
     v.customize ["modifyvm", :id, "--ioapic", "on"]
     v.customize ["modifyvm", :id, "--vram",   "10"]
     # syncronize time
     v.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 3000]
  end

  config.vm.define "glog01" do |glog01|
    glog01.vm.hostname = "glog01"
    glog01.vm.network "private_network", ip: "172.16.100.53"
    glog01.vm.provision "node", type: "shell" do |s|
        s.path = "provision-node.sh"
        s.args = "glog01 " + $proxy
    end
    glog01.vm.provision "firststart", type: "shell" do |s|
        s.path = "provision-firststart.sh"
    end
    config.vm.provider "virtualbox" do |v|
      v.memory = 3072
    end
  end
  config.vm.define "glog02" do |glog02|
    glog02.vm.hostname = "glog02"
    glog02.vm.network "private_network", ip: "172.16.100.54"
    glog02.vm.provision "node", type: "shell" do |s|
        s.path = "provision-node.sh"
        s.args = "glog02 " + $proxy
    end
    glog02.vm.provision "firststart", type: "shell" do |s|
        s.path = "provision-firststart.sh"
    end
    config.vm.provider "virtualbox" do |v|
      v.memory = 3072
    end
  end
  config.vm.define "glog03" do |glog03|
    glog03.vm.hostname = "glog03"
    glog03.vm.network "private_network", ip: "172.16.100.55"
    glog03.vm.provision "node", type: "shell" do |s|
        s.path = "provision-node.sh"
        s.args = "glog03 " + $proxy
    end
    glog03.vm.provision "firststart", type: "shell" do |s|
        s.path = "provision-firststart.sh"
    end
    config.vm.provider "virtualbox" do |v|
      v.memory = 3072
    end
  end
  config.vm.define "omd01", autostart: false do |omd01|
    omd01.vm.hostname = "omd01"
    omd01.vm.network "private_network", ip: "172.16.100.60"
    omd01.vm.provision "omd", type: "shell" do |s|
        s.path = "provision-omd.sh"
    end
    config.vm.provider "virtualbox" do |v|
      v.memory = 1024
    end
  end
  config.vm.define "splunk01", autostart: false do |splunk01|
    splunk01.vm.hostname = "splunk01"
    splunk01.vm.network "private_network", ip: "172.16.100.70"
    splunk01.vm.provision "splunk", type: "shell" do |s|
        s.path = "provision-splunk.sh"
    end
    config.vm.provider "virtualbox" do |v|
      v.memory = 1024
    end
  end
end
