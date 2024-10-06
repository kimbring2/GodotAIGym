#!/bin/sh
echo -ne '\033c\033]0;Pong Multiplayer\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/pong_multi.x86_64" "$@"
