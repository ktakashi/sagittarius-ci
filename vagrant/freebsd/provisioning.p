config.vm.provision "shell", inline: <<-SHELL
  pkg install -fy #{packages}
SHELL
