# -*- mode: ruby -*-
# vi: set ft=ruby :

provision = <<-EOS
  sudo apt-get update -yqq
  sudo apt-get install -yqq python-pip git
  sudo apt-get autoremove -y
  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"
  pip install --user cookiecutter
  echo '[ -d "${HOME}"/.local/bin ] && PATH="${HOME}"/.local/bin:"${PATH}"' >> "${HOME}"/.bashrc
EOS

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  config.vm.box = 'ubuntu/trusty64'
  config.vm.provision :shell, inline: provision
  config.ssh.forward_agent = true
end
