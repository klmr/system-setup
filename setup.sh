#!/usr/bin/env bash

# This script attempts to set up a clean environment based on my configuration,
# on a Mac system.
#
# THIS SCRIPT IS NOT DESIGNED TO RUN WITHOUT USER INPUT! In particular, the
# generation of the SSH keys will ask for user interaction.
#
# So far it is untested and will certainly not work out of the box.

# Ensure we’re in the home directory.

cd ~

# Install Homebrew #############################################################

if ! command -v brew > /dev/null 2>&1; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install elementary applications ##############################################

brew update

brew install git
brew install apparix
brew install gcc
brew install python
brew install pandoc
brew install zmq

brew tap neovim/neovim

brew install neovim --with-release

brew cask install quicksilver
brew cask install r
brew cask install xquartz
# brew cask install basictex

# Install pip ##################################################################

pip install --upgrade pip
pip install ipython[all]

# Set up applications ##########################################################

# Set up Neovim

pip install neovim

# Ensure directories exists
mkdir -p ~/.config
mkdir -p ~/.vim

# Symlink Neovim configuration
[ -e ~/.config/nvim ] || ln -s ~/.vim ~/.config/nvim
[ -e ~/.config/nvim/init.vim ] || ln -s ~/.vimrc ~/.config/nvim/init.vim

# Clone personal settings #####################################################

install-dotfiles() {
	pushd ~
	git clone https://github.com/klmr/.files.git
	cd .files
	tee local.conf <<-CONFIG > /dev/null
	core
	aliases
	apparix
	inputrc
	git
	c
	r
	tmux
	vim
	CONFIG

	./deploy <<< y
	popd
}

[ -d ~/.files ] || install-dotfiles

# Generate an SSH key ##########################################################

[ -e ~/.ssh/id_rsa ] || ssh-keygen

# Install R packages and modules ###############################################

r_packages=(
	devtools
	Rcpp
	hadley/devtools
	smbache/magrittr
	hadley/lazyeval
	hadley/dplyr
	hadley/tidyr
	hadley/testthat
	klutometis/roxygen
	hadley/ggplot2
	yihui/knitr
	rstudio/rmarkdown
	shiny
	hadley/readr
	hadley/readxl
	dgrtwo/broom
	rstudio/bookdown
	klmr/modules
)

r_modules=(
	klmr/sys
	klmr/decorator
	ebi-predocs/ebits
)

#'r args = commandArgs(trailingOnly = TRUE)
#'r type = args[1]
#'r items = unlist(strsplit(args[-1], ','))
#'r 
#'r install_module = function (name) {
#'r     # Here we assume is a fully qualified Github project name without release
#'r     # or similar shenanigans, to keep it simple.
#'r     # Replace with modules installer once that exists.
#'r     if (! grepl('^[\\w\\d-]+/[\\w\\d.-]+$', name, perl = TRUE))
#'r         stop('Invalid Github project name: ', dQuote(name))
#'r 
#'r     module_path = getOption('import.path', '.')
#'r     on.exit(setwd(oldwd))
#'r     oldwd = getwd()
#'r     dir.create(module_path, showWarnings = FALSE, recursive = TRUE)
#'r     setwd(module_path)
#'r 
#'r     # To keep dependencies slim, use command line git.
#'r     system2('git', c('clone', sprintf('git@github.com:%s.git', name), name))
#'r }
#'r 
#'r install_package = function (name) {
#'r     # Assume either a CRAN or an unadorned Github package name.
#'r     # Don’t do sanity check beyond that.
#'r     stopifnot(length(name) == 1)
#'r 
#'r     is_cran = ! grepl('/', name)
#'r     handler = if (is_cran) install.packages else devtools::install_github
#'r     handler(name)
#'r }
#'r 
#'r handler = switch(type,
#'r                  module = install_module,
#'r                  modules = install_module,
#'r                  package = install_package,
#'r                  packages = install_package,
#'r                  stop(sprintf('Invalid type %s', dQuote(type))))
#'r 
#'r invisible(lapply(items, handler))

install-r() {
	local type="$1"
	shift
	local IFS=','
	local items="$*"
	Rscript <(grep "^#'r " "$0" | sed "s/#'r //") "$type" "$items"
}

# Ensure package path exists because R insists on an existing path.
# And since R doesn’t set it properly we need to grep for it rather than getting
# it via `Rscript -e '.libPaths()[1]'`.
q_pattern=['"'"'"]
r_lib_path_pattern="\.libPaths(${q_pattern}\(.*\)${q_pattern})"
r_lib_path="$(grep "$r_lib_path_pattern" .Rprofile | sed "s/$r_lib_path_pattern/\1/")"
r_lib_path="${r_lib_path/#\~/$HOME}"
mkdir -p $r_lib_path

install-r packages "${r_packages[@]}"
install-r modules "${r_modules[@]}"

# vim: noexpandtab
