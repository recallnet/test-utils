#!/bin/bash

set -euo pipefail

dir=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
source "$dir/utils.sh"

# Generate user wallets
gen_users_command() {
  local num="${1:-}"
  if [[ -z "$num" ]]; then
    echo "Usage: $0 gen-users <num>"
    return 1
  fi

  gen_wallets "$dir" "$num"

  echo "Generated $num user wallets"
}

# Approve all users to spend admin credits
approve_users_command() {
  local network="${1:-}"
  if [[ -z "$network" ]]; then
    echo "Usage: $0 approve-users <devnet|localnet|testnet>"
    return 1
  fi

  require_admin_key "$network"
  export RECALL_NETWORK=$network
  admin=$(recall account info | jq .address | tr -d '"')

  declare -a users
  get_wallets "$dir" users

  for user in "${users[@]}"; do
    IFS=':' read -r addr pk <<< "$user"
    recall account transfer --to "$addr" 1
    recall account credit approve --to "$addr"
    RECALL_PRIVATE_KEY="$pk" recall account sponsor set "$admin"
  done

  echo "Approved users on $network"
}

# Buy credit for admin
buy_credit_command() {
  local network="${1:-}"
  local amount="${2:-}"
  if [[ -z "$network" || -z "$amount" ]]; then
    echo "Usage: $0 buy-credit <devnet|localnet|testnet> <amount>"
    return 1
  fi

  require_admin_key "$network"
  export RECALL_NETWORK=$network

  recall account credit buy "$amount"

  echo "Bought credit on $network"
}

# Add objects from all users
add_user_objects_command() {
  local network="${1:-}"
  local count="${2:-}"
  local mode="${3:-}"
  local bucket="${4:-}"
  if [[ -z "$network" || -z "$count" || -z "$mode" ]]; then
    echo "Usage: $0 add-user-objects <devnet|localnet|testnet> <per-user-count> <mode> [bucket]"
    return 1
  fi

  require_admin_key "$network"
  export RECALL_NETWORK=$network

  declare -a users
  get_wallets "$dir" users

  if [[ -z "$bucket" ]]; then
    bucket=$(recall bu create | jq .address | tr -d '"')
    echo "Using new bucket $bucket"
  fi

  for user in "${users[@]}"; do
    IFS=':' read -r addr pk <<< "$user"
    RECALL_PRIVATE_KEY="$pk" "$dir/add_objects.sh" "$addr" "$bucket" "$count" "$mode" &
  done
  wait

  echo "Added objects on $network (users: ${#users[@]}, objects/user: $count)"
}

# Push events from all users
push_user_events_command() {
  local network="${1:-}"
  local count="${2:-}"
  local mode="${3:-}"
  local hub="${4:-}"
  if [[ -z "$network" || -z "$count" || -z "$mode" ]]; then
    echo "Usage: $0 push-user-events <devnet|localnet|testnet> <per-user-count> <mode> [hub]"
    return 1
  fi

  require_admin_key "$network"
  export RECALL_NETWORK=$network

  declare -a users
  get_wallets "$dir" users

  if [[ -z "$hub" ]]; then
    hub=$(recall th create | jq .address | tr -d '"')
    echo "Using new hub $hub"
  fi

  for user in "${users[@]}"; do
    IFS=':' read -r _ pk <<< "$user"
    RECALL_PRIVATE_KEY="$pk" "$dir/push_events.sh" "$hub" "$count" "$mode" &
  done
  wait

  echo "Pushed events on $network (users: ${#users[@]}, events/user: $count)"
}

# Watch blocks
watch_blocks_command() {
  local network="${1:-}"
  if [[ -z "$network" ]]; then
    echo "Usage: $0 log-blocks <devnet|localnet|testnet>"
    return 1
  fi

  rpc_url=$(get_rpc_url "$network")

  status=$(curl -s "$rpc_url/status")
  height=$(echo "$status" | jq -r '.result.sync_info.latest_block_height')
  while true; do
    while true; do
      block=$(curl -s "$rpc_url/block?height=$height")
      if echo "$block" | jq -e '.error' >/dev/null; then
        sleep 0.5
      else
        break
      fi
    done
    hash=$(echo "$block" | jq -r '.result.block_id.hash')

    mempool_info=$(curl -s "$rpc_url/num_unconfirmed_txs")
    mempool_size=$(echo "$mempool_info" | jq -r '.result.n_txs')
    mempool_bytes=$(echo "$mempool_info" | jq -r '.result.total_bytes')

    txs=()
    block_gas_wanted=0
    block_gas_used=0
    tx_count=$(echo "$block" | jq -r '.result.block.data.txs | length')
    if [[ "$tx_count" -ne 0 ]]; then
      # Transactions in big blocks can take some extra time to show up over the API
      block_txs=""
      while true; do
        block_txs=$(curl -s "$rpc_url/block_results?height=$height" | jq -c '.result.txs_results[]?')
        if [[ "$block_txs" != "" ]]; then
          break
        fi
        sleep 0.5
      done
      index=1
      while read -r tx; do
        gas_wanted=$(echo "$tx" | jq -r '.gas_wanted')
        gas_used=$(echo "$tx" | jq -r '.gas_used')
        from=$(echo "$tx" | jq -r '.events[] | select(.type == "message") | .attributes[] | select(.key == "from") | .value // empty')
        to=$(echo "$tx" | jq -r '.events[] | select(.type == "message") | .attributes[] | select(.key == "to") | .value // empty')

        txs+=("  $index: gas_wanted=$gas_wanted gas_used=$gas_used from=$from to=$to")

        block_gas_wanted=$((block_gas_wanted + gas_wanted))
        block_gas_used=$((block_gas_used + gas_used))

        index=$((index + 1))
      done < <(echo "$block_txs")
    fi

    print_color "32" "$height: txs=$tx_count gas_wanted=$block_gas_wanted gas_used=$block_gas_used mempool_txs=$mempool_size mempool_bytes=$mempool_bytes hash=${hash,,}"
    for tx in "${txs[@]}"; do
      print_color "36" "$tx"
    done

    height=$((height + 1))
  done
}

# CLI
subcommand="${1:-}"
case "$subcommand" in
  gen-users)
    shift
    gen_users_command "$@"
    ;;
  approve-users)
    shift
    approve_users_command "$@"
    ;;
  buy-credit)
    shift
    buy_credit_command "$@"
    ;;
  add-user-objects)
    shift
    add_user_objects_command "$@"
    ;;
  push-user-events)
    shift
    push_user_events_command "$@"
    ;;
  watch-blocks)
    shift
    watch_blocks_command "$@"
    ;;
  *)
    echo "Usage: $0 {gen-users|approve-users|buy-credit|add-user-objects|push-user-events|watch-blocks} [args...]"
    exit 1
    ;;
esac
