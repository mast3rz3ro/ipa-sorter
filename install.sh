#!/bin/bash


		f="./ipa-sorter.sh" # utility to install
		x="ipa-sorter"      # command to call for usage
		deps="plistutil plget unzip 7z awk"
		echo "- preparing for installing: $x"
	if [ -s "/private/preboot/active" ]; then
		c="$(cat "/private/preboot/active")"
	else
		echo "- error installing on this device is not supported."
		exit 1
	fi

	for d in $deps; do
			which "$d"
		if [ $? -ne 0 ]; then
			main="https://raw.githubusercontent.com/mast3rz3ro/ipa-sorter/refs/heads/main/ipa-sorter.sh"
			plget="https://github.com/mast3rz3ro/ipa-sorter/releases/download/utils/plget"
			sudo apt update
			sudo apt install -y unzip p7zip gawk libplist-utils || exit 1
			curl -L "$main" -o "./ipa-sorter.sh" || exit 1
			curl -L "$plget" -o "./plget" || exit 1
			chown mobile:mobile "./plget"
			chmod 755 "./plget"
		fi
	done

		dopamine_root="$(find "/private/preboot/$c" -maxdepth 1 -name "dopamine-*")/procursus/usr/bin"
		palera1n_root="$(find "/private/preboot/$c" -maxdepth 1 -name "jb-*")/procursus/usr/bin"
	if [ -s "./plget" ]; then
		[ -d "$dopamine_root" ] && cp "./plget" "$dopamine_root/plget"
		[ -d "$palera1n_root" ] && cp "./plget" "$palera1n_root/plget"
	fi
	if [ -d "$dopamine_root" ]; then
		echo "- copying: $f into: $dopamine_root/$x"
		cp "$f" "$dopamine_root/$x"
	fi
	if [ -d "$palera1n_root" ]; then
		echo "- copying: $f into: $palera1n_root/$x"
		cp "$f" "$palera1n_root/$x"
	fi
		echo "- installtion completed !"
		exit 0
