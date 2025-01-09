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

seq=$(hoku account info | jq .sequence)

for _ in $(seq 1 "$count"); do
  cid="bafkreihg32qccdh3zirvjdcopgtkd6vclfesz4b4m2uerz7xhnm3lju4wy"

  rpc_url=$(get_rpc_url "$HOKU_NETWORK")

  cmd="hoku -q --rpc-url $rpc_url th push --gas-limit 30000000 -b $mode --sequence $seq -a $hub"
  res=$(echo "$cid" | $cmd 2>&1)
  echo "$res"

  if [[ "${res,,}" == *"error"* ]]; then
    break
  fi

  seq=$((seq + 1))
done
