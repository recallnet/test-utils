#!/bin/bash

if [ $# -ne 4 ]; then
    echo "Usage: $0 <user> <bucket> <count> <mode>"
    exit 1
fi

user=$1
bucket=$2
count=$3
mode=$4

dir=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
source "$dir/config.sh"
source "$dir/utils.sh"

temp_dir="/tmp/$user"
mkdir -p "$temp_dir"

seq=$(recall account info | jq .sequence)

for i in $(seq 1 "$count"); do
  file_name="$temp_dir/file_$i"
  key=$(generate_random_string 7)
  generate_random_file "$file_name"

  rpc_url=$(get_rpc_url "$RECALL_NETWORK")
  objects_url=$(get_objects_url "$RECALL_NETWORK")

  cmd="recall -q --rpc-url $rpc_url bu add --object-api-url $objects_url --gas-limit 100000000 -b $mode --sequence $seq -a $bucket -k $key"
  cmd="$cmd $file_name"
  res=$($cmd 2>&1)
  echo "$res"

  if [[ "${res,,}" == *"error"* ]]; then
    break
  fi

  seq=$((seq + 1))
done

rm -r "$temp_dir"
