# Dotfiles

This is "anotherother" dotfiles repo, that stands my needs. Feel free to take anything you want at your own risks.

## Installation

1. Clone the repository

```bash
git clone https://github.com/0kyn/dotfiles ~/.dotfiles

```

2. Use the [Makefile](./Makefile) to install whatever you want

```bash
cd ~/.dotfiles

make
# will display available commands
```

## Configuration

`./config.ini` contains system and programs configurations (timezone, keyboard layouts...)

`./dotfiles.ini` contains each dotfiles present in `config` folder and the target where its symbolic link should point to.
```ini
[tmux]
config=~/.tmux.conf

# tmux config file ~/.dotfile/config/tmux/.tmux.conf will target ~/.tmux.conf
```

## Usage

### Test

To test this dotfiles manager, you should run a VM with Vagrant.

```bash
# this will run Ubuntu 18.04
vagrant up
```

```bash
# Into the Vagrant box
# user: vagrant
# pwd:  vagrant

cd ~/.dotfiles

make all
```

## License

[MIT](https://choosealicense.com/licenses/mit/)