#!/bin/bash

WALLET_FILENAME=wallets.csv

DEVNET_ADMIN_PRIVATE_KEY=1c323d494d1d069fe4c891350a1ec691c4216c17418a0cb3c7533b143bd2b812
LOCALNET_ADMIN_PRIVATE_KEY=2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

DEVNET_RPC_URLS=("http://localhost:26657")
LOCALNET_RPC_URLS=("http://localhost:26657" "http://localhost:26757" "http://localhost:26857")
TESTNET_RPC_URLS=("https://api-ignition-0.recall.network" "https://api-ignition-1.recall.network")

DEVNET_OBJECTS_URLS=("http://localhost:8001")
LOCALNET_OBJECTS_URLS=("http://localhost:8001" "http://localhost:8002" "http://localhost:8003")
TESTNET_OBJECTS_URLS=("https://object-api-ignition-0.recall.network" "https://object-api-ignition-1.recall.network")
