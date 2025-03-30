# Test Utils

[![License](https://img.shields.io/github/license/recallnet/test-utils.svg)](./LICENSE)
[![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg)](https://github.com/RichardLitt/standard-readme)

> Bash-based test utils for Recall

## Table of Contents

- [Background](#background)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Background

Simple bash scripts for monitoring gas usage and throughput in Recall.

## Usage

Most commmands take a `network` argument. This can be `devnet`, `localnet`, or `testnet`.

With `testnet`, you'll need to provide a `RECALL_PRIVATE_KEY` environment variable,
which is used for the "admin" wallet.
`devnet` and `localnet` will use a default (hard-coded) private key for the "admin" wallet.

When using `localnet` or `testnet`, every transaction is submitted to a random Recall node to increase network throughput.
When adding objects to a bucket, objects are staged to a random Object API.

### Buy some credit for the "admin"

```sh
./main.sh buy-credit localnet <tokens to spend>
```

### Create some user wallets

The commands will use multiple user wallets to add bucket objects or push timehub events.
Using a higher number of users makes it easier to fill up the mempool.
This is especially true when adding objects.
Every add operation must wait for a response from the Object API before its transaction can be submitted.

```sh
./main.sh gen-users <num users>
```

User wallets are stored in a `wallet.csv` file.

### Approve users to spend default admin credits

Instead of buying credits for all users in the `wallet.csv` file, we just approve them
to use the admin's credits.

```sh
./main.sh approve-users localnet
```

### Add some objects to a bucket

```sh
./main.sh add-user-objects localnet <objects per user> <broadcast mode>
```

This will add objects from every user in the `wallet.csv` file to a new bucket owned by the "admin" wallet.

You can also use an existing bucket:
```sh
./main.sh add-user-objects localnet <objects per user> <broadcast mode> <bucket address>
```

### Push some events to a timehub

```sh
./main.sh push-user-events localnet <events per user> <broadcast mode>
```

This will push events from every user in the `wallet.csv` file to a new timehub owned by the "admin" wallet.

You can also use an existing timehub:
```sh
./main.sh push-user-events localnet <events per user> <broadcast mode> <timehub address>
```

### Watch CometBFT blocks

This is invaluable for monitoring transaction throughput when adding objects or pushing events.

```sh
./main.sh watch-blocks localnet
```

`watch-blocks` uses a few different CometBFT APIs to show a running log of blocks and transactions. Here's an example
output for a single block:

```txt
66731: txs=12 gas_wanted=750000000 gas_used=485307993 mempool_txs=4 mempool_bytes=1539 hash=29735859e8aadacbb3a4bb715a4c07a74ddeefa2c1370532ec7d62d90ab0dec5
  1: gas_wanted=50000000 gas_used=28817147 from=t00 to=t066
  2: gas_wanted=50000000 gas_used=31343964 from=t00 to=t066
  3: gas_wanted=50000000 gas_used=30403766 from=t00 to=t066
  4: gas_wanted=50000000 gas_used=27315212 from=t00 to=t066
  5: gas_wanted=50000000 gas_used=28209877 from=t00 to=t066
  6: gas_wanted=50000000 gas_used=32657192 from=t00 to=t066
  7: gas_wanted=50000000 gas_used=27518397 from=t00 to=t066
  8: gas_wanted=50000000 gas_used=31602075 from=t00 to=t066
  9: gas_wanted=50000000 gas_used=33903079 from=t00 to=t066
  10: gas_wanted=100000000 gas_used=69632145 from=t410flu5uemgctqyopwkkuzwiy4xredf5qxrogfz5e3i to=t0166
  11: gas_wanted=100000000 gas_used=71572072 from=t410f6fspsvkcnlxwg2iwntbft5s6hexccwcbstx65qy to=t0166
  12: gas_wanted=100000000 gas_used=72333067 from=t410f6fspsvkcnlxwg2iwntbft5s6hexccwcbstx65qy to=t0166
```

We can see some useful information from the output:
- The number of transactions in the block
- The total amount of gas _wanted_ by the block (the sum of transaction `gas_limit` amounts)
- The total amount of gas _used_ by the block (the sum of transaction `gas_used` amounts)
- The current mempool transaction count
- The current mempool byte size
- From, to, gas wanted, and gas used values for each transaction

### Watch Eth blocks

This is useful for EVM event debugging.

```sh
node watch-eth-blocks.js
```

### Watch Fenderming logs with filters

This is useful for Fendermint debugging.

```sh
./watch_logs.sh 0 "blob pool counts" "blob fetched counts" "end block" "warn" "error"
```

## Contributing

PRs accepted.

Small note: If editing the README, please conform to
the [standard-readme](https://github.com/RichardLitt/standard-readme) specification.

## License

MIT OR Apache-2.0, © 2024 Recall Contributors
