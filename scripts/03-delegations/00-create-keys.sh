#!/usr/bin/env bash


print_line() {
  printf '%*s\n\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' '-'
}

read_enter() {
  echo "Press enter to ${1}"
  read REPLY
}


set -e
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

FORKANO_NET_URL="pools.forkano.net"

echo "This is the list of every stake pool on the mainnet"
print_line
forkano-cli query stake-pools --mainnet | echo "$(tee >(wc -l)) registered stake pool(s) found!"
print_line
read_enter "continue"

echo "Paste here your selected pool ID"
read POOL_ID

POOL_ID="pool1y26d5lyzc986y4hccezm9ju0fwtfvear5f86w3v6ln5zvxhqd33"

if [ -z $POOL_ID ]; then
    echo "You need to provide destination pool ID in format \"pool1...\""
    exit 1
fi

ID=$POOL_ID

STAKE_BASE_DIR=${ROOT}/multi-staking/${POOL_ID}
ADDR_DIR=${STAKE_BASE_DIR}/addresses
COLD_KEY_DIR=${STAKE_BASE_DIR}/cold-keys
KEY_DIR=${STAKE_BASE_DIR}/keys

PAYMENT_KEY="${ADDR_DIR}/payment"
STAKE_KEY="${KEY_DIR}/stake"
COLD_KEY="${COLD_KEY_DIR}/cold"
VRF_KEY="${KEY_DIR}/vrf"

a0_create_directories() {
  set +e
  rm -r ${STAKE_BASE_DIR}
  mkdir ${STAKE_BASE_DIR} -p
  mkdir ${ADDR_DIR} -p
  mkdir ${COLD_KEY_DIR} -p
  mkdir ${KEY_DIR} -p
  set -e
}

a1_create_keys() {
  # PaymentStakeStake keys
  forkano-cli address key-gen \
	--verification-key-file ${PAYMENT_KEY}.vkey \
	--signing-key-file ${PAYMENT_KEY}.skey

  # Stake keys
  forkano-cli stake-address key-gen \
	--verification-key-file ${STAKE_KEY}.vkey \
	--signing-key-file ${STAKE_KEY}.skey

  # Payment addresses
  forkano-cli address build \
        --payment-verification-key-file ${PAYMENT_KEY}.vkey \
        --stake-verification-key-file ${STAKE_KEY}.vkey \
        --mainnet \
        --out-file ${ADDR_DIR}/payment.addr

  # Stake addresses
  forkano-cli stake-address build \
        --stake-verification-key-file ${STAKE_KEY}.vkey \
        --mainnet \
        --out-file ${ADDR_DIR}/staking.addr

  # Stake addresses registration certs
  forkano-cli stake-address registration-certificate \
        --stake-verification-key-file ${STAKE_KEY}.vkey \
        --out-file ${ADDR_DIR}/staking_registration.cert

  # Create delegation certificate
  forkano-cli stake-address delegation-certificate \
      --stake-verification-key-file ${STAKE_KEY}.vkey \
      --stake-pool-id ${POOL_ID} \
      --out-file ${ADDR_DIR}/staking_delegation.cert

}

a1_check_initial_funds() {
  ADDRESS=$(cat ${ADDR_DIR}/payment.addr)
  echo "PLEASE TRANSFER SOME FUNDS TO ADDRESS" $ADDRESS " FIRST!!, then press ENTER TWICE!!"
  read REPLY
  read REPLY
  GREATEST_INPUT=$(forkano-cli query utxo --whole-utxo --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -n -k1 | head -n1)
  echo "Checking balance from address" $ADDRESS
  echo "forkano-cli query utxo --address $ADDRESS --mainnet, PRESS ENTER"
  read REPLY
  GREATEST_INPUT=$(forkano-cli query utxo --address $ADDRESS --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1)

  TXID0=$(echo ${GREATEST_INPUT} | awk '{print $1}')
  COINS_IN_INPUT=$(echo ${GREATEST_INPUT} | awk '{print $2}')
    
  echo "FUNDS: ${COINS_IN_INPUT}"
  if [ -z ${COINS_IN_INPUT} ]; then
    echo "No funds yet, try again later"
    exit 0
  else
    min_funds=1000000000
    if [ ${COINS_IN_INPUT} -ge ${min_funds} ]; then
      echo "Funds arrived, press ENTER to resume..."
      read REPLY
    else 
      echo "Not enough funds! Min funds needed: ${min_funds}"
      exit 0
    fi
  fi
}

