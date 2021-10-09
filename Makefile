SHELL = /bin/bash

TMP = ./tmp

RELEASE_CODENAME = $(shell lsb_release -cs)
USER = $(shell ./functions.sh get ./config.ini user_name)
NODEJS_VERSION = $(shell ./functions.sh get ./config.ini nodejs_version)
TIMEZONE = $(shell ./functions.sh get ./config.ini system_timezone)
KEYBOARD_LAYOUT = $(shell ./functions.sh get ./config.ini system_keyboard_layout)

UPDATE := sudo apt update
INSTALL := sudo apt install --yes
UPDATE_INSTALL := $(UPDATE) && $(INSTALL)
APT_REPOSITORY := sudo add-apt-repository --yes --update

.DEFAULT_GOAL = help
.PHONY: help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-10s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

test:
	echo $(KEYBOARD_LAYOUT)

mktmp: rmtmp
	mkdir $(TMP)

rmtmp:
	-rm -r $(TMP)

all: upgrade system mktmp custom-shell install-utils install-packages install-custom  link dconf aliases restart-gnome ## update and install everything

update: ## update packages list
	$(UPDATE)

upgrade: update ## upgrade packages
	sudo apt dist-upgrade -y

install-utils: update ## install utils packages
	sudo xargs $(INSTALL) <./install/utils

install-packages: ## install packages
	sudo xargs $(INSTALL) <./install/packages

install-custom: mktmp copyq nodejs vscode docker vagrant virtualbox ansible google-chrome discord rmtmp ## install custom

link: ## symlink dotfiles
	sudo ./functions.sh link_files

system: ## run system config
	sudo sed -i 's/XKBLAYOUT=\"\w*\"/XKBLAYOUT=\"$(KEYBOARD_LAYOUT)\"/g' /etc/default/keyboard
	sudo setxkbmap $(KEYBOARD_LAYOUT)
	sudo timedatectl set-timezone $(TIMEZONE)

custom-shell: upgrade ## install zsh
	$(INSTALL) zsh
	sudo chsh -s /bin/zsh $(USER)
	curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o $(TMP)/oh-my-zsh-install.sh
	sh $(TMP)/oh-my-zsh-install.sh --unattended
	cp -f ./theme/okyn.zsh-theme /home/$(USER)/.oh-my-zsh/themes/okyn.zsh-theme
	git clone https://github.com/zsh-users/zsh-autosuggestions /home/$(USER)/.oh-my-zsh/custom/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting /home/$(USER)/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

dconf: ## apply gnome desktop settings
	dconf load /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ <./gnome/keybindings.dconf
	dconf load /org/gnome/shell/extensions/ <./gnome/extensions.dconf
	dconf load /org/gnome/desktop/ <./gnome/desktop.dconf
	dconf load /org/gnome/terminal/legacy/ <./gnome/legacy.dconf

aliases: ## add 00-aliases to root user
	sudo printf "\n if [ -f /etc/profile.d/00-aliases.sh ]; then \n \
        . /etc/profile.d/00-aliases.sh \n \
	fi" >> ~/.bashrc

restart-gnome: ## restart gnome shell
	# https://askubuntu.com/questions/100226/how-to-restart-gnome-shell-from-command-line
	# killall -3 gnome-shell
	echo "Restart your session"

copyq: ## install copyq
	$(APT_REPOSITORY) ppa:hluk/copyq
	$(INSTALL) copyq

nodejs: ## install NodeJS
	curl -fsSL https://deb.nodesource.com/setup_$(NODEJS_VERSION).x | sudo -E bash -
	$(INSTALL) nodejs

vscode: ## install Visual Studio Code
	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > $(TMP)/packages.microsoft.gpg
	sudo install -o root -g root -m 644 $(TMP)/packages.microsoft.gpg /etc/apt/trusted.gpg.d/
	sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
	rm -f $(TMP)/packages.microsoft.gpg
	$(INSTALL) apt-transport-https
	$(UPDATE_INSTALL) code
	cat ./install/vscode-extensions | xargs -I {} code --install-extension {}

docker: ## install Docker engine
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	sudo echo \
	"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
	$(RELEASE_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	$(UPDATE_INSTALL) docker-ce docker-ce-cli containerd.io
#	docker non root user | https://docs.docker.com/engine/install/linux-postinstall/
	- sudo groupadd docker
	sudo usermod -aG docker $(USER)

vagrant: ## install Vagrant
	sudo curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
	$(APT_REPOSITORY) "deb [arch=amd64] https://apt.releases.hashicorp.com $(RELEASE_CODENAME) main"
	$(INSTALL) vagrant

virtualbox: ## install VirtualBox
	sudo wget -q -O- http://download.virtualbox.org/virtualbox/debian/oracle_vbox_2016.asc | sudo apt-key add -
	$(APT_REPOSITORY) "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(RELEASE_CODENAME) contrib"
	$(INSTALL) virtualbox

ansible: ## install Ansible
	$(INSTALL) software-properties-common
	$(APT_REPOSITORY) ppa:ansible/ansible
	$(INSTALL) ansible
	$(INSTALL) sshpass 

google-chrome: ## install Google Chrome
	- wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o $(TMP)/google-chrome-stable_current_amd64.deb
	- sudo dpkg -i google-chrome-stable_current_amd64.deb 
	$(INSTALL) --fix-broken
	sudo dpkg -i google-chrome-stable_current_amd64.deb
	rm $(TMP)/google-chrome-stable_current_amd64.deb

discord: ## install Discord
	curl -J -L -o $(TMP)/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
	$(INSTALL) $(TMP)/discord.deb
	rm $(TMP)/discord.deb
