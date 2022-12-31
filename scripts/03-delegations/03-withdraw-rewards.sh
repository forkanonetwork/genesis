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

withdraw_rewards() {

    PAYMENT_ADDR=${ADDR_DIR}/payment.addr
    STAKE_ADDR=${ADDR_DIR}/staking.addr

    PAYMENT_SKEY=${KEYS_DIR}/payment.skey
    STAKE_SKEY=${KEYS_DIR}/staking.skey

    dstAddress=$(cat ${PAYMENT_ADDR}) 

    echo '---------------------'
    echo "Destination address:" ${dstAddress}

    rewards=$(forkano-cli query stake-address-info \
    --mainnet \
    --address $(cat ${STAKE_ADDR}) | jq '.[0].rewardAccountBalance')

    echo "Rewards to withdraw:" ${rewards}
    echo '---------------------'

    currentSlot=$(forkano-cli query tip --mainnet | jq -r '.slot')
    echo "Current Slot:" $currentSlot

    forkano-cli query utxo \
        --address $(cat ${PAYMENT_ADDR}) \
        --mainnet > fullUtxo.out

    tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out

    cat balance.out

    tx_in=""
    total_balance=0
    while read -r utxo; do
        in_addr=$(echo ${utxo} | awk '{ print $1 }')
        idx=$(echo ${utxo} | awk '{ print $2 }')
        utxo_balance=$(echo ${utxo} | awk '{ print $3 }')
        total_balance=$((${total_balance}+${utxo_balance}))
        echo TxHash: ${in_addr}#${idx}
        echo CAP: ${utxo_balance}
        tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
    done < balance.out
    txcnt=$(cat balance.out | wc -l)
    echo Total CAP balance: ${total_balance}
    echo Number of UTXOs: ${txcnt}

    forkano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat ${PAYMENT_ADDR})+0 \
    --withdrawal $(cat ${STAKE_ADDR})+0 \
    --invalid-hereafter 0 \
    --fee 0 \
    --out-file withdraw_rewards.draft

    forkano-cli query protocol-parameters --mainnet --out-file protocol-parameters.json

    fee=$(forkano-cli transaction calculate-min-fee \
    --tx-body-file withdraw_rewards.draft  \
    --tx-in-count 1 \
    --tx-out-count 1 \
    --witness-count 2 \
    --byron-witness-count 0 \
    --mainnet \
    --protocol-params-file protocol-parameters.json | awk '{print $1}')

    echo fee: $fee

    forkano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat ${PAYMENT_ADDR})+$(( ${total_balance} - ${fee} + ${rewards} )) \
    --withdrawal $(cat ${STAKE_ADDR})+${rewards} \
    --invalid-hereafter $(( ${currentSlot} +10000)) \
    --fee ${fee} \
    --out-file withdraw_rewards.raw

    forkano-cli transaction sign \
    --tx-body-file withdraw_rewards.raw  \
    --signing-key-file ${PAYMENT_SKEY} \
    --signing-key-file ${STAKE_SKEY} \
    --mainnet \
    --out-file withdraw_rewards.signed

    echo "PRESS ENTER TWICE TO SUBMIT TRANSACTION"
    read REPLY

    echo "SURE?"
    read REPLY

    forkano-cli transaction submit \
    --tx-file withdraw_rewards.signed \
    --mainnet

    rm protocol-parameters.json
    rm balance.out
    rm fullUtxo.out
    rm withdraw_rewards.draft
    rm withdraw_rewards.raw
    rm withdraw_rewards.signed
}

for POOL_ID in ${STAKE_BASE_DIR}/* ; do
    echo "Info for pool ${POOL_ID}"

    ADDR_DIR=${POOL_ID}/addresses
    CERTS_DIR=${POOL_ID}/certs
    KEYS_DIR=${POOL_ID}/keys

    get_info ${POOL_ID}
    withdraw_rewards ${POOL_ID}
done
