#!/bin/bash



_usage()
{

		local msg
	msg="\
usage: ipa-sorter someapp.ipa
 exportable variables:
  export rename_apps=yes (allows ipa renaming)
  export verbose=yes (enables verbose mode)
  export output_dir=~/somedir (chose where to move apps after rename)"
	echo -ne "$msg\n"

}


_config()
{
				_getstat()
							{
									local c1 c2 c3 c4 c5 c6 c7
									c1=${stat[1]}; c2=${stat[2]}; c3=${stat[3]}
									c4=${stat[4]}; c5=${stat[5]}
									c6=${stat[6]}; c7=${stat[7]}
								if [ $c1 -eq 0 ]; then
									return 1
								fi
									_echo "tasks stats:" 1
									_echo "total proccedd files: $c1" 2
									_echo "total ignored files: $c2" 4
									_echo "total encrypted apps: $c3" 2
									_echo "total unencrypted apps: $c4" 2
									_echo "total rename errors: $c5" 2
									_echo "total mach-o errors: $c6" 4
									_echo "total manifest errors: $c7" 4
							}
		if [ -z "$1" ]; then
			_usage
			return 0
		fi

	
		local c x f
		stat=(0 0 0 0 0 0 0 0)
		_echo "starting ipa-sorter..." 4
	while read f; do
			_echo "idenifying file: $f" 0
		if [ -s "$f" ]; then
				c="$(file "$f")"
			if [[ "$c" = *"Zip archive"* ]]; then
				mode="zip"; stat[1]=$((stat[1]+1))
			elif [[ "$c" = *"Mach-O"* ]]; then
				mode="mach"; stat[1]=$((stat[1]+1))
			elif [[ "$f" = *"Info.plist"* ]]; then
				mode="dir"; stat[1]=$((stat[1]+1))
			else
				_echo "error invalid file: $f returned: $c" 2
				stat[2]=$((stat[2]+1)); continue
			fi
				_getmacho "$f"
				_getinfo "$f"
		else
			_echo "error cannot read file: $f" 2
			stat[2]=$((stat[2]+1)); continue
		fi
	done< <(find "$@" -type f -wholename '*.app/Info.plist' -or -name '*.ipa' -or -name '*.macho')
			_getstat #$stat

}


