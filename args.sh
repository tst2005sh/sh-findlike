#!/bin/sh

lastarg() {
	eval 'local a="$'"$#"'"'
	echo "$a"
}

argn() {
	local lst="$1";shift
	for n in $lst; do
		if [ $n -lt 0 ]; then
			echo "$(( $# + $n +1 ))"
		else
			echo "$n"
		fi
	done
}
#argn "-1 -2 -3" a1 a2 a3 a4 a5
#argn "1 3" a1 a2 a3 a4 a5


argrange() {
	local y="$1";shift
	local z="$1";shift
	for n in $(seq $y $z); do
		:
	done
}
