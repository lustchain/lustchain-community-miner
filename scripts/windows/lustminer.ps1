# === Lust Chain Windows miner (com 3 bootnodes oficiais) ===

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

$ddata = ($DATA -replace '\\','/')
$dgen  = ($GENESIS -replace '\\','/')

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

docker logs -f $NAME
