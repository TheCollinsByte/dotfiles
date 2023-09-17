#!/bin/bash

# Change directory and view the contents at the same time
function cl() {
	DIR="$*";
		# if no DIR given, go home
		if [ $# -lt 1 ]; then 
			DIR=$HOME;
		fi;
		builtin cd "${DIR}" && \
		# preferred ls command
		ls -F --color=auto
}