a2_submit_certs() {
  echo "Submit the stake registration certificate to the blockchain"
  ADDRESS=$(cat ${ADDR_DIR}/payment.addr)
  echo "PLEASE TRANSFER SOME FUNDS TO ADDRESS" $ADDRESS " FIRST!!, then press ENTER TWICE!!"
  read REPLY
  read REPLY
  GREATEST_INPUT=$(forkano-cli query utxo --whole-utxo --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -n -k1 | head -n1)
  echo "Checking balance from address" $ADDRESS
  echo "forkano-cli query utxo --address $ADDRESS --mainnet, PRESS ENTER"
  read REPLY
  GREATEST_INPUT=$(forkano-cli query utxo --address $ADDRESS --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1)

  TXID0=$(echo ${GREATEST_INPUT} | awk '{print $1}')
  COINS_IN_INPUT=$(echo ${GREATEST_INPUT} | awk '{print $2}')
    
  echo "Using ${TXID0}, containing ${COINS_IN_INPUT} lovelace"
  forkano-cli transaction build-raw \
    --tx-in ${TXID0} \
    --tx-out ${ADDRESS}+0 \
    --ttl 0 \
    --fee 0 \
    --certificate-file ${ADDR_DIR}/staking_registration.cert \
    --certificate-file ${ADDR_DIR}/staking_delegation.cert \
    --out-file tx.raw

  forkano-cli query protocol-parameters \
    --mainnet \
    --out-file protocol.json

  echo "Calculating min fee:"
  FEE=$(forkano-cli transaction calculate-min-fee \
    --tx-body-file tx.raw \
    --tx-in-count 1 \
    --tx-out-count 2 \
    --mainnet \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file protocol.json)

  FEE=$(echo ${FEE} | awk '{print $1}')
  echo "FEE:" $FEE 

  DEPOSIT=20000000
  CHANGE=$(expr ${COINS_IN_INPUT} - $DEPOSIT - $FEE)

  echo "Trying to deposit about $DEPOSIT lovelace(s)"

  echo "Building transaction"
  currentSlot=$(forkano-cli query tip --mainnet | jq -r '.slot')
  forkano-cli  transaction build-raw \
    --tx-in ${TXID0} \
    --tx-out ${ADDRESS}+${DEPOSIT} \
    --tx-out ${ADDRESS}+${CHANGE} \
    --invalid-hereafter $(( ${currentSlot} +10000)) \
    --fee $FEE \
    --certificate-file ${ADDR_DIR}/staking_registration.cert \
    --certificate-file ${ADDR_DIR}/staking_delegation.cert \
    --out-file tx.raw

  echo "Signing transaction"
  forkano-cli transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file ${PAYMENT_KEY}.skey \
    --signing-key-file ${STAKE_KEY}.skey \
    --mainnet \
    --out-file tx.signed

      echo "Submitting transaction, PRESS ENTER TWICE!!"
  read REPLY
  echo "SHURE?"
  read REPLY
  forkano-cli transaction submit \
    --tx-file tx.signed \
    --mainnet

  echo "If transaction submitted successfully then PRESS ENTER TWICE!!"
  echo "Otherwise press CTRL+C to abort"
  read REPLY
  read REPLY
}


#a0_create_directories
#a1_create_keys
a1_check_initial_funds
a2_submit_certs