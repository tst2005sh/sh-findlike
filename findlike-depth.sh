#!/bin/sh

set -e

# a modified version of findlike (focus on most deep first & directory before files)

# findlike [<directory> [<directories ...>]]
findlike() {
	local status=0
	local mindepth
	local maxdepth
	while [ $# -gt 0 ]; do
		case "$1" in
			(-mindepth)	shift; mindepth="$1";;
			(-maxdepth)	shift; maxdepth="$1";;
			(--)		shift; break;;
			-*) echo >&2 "ERROR: invalid option $1"; return 1;;
			*) break
		esac
		shift
	done
	local filter=foobar_filter
	local hand=foobar
	if [ $# -eq 0 ]; then
		MINDEPTH="$mindepth" MAXDEPTH="$maxdepth" \
		_findlike "$filter" "$hand" . || status=1
		return $status
	fi
	for item in "$@"; do
		if [ -d "$item" ]; then
			MINDEPTH="$mindepth" MAXDEPTH="$maxdepth" \
			_findlike "$filter" "$hand" "$item" || status=1
		fi
	done
	for item in "$@"; do
		if [ ! -d "$item" ]; then
			MINDEPTH="$mindepth" MAXDEPTH="$maxdepth" \
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
		if "$filter" 'd' "$item"; then
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
	"$filter" "$type1$type" "$item" && \
	[ ${level:-0} -ge ${mindepth:-0} ] && \
	"$hand" "$type1$type" "$item" || status=1
	return $status
}

mindepth() {
	if [ ${level:-0} -lt ${MINDEPTH:-0} ]; then
		return 1
	fi
	return 0
}

maxdepth() {
	if [ -n "${MAXDEPTH:-}" ] && [ ${level:-0} -gt ${MAXDEPTH} ]; then
		return 1
	fi
	return 0
}

showall() {
	#maxdepth || return 1
	#mindepth || return 1
	echo "$1 $2 (${level:-0})"
	if [ "$1" = "d" ] && [ ! -r "$2" ]; then return 1; fi
	return 0
}

showdeadlink() {
	#maxdepth || return 1
	if [ "$1" = "l!" ]; then
		mindepth || echo "$2"
	fi
}
showfile() {
	#maxdepth || return 1
	case "$1" in
		f|lf)
			mindepth 1 || echo "${level:-0} $2" ;;
	esac
}
showdir() {
	#maxdepth || return 1
	case "$1" in
		d|ld)
			mindepth 1 || echo "${level} $2" ;;
	esac
}

foobar_filter() {
	maxdepth || return 1
	#mindepth || return 1

	#maxdepth || return 1
	#mindepth && return 0

	# skip the .git directory
	case "$2" in
		(*'/.git'|'.git/'*|'.git'|*'/.git/'*) return 1 ;;
	esac
	return 0
}

foobar() {
	#maxdepth || return 1
	#mindepth || return 1

	local explore=true
	case "$1" in
		f) ;; # want to get time
		d) ;; # want to explore
		'!'*) ;; # show invalid stuff
		?) explore=false ;; # ignore special or unknown item
		l*) explore=false ;; # we don't follow symlink FIXME: we should try to get the symlink timestamp (if the stat callow to not follow the target)
		#'!!') return 1 ;;
		*) explore=false ;; # we don't use missing case!
	esac
#	if ! $explore; then
#		printf '%s (%s) %2s %s\n' "#" "${level:-0}" "$1" "$2"
#		return 2
#	fi
	printf '%s (%s) %2s %s\n' "+" "${level:-0}" "$1" "$2"

	#if [ "$1" = "d" ] && [ ! -r "$2" ]; then return 1; fi # unreadable directory
	return 0
}

findlike "$@"
