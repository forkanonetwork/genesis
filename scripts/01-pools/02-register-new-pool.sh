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

FORKANO_NET_URL="pools.forkano.net"

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

a0_check_pool_data() {
  ################################################ "PLEASE CHANGE THIS!!!"####################################################################################
  POOL_NAME="Name"
  POOL_DESCRIPTION="Description"
  # Remember: Pool ticker cannot be larger than 6 characters, letters and/or numbers
  POOL_TICKER="AAA1"
  POOL_HOMEPAGE="https://homepage.your.pool"
  POOL_RELAY_IPV4="127.0.0.1"
  ################################################ "PLEASE CHANGE THIS!!!"####################################################################################

  if [ ! ${POOL_NAME:+x} ] || [ ! ${POOL_DESCRIPTION:+x} ] || [ ! ${POOL_TICKER:+x} ] || [ ! ${POOL_RELAY_IPV4:+x} ] || [ ! ${POOL_HOMEPAGE:+x} ]; then
    echo "Pool data not set. Please edit this script and fill all POOL_ variables before running!"
    echo "Exiting..."
    exit 0
  else
    echo "Preparing your pool with following info:"
    echo "Pool Name:" ${POOL_NAME}
    echo "Pool Description:" ${POOL_DESCRIPTION}
    echo "Pool Ticker:" ${POOL_TICKER}
    echo "Pool Homepage:" ${POOL_HOMEPAGE}
    echo "Pool IPV4:" ${POOL_RELAY_IPV4}
    echo "Press ENTER TWICE to continue"
    read REPLY
    read REPLY
  fi
}

