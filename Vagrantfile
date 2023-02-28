Vagrant.configure(2) do |config|

  # Configure all VM specs.
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.synced_folder ".", "/vagrant", type: "nfs"
  config.vm.box = "centos/stream8"
  config.vm.network "private_network", type: "dhcp", virtualbox__intnet: "kubernetes"
  config.vm.provision "shell",
    run: "always",
    inline: "ip route del default via 192.168.99.1 dev eth1; ip route add default via 192.168.99.1 dev eth1 metric 999"

  config.vm.define "ctrl" do |node|
    node.vm.hostname = "ctrl"
    node.vm.provision "shell", path: "./provision/controller.sh"
    node.vm.network "private_network", ip: "192.168.56.2", name: "kubernetes-hostonly"
  end

  starting_node = 1
  ending_node = 3

  starting_node.upto(ending_node) do |i| 
    config.vm.define "n#{i}" do |node|
      node.vm.hostname = "n#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{i + 2}", name: "kubernetes-hostonly"
      node.vm.provision "shell", path: "./provision/node.sh"
    end
  end

end
