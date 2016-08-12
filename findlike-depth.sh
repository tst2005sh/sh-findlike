#!/bin/sh

set -e

# a modified version of findlike (focus on most deep first & directory before files)

# findlike [<options>] [--] [<directory> [<directories ...>]]
findlike() {
	local status=0
	local mindepth=''
	local maxdepth=''
	while [ $# -gt 0 ]; do
		case "$1" in
			(-mindepth)	shift; mindepth="$1";;
			(-maxdepth)	shift; maxdepth="$1";;
			(--)		shift; break;;
			-*) echo >&2 "ERROR: invalid option $1"; return 1;;
			*) break;;
		esac
		shift
	done
	local filter=foobar_filter
	local hand=foobar
	if [ $# -eq 0 ]; then
		_findlike "$filter" "$hand" . || status=1
		return $status
	fi
	for item in "$@"; do
		if [ -d "$item" ]; then
			_findlike "$filter" "$hand" "$item" || status=1
		fi
	done
	for item in "$@"; do
		if [ ! -d "$item" ]; then
			_findlike "$filter" "$hand" "$item" || status=1
		fi
	done
	return $status
}

# _findlike() <pre-callback> <post-callback> <directory|file>
_findlike() {
	local filter="$1";shift
	local hand="$1";shift
	local level=${level:-0} # usefull in case of MINDEPTH=0
	local item="$1"
	local status=0

	local type1=''
	if [ -h "$item" ]; then
		type1='l'
	elif [ ! -e "$item" ]; then
		if [ -e "${item%/\*}" ] && [ -d "${item%/\*}" ]; then # WORKAROUND in case of  `for item in 'dir/'*; do echo "item=$item"; done`  we got a item='dir/*' line.
			return 0
		fi
		# here it seems an asked non-existant directory, show it!
		type1='!'
	elif [ -d "$item" ]; then
		if ( [ -z "${maxdepth:-}" ] || [ ${level:-0} -le ${maxdepth} ] ) && "$filter" 'd' "$item"; then
			if [ -r "$item/" ]; then
				level=$(( ${level:-0} + 1))
				for childitem in "$item"/* "$item"/.*; do
					[ -d "$childitem" ] || continue
					case "$childitem" in
						 */.|*/..) continue ;;
					esac
					_findlike "$filter" "$hand" "$childitem" || status=1
				done
				for childitem in "$item"/* "$item"/.*; do
					[ ! -d "$childitem" ] || continue
					case "$childitem" in
						*/.|*/..) continue ;;
					esac
					_findlike "$filter" "$hand" "$childitem" || status=1
				done
				level=$(( ${level:-0} - 1))
			fi
			if [ ${level:-0} -ge ${mindepth:-0} ]; then
				"$hand" "$type1"'d' "$item" || status=1
			fi
		fi
		return $status
	fi
	local type='U'
	if [ ! -e "$item" ]; then type='!';
	elif [ -f "$item" ]; then type='f';
	elif [ -d "$item" ]; then type='d';
	elif [ -S "$item" ]; then type='s';
	elif [ -p "$item" ]; then type='p';
	elif [ -b "$item" ]; then type='b';
	elif [ -c "$item" ]; then type='c';
	fi
	if [ ${level:-0} -ge ${mindepth:-0} ] && \
	( [ -z "${maxdepth:-}" ] || [ ${level:-0} -le ${maxdepth} ] ) && \
	"$filter" "$type1$type" "$item"; then
		"$hand" "$type1$type" "$item" || status=1
	fi
	return $status
}

showall() {
	echo "$1 $2 (${level:-0})"
	if [ "$1" = "d" ] && [ ! -r "$2" ]; then return 1; fi
	return 0
}

showdeadlink() {
	if [ "$1" = "l!" ]; then
		echo "$2"
	fi
}
showfile() {
	case "$1" in
		f|lf)
			echo "${level:-0} $2" ;;
	esac
}
showdir() {
	case "$1" in
		d|ld)
			echo "${level} $2" ;;
	esac
}

foobar_filter() {
	# skip the .git directory
	case "$2" in
		(*'/.git'|'.git/'*|'.git'|*'/.git/'*) return 1 ;;
	esac

	case "$1" in
		(f) ;; # want to get time
		(d) ;; # want to explore
		('!'*) return 1 ;; # show invalid stuff
		(?)  return 1 ;; # ignore special or unknown item
		(l*) return 2 ;;
		(*) return 1 ;; # we don't use missing case!
	esac
	return 0
}

getTimestampFromFS() { #FIXME: timestamp will be got from git info, not from real FS.
	stat -c %Y -- "$1"
}

foobar() {
	case "$1" in
		(d)
			# when a dir match, all his content has been done
			if [ -n "${recenttimestamp}" ]; then
				echo "can apply recenttimestamp=$recenttimestamp to $2 (from $datefrom)"
				recenttimestamp='' # reset it
				datefrom=''
			else
				echo "no such date for $2 (maybe empty dir ?)"
			fi
		;;
		(f)	# want to get time
			local candidate="$(getTimestampFromFS "$2")"
			if [ $candidate -gt ${recenttimestamp:-0} ]; then
				echo "new most recent timestamp: $2 $(date -d @$candidate +'%Y-%m-%d %H:%M:%S')"
				recenttimestamp="$candidate"
				datefrom="$2"
			fi
		;;
	esac
	printf '%s (%s) %2s %s\n' "+" "${level:-0}" "$1" "$2"

	#if [ "$1" = "d" ] && [ ! -r "$2" ]; then return 1; fi # unreadable directory
	return 0
}

findlike "$@"