a1_check_initial_funds() {
  ADDRESS=$(cat ${ADDR_DIR}/payment$ID.addr)
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

a2_generate_operational_certificate() {
  #Generate the Operational Certificate
  SLOT=$(forkano-cli query tip --mainnet | jq -r '.slot')
  SLOTSPERKES=$(cat ${ROOT}/genesis/shelley/genesis.json  | jq -r '.slotsPerKESPeriod')
  if [ "${SLOT}" -gt "${SLOTSPERKES}" ]; then
    KESPERIOD="$(expr ${SLOT}  / ${SLOTSPERKES})"
  else 
    KESPERIOD=0
  fi
  echo "Generating operational certificate with KES-PERIOD:" ${KESPERIOD}
  echo "Press ENTER to continue or CTRL-C to abort"
  read REPLY
  forkano-cli node issue-op-cert \
    --kes-verification-key-file ${KEY_DIR}/kes${ID}.vkey \
    --cold-signing-key-file ${COLD_KEY}.skey \
    --operational-certificate-issue-counter ${NODE_DIR}/opcert.counter \
    --kes-period ${KESPERIOD} \
    --out-file ${NODE_DIR}/opcert.cert

  forkano-cli node new-counter \
    --cold-verification-key-file ${COLD_KEY}.vkey \
    --counter-value 0 \
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
}

a3_generate_delegation_certificate() {
echo "Generate Delegation Certificate (pledge) "
echo "Press ENTER to continue or CTRL-C to abort"
read REPLY

forkano-cli stake-address delegation-certificate \
  --stake-verification-key-file ${STAKE_KEY}.vkey \
  --cold-verification-key-file ${COLD_KEY}.vkey \
  --out-file ${ADDR_DIR}/staking${ID}.deleg.cert
}

a4_submit_registration_certificate() {
  echo "Submit the stake registration certificate to the blockchain"
  ADDRESS=$(cat ${ADDR_DIR}/payment$ID.addr)
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
    --out-file tx.raw \
    --certificate-file ${ADDR_DIR}/staking${ID}.reg.cert \

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
    --certificate-file ${ADDR_DIR}/staking${ID}.reg.cert \
    --out-file tx.raw

  echo "Signing transaction"
  forkano-cli transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file ${PAYMENT_KEY}.skey \
    --signing-key-file ${STAKE_KEY}.skey \
    --signing-key-file ${COLD_KEY}.skey \
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

a5_generate_pledge_certificate() {
  (
    echo "{"
    echo "  \"name\": \"${POOL_NAME}\","
    echo "  \"description\": \"${POOL_DESCRIPTION}\","
    echo "  \"ticker\": \"${POOL_TICKER}\","
    echo "  \"homepage\": \"${POOL_HOMEPAGE}\""
    echo "}"
  ) > "metadataPool${ID}.json"

  POOL_METADATA_HASH=$(forkano-cli stake-pool metadata-hash --pool-metadata-file metadataPool${ID}.json)
  echo "Pool Metadata Hash:" ${POOL_METADATA_HASH}

  echo "#Generate delegation certificate (pledge)"
  echo "Press ENTER to continue or CTRL-C to abort"
  read REPLY
  forkano-cli stake-pool registration-certificate \
    --cold-verification-key-file ${COLD_KEY}.vkey \
    --vrf-verification-key-file ${VRF_KEY}.vkey \
    --pool-pledge 20000000 \
    --pool-cost 4321000000 \
    --pool-margin 0.04 \
    --pool-reward-account-verification-key-file ${STAKE_KEY}.vkey \
    --pool-owner-stake-verification-key-file ${STAKE_KEY}.vkey \
    --mainnet \
    --pool-relay-ipv4 ${POOL_RELAY_IPV4} \
    --pool-relay-port 300$ID \
    --metadata-url metadataPool$ID.json \
    --metadata-hash ${POOL_METADATA_HASH} \
    --out-file ${NODE_DIR}/pool-registration$ID.cert

  cat ${NODE_DIR}/pool-registration$ID.cert
}

a6_submit_certificates() {
  echo "Submit the pool certificate and delegation certificate to the blockchain"
  GREATEST_INPUT=$(forkano-cli query utxo --whole-utxo --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -n -k1 | head -n1)
  ADDRESS=$(cat ${ADDR_DIR}/payment$ID.addr)
  echo "Checking balance from address" $ADDRESS
  echo "forkano-cli query utxo --address $ADDRESS --mainnet, PRESS ENTER"
  read
  GREATEST_INPUT=$(forkano-cli query utxo --address $ADDRESS --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1)

  TXID0=$(echo ${GREATEST_INPUT} | awk '{print $1}')
  COINS_IN_INPUT=$(echo ${GREATEST_INPUT} | awk '{print $2}')
  echo "Using ${TXID0}, containing ${COINS_IN_INPUT} lovelace"

  forkano-cli transaction build-raw \
    --tx-in ${TXID0} \
    --tx-out ${ADDRESS}+0 \
    --ttl 0 \
    --fee 0 \
    --out-file tx.raw \
    --certificate-file ${ADDR_DIR}/staking$ID.deleg.cert \
    --certificate-file ${NODE_DIR}/pool-registration$ID.cert

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
    --certificate-file ${NODE_DIR}/pool-registration$ID.cert \
    --certificate-file ${ADDR_DIR}/staking$ID.deleg.cert \
    --out-file tx.raw

  echo "Signing transaction"
  forkano-cli transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file ${PAYMENT_KEY}.skey \
    --signing-key-file ${STAKE_KEY}.skey \
    --signing-key-file ${COLD_KEY}.skey \
    --mainnet \
    --out-file tx.signed

  echo "Submitting transaction, PRESS ENTER TWICE!!"
  read REPLY
  forkano-cli transaction submit \
    --tx-file tx.signed \
    --mainnet

  echo "If transaction submitted successfully then PRESS ENTER TWICE!!"
  echo "Otherwise press CTRL+C to abort"
  read REPLY
  read REPLY

  #forkano-cli stake-pool id --cold-verification-key-file ${COLD_KEY}.vkey
  #POOLID=$(forkano-cli stake-pool id --cold-verification-key-file ${COLD_KEY}.vkey)
  #forkano-cli query ledger-state --mainnet | grep publicKey | grep ${POOLID}
}

a7_create_scripts() {
  # Create scripts
  (
    echo "#!/usr/bin/env bash"
    echo ""
    echo "forkano-node run \\"
    echo "  --config                          '${NODE_DIR}/extra/configuration.yaml' \\"
    echo "  --topology                        '${NODE_DIR}/topology.json' \\"
    echo "  --database-path                   '${NODE_DIR}/db' \\"
    echo "  --socket-path                     '$(sprocket "${NODE_DIR}/node.sock")' \\"
    echo "  --shelley-kes-key                 '${KEY_DIR}/kes${ID}.skey' \\"
    echo "  --shelley-vrf-key                 '${KEY_DIR}/vrf${ID}.skey' \\"
    echo "  --shelley-operational-certificate '${NODE_DIR}/opcert.cert' \\"
    echo "  --port                             '${PORT}'"
  ) > "${NODE_DIR}.sh"

  chmod a+x "${NODE_DIR}.sh"

  echo "${NODE_DIR}.sh Created! PLEASE RESTART THE NODE!!!"
  echo "Press enter to acknowledge"
  read REPLY
}

a0_check_pool_data
a1_check_initial_funds
a2_generate_operational_certificate
a3_generate_delegation_certificate
a4_submit_registration_certificate
a5_generate_pledge_certificate
a6_submit_certificates
a7_create_scripts