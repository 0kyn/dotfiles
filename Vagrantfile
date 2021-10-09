Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/bionic64"
    config.vm.hostname = "dotfiles"
    config.vm.network "private_network", ip: "192.168.50.4", hostname: true

    config.vm.synced_folder ".", "/home/vagrant/.dotfiles"

    # Update repositories
    config.vm.provision :shell, inline: "sudo apt update -y"

    # Upgrade installed packages
    config.vm.provision :shell, inline: "sudo apt upgrade -y"
    # Add desktop environment
    config.vm.provision :shell, inline: "sudo apt install -y --no-install-recommends ubuntu-desktop"
    config.vm.provision :shell, inline: "sudo apt install -y --no-install-recommends virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11"
    # Add `vagrant` to Administrator
    config.vm.provision :shell, inline: "sudo usermod -a -G sudo vagrant"
    # Restart
    config.vm.provision :shell, inline: "sudo shutdown -r now"
    
    config.vm.provider "virtualbox" do |v|
        v.name = "dotfiles"
        v.gui = true
        v.memory = 2048
        v.cpus = 1
    end
end
