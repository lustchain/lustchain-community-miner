# Lust Chain Community Miner

This repository provides **simple, copy‑paste‑ready** scripts to run a Lust Chain mining node with **Docker** on:

- **Linux / Ubuntu**
- **Windows + Docker Desktop**

It always fetches the **official genesis** from the public Lust Chain RPC, uses the **official bootnodes** and connects to **network ID 6923** (Lust Chain).

> ⚠️ These scripts mine directly to **your** wallet (the one you type when running). Keep it safe.

---

## 1. Requirements

### Linux / Ubuntu
- Ubuntu 20.04+ (works on 22.04, 24.04, 25.04)
- `docker` installed (the script installs it if missing)
- `curl` and `jq` (the script installs them if missing)
- Internet access to `http://138.197.125.190:18580/genesis.json`

### Windows
- Windows 10/11
- **Docker Desktop** installed and running
- PowerShell

---

## 2. Quick start — Linux / Ubuntu

1. Download / create the script:

   ```bash
   cat > $HOME/lustminer.sh <<'EOF'
   #!/usr/bin/env bash
   # === Lust Chain — Docker miner (uses genesis from the official RPC) ===
   set -euo pipefail

   echo "=== Lust Chain - miner ==="

   # fixed URL of your RPC
   GENESIS_URL="${GENESIS_URL:-http://138.197.125.190:18580/genesis.json}"

   # 1) ask for wallet
   read -rp "Wallet (0x...): " WALLET
   if [[ -z "$WALLET" ]]; then
     echo "❌ you must inform the wallet"
     exit 1
   fi

   # 2) ask for threads
   read -rp "Threads [2]: " THREADS
   THREADS=${THREADS:-2}

   # 3) folders
   BASE="$HOME/lust-miner"
   DATADIR="$BASE/data"
   GENESIS="$BASE/genesis.json"

   mkdir -p "$BASE"

   # if the folder was created as root before, fix owner
   if [ -d "$BASE" ]; then
     sudo chown -R "$USER":"$USER" "$BASE" || true
   fi

   echo "📁 miner folder: $BASE"

   # 4) make sure basic deps exist
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

   # 5) stop old container
   echo "➡ stopping old container (if any)..."
   sudo docker rm -f lust-miner >/dev/null 2>&1 || true

   # 6) clean old datadir (maybe old genesis)
   echo "➡ cleaning old datadir..."
   rm -rf "$DATADIR"
   mkdir -p "$DATADIR"

   # 7) download genesis from RPC
   echo "➡ downloading genesis from $GENESIS_URL ..."
   curl -fsSL "$GENESIS_URL" -o "$GENESIS"

   # 8) check if it is chainId 6923
   CHAINID=$(jq -r '.config.chainId' "$GENESIS")
   if [ "$CHAINID" != "6923" ]; then
     echo "❌ downloaded genesis is NOT Lust Chain (chainId=$CHAINID)"
     exit 1
   fi
   echo "✅ genesis is Lust Chain (chainId 6923)"

   # 9) init geth inside docker
   echo "➡ initializing datadir with genesis..."
   sudo docker run --rm      -v "$DATADIR":/root/.ethereum      -v "$GENESIS":/genesis.json:ro      ethereum/client-go:v1.10.26      init /genesis.json

   # 10) official bootnodes (your 3 nodes)
   BOOTNODES="enode://cf04c868ab597ab088cc0868b955368b36c47d22f162a59c8a732d3c4732dda5dac79bd39e41c6f853556aadfb100bacb709fd9f60dec8abfa3185c10ad782f5@138.197.125.190:30303,enode://fddbd81de98139327094965d2bfcbe5d9baae312a52b72887a1f1ecba497b521273cefd360bce34c0575bb592d5287d9ed5c5be9698cce9b50c2d8acdc2fd55e@104.248.175.223:30303,enode://707c8b3ef4311b55a7a027ddf499fa96ece47f7f7c226104df4f313a39c997d88a496ff61f33dd7597c8347c0c75a7a8caa5966ac45f7c434122c0331b8224c1@170.64.145.190:30303"

   echo "➡ starting miner..."
   sudo docker run -d --name lust-miner --restart unless-stopped      -v "$DATADIR":/root/.ethereum      ethereum/client-go:v1.10.26      --networkid 6923      --syncmode full      --http --http.addr 0.0.0.0 --http.port 8545 --http.api eth,net,web3,miner      --bootnodes "$BOOTNODES"      --mine      --miner.etherbase "$WALLET"      --miner.threads "$THREADS"      --cache 512

   echo "✅ miner is running!"
   echo "📜 see logs: sudo docker logs -f lust-miner"
   echo "🔎 check balance of this wallet:"
   echo "    curl -s -X POST http://127.0.0.1:8545 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$WALLET\",\"latest\"],\"id\":1}' | jq -r .result"
   EOF
   ```

