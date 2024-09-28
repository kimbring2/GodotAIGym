#!/bin/sh
echo -ne '\033c\033]0;Basic3DPlatformer\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Basic3DPlatformer.x86_64" "$@"
