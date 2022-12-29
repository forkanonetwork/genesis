#!/usr/bin/env bash

set -e
# Unofficial bash strict mode.
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

STAKE_BASE_DIR=${ROOT}/multi-staking

get_info() {
  echo "Stake Address Info"
  echo "Notice: rewardAccountBalance refers to the total amount available for withdrawal."
  echo "        The Rewards Withdrawal script is provided as 'xx-withdrawal.sh' script"
  echo "        Rewards are automatically added to pool stake each epoch, so there's no need to withdraw, it's your call"
    forkano-cli query stake-address-info \
      --address $(cat ${ADDR_DIR}/staking.addr) \
      --mainnet
  print_line
  read_enter "continue"

  echo "Funds/UTXOs for address $(cat ${ADDR_DIR}/payment.addr)"
  forkano-cli query utxo --address $(cat ${ADDR_DIR}/payment.addr) --mainnet
  print_line
  read_enter "exit"
}

for POOL_ID in ${STAKE_BASE_DIR}/* ; do
    echo "Info for pool ${POOL_ID}"
    ADDR_DIR=${POOL_ID}/addresses
    get_info ${POOL_ID}
done