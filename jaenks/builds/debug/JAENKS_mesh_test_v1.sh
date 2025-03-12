#!/bin/sh
echo -ne '\033c\033]0;JAENKS\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/JAENKS_mesh_test_v1.x86_64" "$@"
