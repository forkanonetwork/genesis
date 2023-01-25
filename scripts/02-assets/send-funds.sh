#!/usr/bin/env bash

set -e

if [[ $# -ne 2 ]]; then
  echo "Error: Invalid number of arguments. Please provide funds and destination address as arguments."
  echo "Usage: send-fund <amount in lovelaces> <destination_address>"
  exit 1
fi

echo "Sending $1 funds from node to address $2"
echo "Press ENTER TWICE to confirm"
read REPLY
read REPLY
ID=4

ROOT=~/git/forkano-babbage/node-mainnet/node-spo${ID}

export FORKANO_NODE_SOCKET_PATH=$ROOT/node.sock

address_to=$2
address_from=$(cat ${ROOT}/addresses/payment${ID}.addr)

  forkano-cli query utxo --address $address_from  --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1
  GREATEST_INPUT=$(forkano-cli query utxo --address $address_from --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1)

  echo "GREATEST INPUT:" $GREATEST_INPUT

  TXID0=$(echo ${GREATEST_INPUT} | awk '{print $1}')
  COINS_IN_INPUT=$(echo ${GREATEST_INPUT} | awk '{print $2}')

  echo "Using ${TXID0}, containing ${COINS_IN_INPUT} lovelace(s)"
  echo "Sending to address:" $address_to

  forkano-cli query protocol-parameters \
    --mainnet \
    --out-file protocol-parameters.json

fee="0"
output="0"

forkano-cli transaction build-raw \
 --fee $fee \
 --tx-in $TXID0 \
 --tx-out $address_to+$output \
 --out-file matx.raw

fee=$(forkano-cli transaction calculate-min-fee --tx-body-file matx.raw --tx-in-count 1 --tx-out-count 1 --witness-count 25 --mainnet --protocol-params-file protocol-parameters.json | cut -d " " -f1)
funds=$COINS_IN_INPUT
funds=1000000000
funds=$1

echo "Calculated fee:" $fee
echo "COINS: " $COINS_IN_INPUT
echo "FUNDS: " $funds


#output=$(expr $COINS_IN_INPUT - $funds - $fee)
output=$(bc <<< "$COINS_IN_INPUT - $funds - $fee")
echo $address_to+$output

echo "Sending ${funds} to address:" $address_to

change=""
if [ $output -gt 0 ]
then
  echo "Building output"
  change="--tx-out $address_from+$output"
fi

forkano-cli transaction build-raw \
 --fee $fee \
 --tx-in $TXID0 \
 --tx-out $address_to+$funds $change \
 --out-file matx.raw

forkano-cli transaction sign  \
    --signing-key-file $ROOT/cold-keys/cold${ID}.skey \
    --signing-key-file $ROOT/keys/payment${ID}.skey \
    --mainnet --tx-body-file matx.raw  \
    --out-file matx.signed

echo "PRESS ENTER TO SEND THE FUNDS"
read

echo "SURE? ENTER AGAIN!"
read

forkano-cli transaction submit --tx-file matx.signed --mainnet