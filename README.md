# My dotfiles

## Create bare repository

[Atlassian Tutorial](https://www.atlassian.com/git/tutorials/dotfiles)

```bash
# Create bare repo
git init --bare $HOME/.dotfiles
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
config config --local status.showUntrackedFiles no
echo "alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'" >> $HOME/.bashrc

# add git repo
config remote add origin https://gitlab.com/lkfiles/dotfiles.git

# Versioning now with config instead of git
config status
config add .vimrc
config commit -m "Add vimrc"
config add .bashrc
config commit -m "Add bashrc"
config push
```

## Installing dotfiles onto a new system (or migrate to this setup)

Run Script /scripts/dotfiles-install/dotfiles-install.sh

```bash
#!/bin/bash

git clone --bare https://gitlab.com/lkfiles/dotfiles.git $HOME/dotfiles
function config {
   /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}
mkdir -p .dotfiles-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .dotfiles-backup/{}
fi;
config checkout
config config status.showUntrackedFiles > no
```
Create alias for git

```bash
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```
