#!/usr/bin/env bash

input=$(cat | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g')

unset CDPATH; cd "$( dirname "${BASH_SOURCE[0]}" )"; cd "$(pwd -P)"

./discord.sh --text "\`\`\`\n$input\n\`\`\`"

