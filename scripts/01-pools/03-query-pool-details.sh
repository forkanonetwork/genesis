#!/usr/bin/env bash

set -e
# See: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -u
set -o pipefail

print_line() {
  printf '%*s\n\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' '-'
}

read_enter() {
  echo "Press enter to ${1}"
  read REPLY
}

UNAME=$(uname -s) SED=
case $UNAME in
  Darwin )      SED="gsed";;
  Linux )       SED="sed";;
esac

sprocket() {
  if [ "$UNAME" == "Windows_NT" ]; then
    # Named pipes names on Windows must have the structure: "\\.\pipe\PipeName"
    # See https://docs.microsoft.com/en-us/windows/win32/ipc/pipe-names
    echo -n '\\.\pipe\'
    echo "$1" | sed 's|/|\\|g'
  else
    echo "$1"
  fi
}

UNAME=$(uname -s) DATE=
case $UNAME in
  Darwin )      DATE="gdate";;
  Linux )       DATE="date";;
  MINGW64_NT* ) UNAME="Windows_NT"
                DATE="date";;
esac

ROOT=$(cat ~/forkano_root_dir)node-mainnet
export FORKANO_NODE_SOCKET_PATH=${ROOT}/main.sock

FORKANO_NET_URL="127.0.0.1"
#FORKANO_NET_URL="pools.forkano.net"

ID=4
PORT=300${ID}
NODE=node-spo${ID}
NODE_DIR=${ROOT}/${NODE}
ADDR_DIR=${NODE_DIR}/addresses
COLD_KEY_DIR=${NODE_DIR}/cold-keys
KEY_DIR=${NODE_DIR}/keys
PAYMENT_KEY="${KEY_DIR}/payment${ID}"
STAKE_KEY="${KEY_DIR}/stake${ID}"
COLD_KEY="${COLD_KEY_DIR}/cold$ID"
VRF_KEY="${KEY_DIR}/vrf$ID"

echo "This is the list of every stake pool on the mainnet"
print_line
forkano-cli query stake-pools --mainnet | echo "$(tee >(wc -l)) registered stake pool(s) found!"
print_line
read_enter "continue"

# Getting THIS POOL info
POOL_ID=$(forkano-cli stake-pool id --cold-verification-key-file ${COLD_KEY}.vkey)
POOL_ID_HEX=$(forkano-cli stake-pool id --cold-verification-key-file ${COLD_KEY}.vkey --output-format "hex")
echo "Info on POOL:" $POOL_ID
echo "Stake info:"
echo "Notice: activeStake refers to the total blockchain mark/set/go stake"
echo "        poolStake   refers to the pool mark/set/go stake"
echo "        It takes one epoch for each transition -> Stake -> Mark -> Set -> Go -> Rewards "
forkano-cli query stake-snapshot --stake-pool-id ${POOL_ID} --mainnet
print_line
read_enter "continue"

echo "Operational certificate info"
echo "Notice: remember to RENEW KES when needed. The KES Renewal script is provided as 'xx-renew_kes.sh' script"
forkano-cli query kes-period-info --mainnet --op-cert-file ${NODE_DIR}/opcert.cert
print_line
read_enter "continue"

#forkano-cli query ledger-state --mainnet | grep publicKey | grep $POOL_ID_HEX

echo "Leadership Schedule for POOL:" $POOL_ID
forkano-cli query leadership-schedule \
    --mainnet \
    --genesis $ROOT/genesis/shelley/genesis.json \
    --stake-pool-id $POOL_ID \
    --vrf-signing-key-file ${VRF_KEY}.skey \
    --current
print_line
read_enter "continue"

echo "Stake Address Info"
echo "Notice: rewardAccountBalance refers to the total amount available for withdrawal."
echo "        The Rewards Withdrawal script is provided as 'xx-withdrawal.sh' script"
echo "        Rewards are automatically added to pool stake each epoch, so there's no need to withdraw, it's your call"
  forkano-cli query stake-address-info \
    --address $(cat ${ADDR_DIR}/staking${ID}.addr) \
    --mainnet
print_line
read_enter "continue"

echo "Mainnet Query Tip"
forkano-cli query tip --mainnet
print_line
read_enter "continue"

echo "Funds/UTXOs for address $(cat ${ADDR_DIR}/payment${ID}.addr)"
forkano-cli query utxo --address $(cat ${ADDR_DIR}/payment${ID}.addr) --mainnet
print_line
read_enter "exit"