_getmacho()
{
				_getarch()
							{
								# CA FE BA BE --> universal
								# CF FA ED FE --> arm64
								# CE FA ED FE --> arm32

									_echo "idenifying mach-o arch..." 4
								if [ "$1" = "cafebabe" ]; then
									arch="universal"
								elif [ "$1" = "cffaedfe" ]; then
									arch="arm64"
								elif [ "$1" = "cefaedfe" ]; then
									arch="arm32"
								else
									_echo "error unknown mach-o header: $1" 2
									stat[6]=$((stat[6]+1))
									return 1
								fi
								if [ "$universal" != "yes" ] || [ "$verbose" = "yes" ]; then
									_echo "detected arch: $arch" 2
								fi
							}
		_getcryptid()
							{
								# 2C 00 00 00 18 00 00 00 00 ?? ?? ?? ?? ?? ?? ?? xx -> arm64
								# 21 00 00 00 14 00 00 00 00 ?? ?? 00 00 ?? ?? ?? xx -> arm32

									local h m c
									_echo "idenifying mach-o cryptid..." 4
								if [ "$arch" = "arm64" ]; then
									h="2c0000001800000000................"
									m="LC_ENCRYPTION_INFO_64"
								elif [ "$arch" = "arm32" ]; then
									h="210000001400000000....0000........"
									m="LC_ENCRYPTION_INFO"
								fi

									h="$(echo "$1" | grep -om1 "$h")"
									[ -n "$h" ] && c="${h: -1}" || { c="-1"; h="null"; }
								if [ $c -eq 0 ]; then
									state="unencrypted"
									[ "$universal" != "yes" ] && stat[4]=$((stat[4]+1))
								elif [ $c -ge 1 ]; then
									state="encrypted"
									[ "$universal" != "yes" ] && stat[3]=$((stat[3]+1))
								else
									state="unknown"; stat[6]=$((stat[6]+1))
								fi

								if [ "$state" != "unknown" ]; then
										_echo "$m: $h" 4
									if [ "$universal" != "yes" ] || [ "$verbose" = "yes" ]; then
										_echo "cryptid state: $state ($c)" 2
									fi
								else
									_echo "error returned cryptid is: $c" 2
									_echo "state: $state command: $m header: $h data: $1" 3
									stat[6]=$((stat[6]+1))
									return 1
								fi										
							}
				_getsub()
							{
									local m x d c1 c2
									c1="0"; c2="0"
								if [ "$mode" = "zip" ]; then
									_echo "extracting fat mach-o: $2 from: $1 into: ./tmp" 4
									unzip -qp "$1" "$2" >"./tmp"
									m="./tmp"
								else
									m="$1"
								fi
									_echo "parsing fat mach-o header..." 4
								while read x; do
										_echo "parsing sub mach-o header: $x" 4
										d="$(7z -ba -so x "$m" "$x" | od -tx1 -An -N0x2024 | tr -d ' \n')"
										_getarch "${d:0:8}"
										_getcryptid "$d"
									if [ "$state" = "unencrypted" ]; then
										c1=$((c1+1))
									elif [ "$state" = "encrypted" ]; then
										c2=$((c2+1))
									fi
								done< <(7z -ba l "$m" | awk '{print $4}')
								if [ $c1 -gt 0 ] && [ $c2 -gt 0 ]; then
									_echo "error inconsistent fat mach-o: $1 unencrypted: $c1 encrypted: $c2" 2
									stat[6]=$((stat[6]+1))
									return 1
								else
									[ "$state" = "unencrypted" ] && stat[4]=$((stat[4]+1))
									[ "$state" = "encrypted" ] && stat[3]=$((stat[3]+1))
									_echo "cryptid state: $state (universal)" 2
								fi
							}

				local f x m d e
				universal="no"
				_echo "parsing mach-o header..." 4
			if [ "$mode" = "zip" ]; then
				x="$(unzip -l "$1" | grep -om1 'Payload.*\.app' | sed 's/\.app//; s/Payload\///')"
				m="Payload/$x.app/$x"
				d="$(unzip -qp "$1" "$m" | od -tx1 -An -N0x2024 | tr -d ' \n')"
				f="$1"
				payload="Payload/$x.app"
			elif [ "$mode" = "mach" ]; then
				m="$1"
				f="$1"
				payload="$(dirname "$1")"
				_cfile "$f" && d="$(od -tx1 -An -N0x2024 "$1" | tr -d ' \n')" || { stat[6]=$((stat[6]+1)); state="unknown"; return 1; }
			elif [ "$mode" = "dir" ]; then
				e="$(dirname "$1")"
				x="$(basename "$e" | sed 's/\.app//')"
				m="$e/$x"
				f="$m"
				payload="$e"
				_cfile "$f" && d="$(od -tx1 -An -N0x2024 "$f" | tr -d ' \n')" || { stat[6]=$((stat[6]+1)); state="unknown"; return 1; }
			fi
			if [ -n "$d" ]; then
					_getarch "${d:0:8}"
			else
				_echo "error invalid mach-o header: $m" 2
				stat[6]=$((stat[6]+1))
				return 1
			fi

			if [ "$arch" = "arm64" ] || [ "$arch" = "arm32" ]; then
				_getcryptid "$d"
			elif [ "$arch" = "universal" ]; then
				universal="yes"
				_getsub "$f" "$m"
			fi
}



