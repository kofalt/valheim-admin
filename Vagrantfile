# https://docs.vagrantup.com

Vagrant.configure(2) do |config|

	# Box provided by Ubuntu
	# config.vm.box = "ubuntu/bionic64" # 18.04
	# config.vm.box = "ubuntu/cosmic64" # 18.10
	# config.vm.box = "ubuntu/disco64"  # 19.04
	# config.vm.box = "ubuntu/eoan64"   # 19.10
	# config.vm.box = "ubuntu/focal64"  # 20.04
	config.vm.box = "ubuntu/groovy64"  # 20.10

	# Run `vagrant box outdated` to manually update.
	config.vm.box_check_update = false

	# Forward a port
	# config.vm.network "forwarded_port", guest: 80, host: 8080

	# Host-only access to the machine using a specific IP.
	# config.vm.network "private_network", ip: "192.168.33.10"

	# Bridged networking: guest appears as another physical device.
	# config.vm.network "public_network"
	config.vm.network "public_network", bridge: "bridge0"

	# Share an additional folder to the guest VM.
	# config.vm.synced_folder ".", "/example", mount_options: ["rw"]

	# Virtualbox management
	config.vm.provider "virtualbox" do |vb|
		# Run headless
		vb.gui = false

		vb.customize ["modifyvm", :id,
			# Better I/O, disable if problems
			"--ioapic", "on",

			# Set this to the number of physical CPU cores
			"--cpus",   "4",

			# RAM allocation
			"--memory", "4096"
		]
	end

	# A script for no-brainer setup
	config.vm.provision "shell", inline: <<-SHELL
		# Start in /vagrant (default shared folder)
		echo "test -d /vagrant && cd /vagrant" >> /home/vagrant/.bashrc
	SHELL

	# Add an external script
	# config.vm.provision "shell", :path => "vagrant-create.sh"
	# config.vm.provision "shell", :path => "vagrant-every.sh", :run => "always"
end
