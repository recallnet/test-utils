#!/bin/bash

dir=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
source "$dir/config.sh"

gen_wallet() {
  local out addr key
  out=$(recall account create)
  addr=$(echo "$out" | jq .address | tr -d '"')
  key=$(echo "$out" | jq .private_key | tr -d '"')
  echo "$addr" "$key"
}

gen_wallets() {
  local dir="$1"
  local num="$2"
  echo "address,private_key" > "$dir/$WALLET_FILENAME"
  for _ in $(seq 1 "$num"); do
    read -r -a wallet <<< "$(gen_wallet)"
    addr=${wallet[0]}
    pk=${wallet[1]}
    echo "$addr,$pk" >> "$dir/$WALLET_FILENAME"
  done
}

get_wallets() {
  local dir="$1"
  local -n wallets_array="$2"
  if [[ ! -e "$dir/$WALLET_FILENAME" ]]; then
    echo "Generate users first with 'gen-users' command"
    exit 1
  fi
  wallets_array=()
  while IFS=',' read -r addr pk; do
    [[ "$addr" == "address" || -z "$addr" ]] && continue
    wallets_array+=("$addr:$pk")
  done < "$dir/$WALLET_FILENAME"
}

require_admin_key() {
  local network="$1"
  case "$network" in
    devnet)
      export RECALL_PRIVATE_KEY=$DEVNET_ADMIN_PRIVATE_KEY
      ;;
    localnet)
      export RECALL_PRIVATE_KEY=$LOCALNET_ADMIN_PRIVATE_KEY
      ;;
    testnet)
      if [[ -z "${RECALL_PRIVATE_KEY:-}" ]]; then
        echo "Error: RECALL_PRIVATE_KEY environment variable is required for testnet."
        exit 1
      fi
      ;;
    *)
      echo "Error: Invalid network: $network"
      exit 1
      ;;
  esac
}

get_objects_url() {
  local network="$1"
  case "$network" in
    devnet)
      pick_random "${DEVNET_OBJECTS_URLS[@]}"
      ;;
    localnet)
      pick_random "${LOCALNET_OBJECTS_URLS[@]}"
      ;;
    testnet)
      pick_random "${TESTNET_OBJECTS_URLS[@]}"
      ;;
    *)
      echo "Error: Invalid network: $RECALL_NETWORK"
      exit 1
      ;;
  esac
}

get_rpc_url() {
  local network="$1"
  case "$network" in
    devnet)
      pick_random "${DEVNET_RPC_URLS[@]}"
      ;;
    localnet)
      pick_random "${LOCALNET_RPC_URLS[@]}"
      ;;
    testnet)
      pick_random "${TESTNET_RPC_URLS[@]}"
      ;;
    *)
      echo "Error: Invalid network: $RECALL_NETWORK"
      exit 1
      ;;
  esac
}

generate_random_string() {
  local length=$1
  tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

generate_random_file() {
  local filepath=$1
  local filesize=$((RANDOM % 64 + 8))
  head -c "$filesize" < /dev/urandom > "$filepath"
}

pick_random() {
  local array=("$@")
  local array_length=${#array[@]}
  local random_index=$((RANDOM % array_length))
  echo "${array[$random_index]}"
}

print_color() {
  local color_code=$1
  shift
  echo -e "\e[${color_code}m$*\e[0m"
}
