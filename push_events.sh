#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 <hub> <count> <mode>"
    exit 1
fi

hub=$1
count=$2
mode=$3

dir=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
source "$dir/config.sh"
source "$dir/utils.sh"

for _ in $(seq 1 "$count"); do
  cid="bafkreihg32qccdh3zirvjdcopgtkd6vclfesz4b4m2uerz7xhnm3lju4wy"

  rpc_url=$(get_rpc_url "$RECALL_NETWORK")

  cmd="recall -q --rpc-url $rpc_url th push -b $mode -a $hub"
  res=$(echo "$cid" | $cmd 2>&1)
  echo "$res"

  if [[ "${res,,}" == *"error"* ]]; then
    break
  fi
done
