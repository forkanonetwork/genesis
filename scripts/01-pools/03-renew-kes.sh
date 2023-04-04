#!/usr/bin/env bash

set -e
# Unofficial bash strict mode.
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

a0_generate_counter() {
  forkano-cli query kes-period-info \
    --mainnet \
    --op-cert-file ${NODE_DIR}/opcert.cert \
    --out-file ${NODE_DIR}/kes_period.info
    counter=$(cat ${NODE_DIR}/kes_period.info | jq -r '.qKesNodeStateOperationalCertificateNumber')
    echo "Counter value:" $counter
    if [ "$counter" == "null" ]; then
      counter=0
    else
      counter=$(expr ${counter} + 1)
    fi
    echo "New qKesNodeStateOperationalCertificateNumber:" ${counter}
    rm ${NODE_DIR}/kes_period.info

    echo "If this data is ok then press ENTER, else press Ctrl-C"
    read REPLY
}

a1_generate_operational_certificate() {
  forkano-cli node new-counter \
    --cold-verification-key-file ${COLD_KEY}.vkey \
    --counter-value ${counter} \
    --operational-certificate-issue-counter-file ${NODE_DIR}/opcert.counter

  forkano-cli node key-gen-KES \
    --verification-key-file ${KEY_DIR}/kes${ID}.vkey \
    --signing-key-file ${KEY_DIR}/kes${ID}.skey

  echo "Generate the Operational Certificate"
  echo "We need to know the slots per KES period, we get it from the genesis file:"

  slotsPerKESPeriod=$(cat $ROOT/genesis/shelley/genesis.json | jq -r '.slotsPerKESPeriod')
  echo "slotsPerKESPeriod:" ${slotsPerKESPeriod}

  echo "Then we need the current tip of the blockchain:"
  slotNo=$(forkano-cli query tip --mainnet | jq -r '.slot')
  echo "slotNo:" ${slotNo}

  echo "Calculate KES Period"
  kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
  echo "kesPeriod:" ${kesPeriod}
  startKesPeriod=${kesPeriod}
  echo "startKesPeriod:" ${startKesPeriod}

  echo "If this data is ok then press ENTER TWICE, else press Ctrl-C"
  read REPLY

  forkano-cli node issue-op-cert --kes-verification-key-file ${KEY_DIR}/kes${ID}.vkey \
    --cold-signing-key-file ${COLD_KEY}.skey \
    --operational-certificate-issue-counter-file ${NODE_DIR}/opcert.counter \
    --kes-period ${kesPeriod} \
    --out-file ${NODE_DIR}/opcert.cert

  echo "This is the Operational Certificate"
  cat ${NODE_DIR}/opcert.cert
  echo "If this data is ok then press ENTER, else press Ctrl-C"
  read REPLY

  echo "RESTART THE NODE!!!"
  read REPLY
}

a0_generate_counter
a1_generate_operational_certificate
