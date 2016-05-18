pass() {
	echo -n
}

array-contains() {
	local x
	for x in "${@:2}"; do
		if [[ "$x" == "$1" ]]; then
			return 0
		fi
	done

	return 1
}
