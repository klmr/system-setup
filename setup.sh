#!/usr/bin/env bash

# This script attempts to set up a clean environment based on my configuration,
# on a Mac system.
#
# THIS SCRIPT IS NOT DESIGNED TO RUN WITHOUT USER INPUT! In particular, the
# generation of the SSH keys will ask for user interaction.

scriptpath="$(cd "$(dirname "$0")"; pwd -P)"
USER="$(whoami)"
SYSTEM="$(uname)"

source 'helpers.sh'

# Install Command Line Tools & Homebrew ########################################

install-base-Darwin() {
	'xcode-select' --install

	if ! command -v brew > /dev/null 2>&1; then
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi

	login_shell="$(which bash)"
	if [ "$SHELL" != "$login_shell" ]; then
		grep "$login_shell" /etc/shells >/dev/null || \
			sudo bash -c 'echo "'"$login_shell"'" >> /etc/shells'
		chsh -s "$login_shell"
	fi
}

install-base-Linux() {
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
}

install-base() {
	install-base-$SYSTEM
}

# Install elementary applications ##############################################

install-homebrew() {
	brew update

	brew install bash
	brew install bash-completion2
	brew install git
	brew install wget
	brew install apparix
	brew install gcc
	brew install python
	brew install v8
	brew install node --with-full-icu
	brew install ruby
	brew install pandoc
	brew install zmq
	brew install ack
	brew install tree
	brew install ghostscript --with-x11
	brew install imagemagick --with-ghostscript --with-jp2 --with-librsvg --with-libwmf --with-webp --with-x11 --with-openmp
	brew install gist
	brew install htop
	brew install fastqc

	brew tap neovim/neovim

	brew install neovim --with-release

	brew tap tseemann/homebrew-bioinformatics-linux

	brew install trim-galore
}

install-homebrew-cask() {
	brew tap caskroom/cask

	brew cask update

	brew cask install iterm2
	brew cask install quicksilver
	brew cask install r
	brew cask install xquartz
	brew cask install google-chrome
	brew cask install google-drive
	brew cask install basictex
	brew cask install latexit
	brew cask install dropbox
	brew cask install skype
	brew cask install rstudio
}

# Install pip packages #########################################################

install-pip() {
	pip install --upgrade pip

	pip install ipython[all]
	pip install grip
	pip install cutadapt
	pip install multiqc
	pip install biopython
	pip install bcbio-gff
}

# Install gems #################################################################

install-gem() {
	gem install bundler
}

# Install npm packages #########################################################

install-npm() {
	pass
}

# Set up applications ##########################################################

# Set up Neovim

install-vim() {
	pip install neovim

	# Ensure directories exists
	mkdir -p ~/.config
	mkdir -p ~/.vim

	# Symlink Neovim configuration
	[ -e ~/.config/nvim ] || ln -s ~/.vim ~/.config/nvim
	[ -e ~/.config/nvim/init.vim ] || ln -s ~/.vimrc ~/.config/nvim/init.vim
}

# Clone personal settings #####################################################

clone-and-deploy-dotfiles() {
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

install-dotfiles() {
	[ -d ~/.files ] || clone-and-deploy-dotfiles
}

# Generate an SSH key ##########################################################

install-ssh-keys() {
	[ -e ~/.ssh/id_rsa ] || ssh-keygen
}

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
	setwidth
	jalvesaq/colorout
	hadley/pryr
	daattali/ezknitr
	httr
	optparse
	rstudio/packrat
	rvest
)

r_modules=(
	klmr/sys
	klmr/decorator
	ebi-predocs/ebits
)

r_bioc=(
	biomaRt
	Biostrings
	DESeq2
	piano
)

install-r-packages() {
	# Ensure package path exists because R insists on an existing path.
	# And since R doesn’t set it properly we need to grep for it rather than
	# getting it via `Rscript -e '.libPaths()[1]'`.
	q_pattern=['"'"'"]
	r_lib_path_pattern="\.libPaths(${q_pattern}\(.*\)${q_pattern})"
	r_lib_path="$(grep "$r_lib_path_pattern" .Rprofile | sed "s/$r_lib_path_pattern/\1/")"
	r_lib_path="${r_lib_path/#\~/$HOME}"
	mkdir -p $r_lib_path

	install-r packages "${r_packages[@]}"
	install-r modules "${r_modules[@]}"
	install-r bioc "${r_bioc[@]}"
}

# Install LaTeX packages #######################################################

tlmgr() {
	command tlmgr $@ 2> /dev/null
}

install-tex() {
	texlive_path="$(cd "$(kpsewhich -var-value TEXMFMAIN)/../../"; pwd -P)"

	[ "$(stat -f '%Su' "$texlive_path")" == "$USER" ] || \
		sudo chown -R "$USER" "$texlive_path"

	tlmgr update --self

	tlmgr install latexmk
	tlmgr install titlesec
	tlmgr install enumitem
}

# Install convenience scripts ##################################################

curl-install() {
	local source="$1"
	local target="bin/$(basename "$source")"
	if [ -x "$target" ]; then
		echo "$(basename "$target") already installed, skipping"
		return
	fi
	curl --progress-bar "$source" -o "$target" && chmod +x "$target"
}

install-scripts() {
	mkdir -p bin

	curl-install 'https://gist.githubusercontent.com/klmr/e51822f624292681ba98/raw/9dd556365c35587a9cd90bfef66f1f718c8eef92/printmakevars'
}

# Load the different installation modules ######################################

for module in modules/*; do
	if [ -f "$module" ]; then
		source "$module"
	fi
done

# Run installation modules #####################################################

modules=(
	base
	homebrew
	homebrew-cask
	pip
	gem
	npm
	vim
	dotfiles
	ssh-keys
	r-packages
	tex
	scripts
)

if [ "$*" != "" ]; then
	for module in "$@"; do
		if ! array-contains "$module" "${modules[@]}"; then
			echo >&2 "Invalid module '$module'"
			exit 1
		fi
	done

	modules=("$@")
fi

# Ensure we’re in the home directory.
cd ~

for module in "${modules[@]}"; do
	echo "Performing installation for $module"
	install-$module
	echo
done

# vim: noexpandtab
