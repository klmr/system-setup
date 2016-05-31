install-r() {
	local type="$1"
	shift
	local IFS=','
	local items="$*"
	Rscript "$scriptpath/modules/r/install.r" "$type" "$items"
}

# vim: noexpandtab
