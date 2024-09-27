#!/bin/sh
echo -ne '\033c\033]0;Dodge the Creeps\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/DodgeCreep.x86_64" "$@"