_getinfo()
{
						# MacUIRequiredDeviceCapabilities|UIRequiredDeviceCapabilities --> arch
						# apple-id|userName --> linked-account
						# artistName --> publisher
						# bundleDisplayName --> app-name
						# bundleShortVersionString --> app-version
						# softwareVersionBundleId --> bundle-id

						# CFBundleName|CFBundleExecutable|CFBundleDisplayName --> app-name
						# CFBundleShortVersionString --> app-version
			_getdict()
					{
							local d
						for x in $1; do
								d="$(echo "$2" | plget - "$x")"
							if [ -z "$d" ]; then
								_echo "error could not find dict: $x" 4
								continue
							else
								break
							fi
						done

						if [ -n "$d" ]; then
							result="$d"
							return 0
						else
							_echo "error could not parse some identifiers: $1" 2
							result="unknown"; stat[7]=$((stat[7]+1))
							return 1
						fi
					}
		_getconv()
					{
							local d
							_echo "convertting manifest: $2" 4
						if [ "$mode" = "zip" ]; then	
							d="$(unzip -qp "$1" "$2" | plistutil -f xml -i -)"
						elif [ "$mode" = "mach" ]; then
							_cfile "$2" && d="$(plistutil -f xml -i "$2")"
						elif [ "$mode" = "dir" ]; then
							_cfile "$2" && d="$(plistutil -f xml -i "$2")"
						fi

						if [ -n "$d" ]; then
							result="$d"
							return 0
						else
							_echo "error convertting manifest failed: $2" 2
							stat[7]=$((stat[7]+1))
							return 1
						fi
					}


					local x
					_echo "proccessing app manifest..." 2
				if [ "$state" = "encrypted" ]; then
					x="$(dirname "$payload" | sed 's/Payload//')"
					x="${y}iTunesMetadata.plist"
					_getconv "$1" "$x" && info_t="$result" || return 1
					x="$payload/Info.plist"
					_getconv "$1" "$x" && info_n="$result" || return 1
				elif [ "$state" = "unencrypted" ]; then
					x="$payload/Info.plist"
					_getconv "$1" "$x" && info_n="$result" || return 1
				else
					_echo "aborting since state is: $state" 2
					stat[7]=$((stat[7]+1))
					return 1
				fi

					_echo "parsing app manifest..." 4
				if [ "$state" = "encrypted" ]; then
					s="encrypted-apps"
					d="appleId userName com.apple.iTunesStore.downloadInfo/accountInfo/AppleID"
					_getdict "$d" "$info_t" && ids[0]="$result" || e=$((e+1))
					_echo "found purchase account: ${ids[0]}" 2
				elif [ "$state" = "unencrypted" ]; then
					s="unencrypted-apps"
					ids[0]=""
				fi
					d="CFBundleDisplayName CFBundleName CFBundleExecutable"
					_getdict "$d" "$info_n" && ids[1]="$result" || return 1
					d="CFBundleIdentifier"
					_getdict "$d" "$info_n" && ids[2]="$result" || return 1
					d="CFBundleShortVersionString"
					_getdict "$d" "$info_n" && ids[3]="$result" || return 1
					d="CFBundleVersion"
					_getdict "$d" "$info_n" && ids[4]="$result" || return 1
					newids="${ids[1]} v${ids[3]}(${ids[4]})"
					_echo "found idenitifiers: $newids" 2

				if [ "$rename_apps" = "yes" ]; then
					if [ "$mode" = "dir" ]; then
						_echo "ignoring moving: $1" 1
						return 0
					else
						if [ -n "$output_dir" ]; then
							mkdir -p "${output_dir}/${s}/${ids[0]}"
							o="${output_dir}/${s}/${ids[0]}/${newids}"
						else
							o="$(dirname "$1")"
							s="${s/-apps/}"
							o="${o}/${newids}_${s}"
						fi
							_mv "$1" "$o"
					fi
				fi		

}


_mv()
{
	local i x; i="0"
	while true; do
			[ $i -ne 0 ] && x="${2}_${i}.ipa" || x="${2}.ipa"
		if [ ! -s "$x" ]; then
			_echo "moving: $1 into: $x" 2
			mv "$1" "$x"
			[ $? -eq 0 ] && return 0 || { stat[5]=$((stat[5]+1)); return 1; }
		elif [ -s "$x" ]; then
			_echo "skipping overriting into: $x" 4
			i=$((i+1)); stat[5]=$((stat[5]+1))
			continue
		else
			_echo "unexpected error on function: _mv"
			stat[5]=$((stat[5]+1))
			return 1
		fi
	done
}

_cfile()
{
	if [ -s "$1" ]; then
		return 0
	else
		_echo "error can not read file: $1" 2
		return 1
	fi
}


_echo()
{
	if [ "$2" = "0" ]; then
		echo "- $1"
	elif [ "$2" = "1" ]; then
		echo "  - $1"
	elif [ "$2" = "2" ]; then
		echo "     $1"
	elif [ "$2" = "3" ]; then
		[ "$verbose" = "yes" ] && echo "  - [verbose]: $1"
	elif [ "$2" = "4" ]; then
		[ "$verbose" = "yes" ] && echo "     [verbose]: $1"
	else
		echo "warnning unknown parameters used in _echo msg: $1 id: $2"
	fi
}

_config "$@"

