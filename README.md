# My dotfiles

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
