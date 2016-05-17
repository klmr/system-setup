#!/usr/bin/env bash

# Upgrade the existing installation. Do not install additional packages.

brew-cask-upgrade() {
    local cask_path='/opt/homebrew-cask/Caskroom'
    local cask_list=("$cask_path"/*)

    for cask in "${cask_list[@]}"; do
        cask="$(basename "$cask")"
        if ! brew cask list | grep "^$cask$" > /dev/null; then
            brew cask install --force "$cask"
        fi
    done
}

# Clearing the entire cache seems to be the only way of ensuring that brew
# casks are installed from scratch rather than from cache. Identifying
# individual cache names for each cask reliably doesn’t seem to be easy, since
# the naming schemas are inconsistent and there there’s no obvious way of
# deriving the cache name from the cask name and/or metainfo.
rm -rf "$(brew --cache)"

# To ensure update will work even if merges exists.
GIT_MERGE_AUTOEDIT='no' brew update
brew upgrade
brew-cask-upgrade

pip install --upgrade pip

gem update --system

npm install npm -g

tlmgr update --self
tlmgr update --all