2. Make it executable:

   ```bash
   chmod +x $HOME/lustminer.sh
   ```

3. Run:

   ```bash
   ./lustminer.sh
   ```

4. Enter your **wallet** and **threads**.

---

## 3. Daily usage (Linux)

- **View logs**

  ```bash
  sudo docker logs -f lust-miner
  ```

- **Stop miner**

  ```bash
  sudo docker stop lust-miner
  ```

- **Start miner again**

  ```bash
  sudo docker start lust-miner
  ```

- **Remove miner (clean)**

  ```bash
  sudo docker rm -f lust-miner
  ```

- **Change wallet / change threads**: just run the script again:

  ```bash
  ./lustminer.sh
  ```

---

## 4. Windows + Docker Desktop

Create a file called `lustminer.ps1` and paste:

```powershell
# === Lust Chain Windows miner (with 3 official bootnodes) ===

$BOOTNODES = @'
enode://cf04c868ab597ab088cc0868b955368b36c47d22f162a59c8a732d3c4732dda5dac79bd39e41c6f853556aadfb100bacb709fd9f60dec8abfa3185c10ad782f5@138.197.125.190:30303,
enode://fddbd81de98139327094965d2bfcbe5d9baae312a52b72887a1f1ecba497b521273cefd360bce34c0575bb592d5287d9ed5c5be9698cce9b50c2d8acdc2fd55e@104.248.175.223:30303,
enode://707c8b3ef4311b55a7a027ddf499fa96ece47f7f7c226104df4f313a39c997d88a496ff61f33dd7597c8347c0c75a7a8caa5966ac45f7c434122c0331b8224c1@170.64.145.190:30303
'@

$GENESIS_URL = "http://138.197.125.190:18580/genesis.json"
$BASE        = "$HOME\lust-miner"
$DATA        = "$BASE\data"
$GENESIS     = "$BASE\genesis.json"
$IMG         = "ethereum/client-go:v1.10.26"
$NAME        = "lust-miner"

New-Item -ItemType Directory -Force -Path $DATA | Out-Null
Invoke-WebRequest -Uri $GENESIS_URL -OutFile $GENESIS

$wallet  = Read-Host "Wallet (0x...)"
$threads = Read-Host "Threads [2]"
if (-not $threads) { $threads = 2 }

$ddata = ($DATA -replace '\','/')
$dgen  = ($GENESIS -replace '\','/')

# 1) init
docker rm -f $NAME 2>$null | Out-Null
docker run --rm `
  -v "${ddata}:/root/.ethereum" `
  -v "${dgen}:/genesis.json" `
  $IMG `
  --datadir /root/.ethereum init /genesis.json

# 2) run
docker rm -f $NAME 2>$null | Out-Null
docker run -d --name $NAME `
  -v "${ddata}:/root/.ethereum" `
  -p 8545:8545 -p 30303:30303 `
  $IMG `
  --datadir /root/.ethereum `
  --http --http.addr 0.0.0.0 --http.port 8545 `
  --http.api eth,net,web3,miner,txpool `
  --networkid 6923 `
  --port 30303 `
  --bootnodes $BOOTNODES `
  --miner.etherbase $wallet `
  --miner.threads $threads `
  --mine

Write-Host "Miner is running. View logs with: docker logs -f $NAME"
```

### Daily usage (Windows)

- **View logs**

  ```powershell
  docker logs -f lust-miner
  ```

- **Stop miner**

  ```powershell
  docker stop lust-miner
  ```

- **Start miner**

  ```powershell
  docker start lust-miner
  ```

- **Remove miner**

  ```powershell
  docker rm -f lust-miner
  ```

- **Change wallet / threads**

  ```powershell
  docker rm -f lust-miner
  .\lustminer.ps1
  ```

---

## 5. Add Lust Chain to MetaMask

Use these settings:

- **Network Name:** Lust Chain
- **New RPC URL:** https://rpc.lustchain.org
- **Chain ID:** 6923
- **Currency Symbol:** LST
- **Block Explorer:** https://explorer.lustchain.org/ (when available)

---

## 6. License

This project is licensed under the MIT License — see `LICENSE` file for details.
