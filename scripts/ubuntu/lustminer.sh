#!/usr/bin/env bash
# === Lust Chain — Docker miner (uses genesis from the official RPC) ===
set -euo pipefail

echo "=== Lust Chain - miner ==="

GENESIS_URL="${GENESIS_URL:-http://138.197.125.190:18580/genesis.json}"

read -rp "Wallet (0x...): " WALLET
if [[ -z "$WALLET" ]]; then
  echo "❌ you must inform the wallet"
  exit 1
fi

read -rp "Threads [2]: " THREADS
THREADS=${THREADS:-2}

BASE="$HOME/lust-miner"
DATADIR="$BASE/data"
GENESIS="$BASE/genesis.json"

mkdir -p "$BASE"

if [ -d "$BASE" ]; then
  sudo chown -R "$USER":"$USER" "$BASE" || true
fi

echo "📁 miner folder: $BASE"

if ! command -v docker >/dev/null 2>&1; then
  echo "➡ installing docker..."
  sudo apt-get update -y
  sudo apt-get install -y docker.io
  sudo systemctl enable --now docker
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "➡ installing curl..."
  sudo apt-get install -y curl
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "➡ installing jq..."
  sudo apt-get install -y jq
fi

echo "➡ stopping old container (if any)..."
sudo docker rm -f lust-miner >/dev/null 2>&1 || true

echo "➡ cleaning old datadir..."
rm -rf "$DATADIR"
mkdir -p "$DATADIR"

echo "➡ downloading genesis from $GENESIS_URL ..."
curl -fsSL "$GENESIS_URL" -o "$GENESIS"

CHAINID=$(jq -r '.config.chainId' "$GENESIS")
if [ "$CHAINID" != "6923" ]; then
  echo "❌ downloaded genesis is NOT Lust Chain (chainId=$CHAINID)"
  exit 1
fi
echo "✅ genesis is Lust Chain (chainId 6923)"

echo "➡ initializing datadir with genesis..."
sudo docker run --rm   -v "$DATADIR":/root/.ethereum   -v "$GENESIS":/genesis.json:ro   ethereum/client-go:v1.10.26   init /genesis.json

BOOTNODES="enode://cf04c868ab597ab088cc0868b955368b36c47d22f162a59c8a732d3c4732dda5dac79bd39e41c6f853556aadfb100bacb709fd9f60dec8abfa3185c10ad782f5@138.197.125.190:30303,enode://fddbd81de98139327094965d2bfcbe5d9baae312a52b72887a1f1ecba497b521273cefd360bce34c0575bb592d5287d9ed5c5be9698cce9b50c2d8acdc2fd55e@104.248.175.223:30303,enode://707c8b3ef4311b55a7a027ddf499fa96ece47f7f7c226104df4f313a39c997d88a496ff61f33dd7597c8347c0c75a7a8caa5966ac45f7c434122c0331b8224c1@170.64.145.190:30303"

echo "➡ starting miner..."
sudo docker run -d --name lust-miner --restart unless-stopped   -v "$DATADIR":/root/.ethereum   ethereum/client-go:v1.10.26   --networkid 6923   --syncmode full   --http --http.addr 0.0.0.0 --http.port 8545 --http.api eth,net,web3,miner   --bootnodes "$BOOTNODES"   --mine   --miner.etherbase "$WALLET"   --miner.threads "$THREADS"   --cache 512

echo "✅ miner is running!"
echo "📜 see logs: sudo docker logs -f lust-miner"
