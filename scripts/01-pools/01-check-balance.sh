#!/usr/bin/env bash

set -e
# See: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -u
set -o pipefail

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

print_line() {
  printf '\n%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' '-'
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


ID=4
NODE=node-spo${ID}
NODE_DIR=${ROOT}/${NODE}
ADDR_DIR=${NODE_DIR}/addresses
min_funds=1000000000

a1_check_initial_funds() {
  ADDRESS=$(cat ${ADDR_DIR}/payment$ID.addr)
  print_line
  echo "Your main pool address is:"
  echo ${ADDRESS}
  echo "You NEED at least ${min_funds} in order to proceed with pool registration!"
  echo "So, please, ask for funds or transfer to your pool's address first"
  print_line
  echo "Press ENTER to check current address balance"
  read REPLY
  echo "Checking balance from address" $ADDRESS
  GREATEST_INPUT=$(forkano-cli query utxo --address $ADDRESS --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1)

  TXID0=$(echo ${GREATEST_INPUT} | awk '{print $1}')
  COINS_IN_INPUT=$(echo ${GREATEST_INPUT} | awk '{print $2}')
    
  if [ -z ${COINS_IN_INPUT} ]; then
    echo "No funds yet, transfer some funds and try again later"
    echo "Exiting now..."
  else
    echo "Total balance for this address is: ${COINS_IN_INPUT}"
    if [ ${COINS_IN_INPUT} -ge ${min_funds} ]; then
      print_line
      echo "Funds arrived, now you can continue with next step!"
    else 
      echo "Not enough funds! Min funds needed: ${min_funds}"
      echo "Exiting now..."
    fi
  fi
  print_line
}

a1_check_initial_funds
