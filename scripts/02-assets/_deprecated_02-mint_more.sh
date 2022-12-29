#!/usr/bin/env bash

set -e

ROOT=~/git/forkano-babbage/private-mainnet

export NODE_SOCKET_PATH=$ROOT/main.sock

TOKEN_NAME1="Testtoken2"
TOKEN_NAME2="SecondTesttoken2"
TOKEN_AMOUNT="4400001"

testnet="--mainnet"
tokenname1=$(echo -n "${TOKEN_NAME1}" | xxd -ps | tr -d '\n')
tokenname2=$(echo -n "${TOKEN_NAME2}" | xxd -ps | tr -d '\n')
tokenamount=${TOKEN_AMOUNT}

export TOKEN_PATH=$ROOT/assets

address=$(cat $TOKEN_PATH/payment.addr)

  forkano-cli query utxo --address $address --mainnet
  forkano-cli query utxo --whole-utxo --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1
  GREATEST_INPUT=$(forkano-cli query utxo --address $address --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1)
  GREATEST_INPUT=$(forkano-cli query utxo --whole-utxo --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1)

  echo "GREATEST INPUT:" $GREATEST_INPUT

  TXID0=$(echo ${GREATEST_INPUT} | awk '{print $1}')
  COINS_IN_INPUT=$(echo ${GREATEST_INPUT} | awk '{print $2}')

  echo "Using ${TXID0}, containing ${COINS_IN_INPUT} lovelace(s)"
  echo "Sending to address:" $address
  policyid=$(cat $TOKEN_PATH/policy/policyID)

  forkano-cli query protocol-parameters \
  --mainnet \
  --out-file protocol-parameters.json

fee="0"
output="0"

forkano-cli transaction build-raw \
 --fee $fee \
 --tx-in $TXID0 \
 --tx-out $address+$output+"$tokenamount $policyid.$tokenname1 + $tokenamount $policyid.$tokenname2" \
 --mint "$tokenamount $policyid.$tokenname1 + $tokenamount $policyid.$tokenname2" \
 --minting-script-file $TOKEN_PATH/policy/policy.script \
 --out-file matx.raw

fee=$(forkano-cli transaction calculate-min-fee --tx-body-file matx.raw --tx-in-count 1 --tx-out-count 1 --witness-count 25 $testnet --protocol-params-file protocol-parameters.json | cut -d " " -f1)
funds=$COINS_IN_INPUT
#funds=10000000

echo "Calculated fee:" $fee
output=$(expr $funds - $fee)
echo $address+$output+"$tokenamount $policyid.$tokenname1 + $tokenamount $policyid.$tokenname2"

address=$(cat test.addr)
echo "Sending tokens to address:" $address

forkano-cli transaction build-raw \
 --fee $fee \
 --tx-in $TXID0 \
 --tx-out $address+$output+"$tokenamount $policyid.$tokenname1 + $tokenamount $policyid.$tokenname2" \
 --mint "$tokenamount $policyid.$tokenname1 + $tokenamount $policyid.$tokenname2" \
 --minting-script-file $TOKEN_PATH/policy/policy.script \
 --out-file matx.raw

#    --signing-key-file $ROOT/addresses/wallet1.skey  \
#    --signing-key-file $ROOT/addresses/wallet2.skey  \
#    --signing-key-file $ROOT/addresses/wallet3.skey  \


forkano-cli transaction sign  \
    --signing-key-file $TOKEN_PATH/payment.skey  \
    --signing-key-file $TOKEN_PATH/policy/policy.skey  \
--signing-key-file $ROOT/stake-delegator-keys/payment2.skey \
--signing-key-file $ROOT/stake-delegator-keys/staking1.skey \
--signing-key-file $ROOT/stake-delegator-keys/staking2.skey \
--signing-key-file $ROOT/stake-delegator-keys/staking3.skey \
--signing-key-file $ROOT/stake-delegator-keys/payment3.skey \
--signing-key-file $ROOT/stake-delegator-keys/payment1.skey \
--signing-key-file $ROOT/utxo-keys/utxo3.skey \
--signing-key-file $ROOT/utxo-keys/utxo2.skey \
--signing-key-file $ROOT/utxo-keys/utxo1.skey \
--signing-key-file $ROOT/pools/staking-reward1.skey \
--signing-key-file $ROOT/pools/cold3.skey \
--signing-key-file $ROOT/pools/cold2.skey \
--signing-key-file $ROOT/pools/staking-reward3.skey \
--signing-key-file $ROOT/pools/staking-reward2.skey \
--signing-key-file $ROOT/pools/cold1.skey \
--signing-key-file $ROOT/genesis-keys/genesis3.skey \
--signing-key-file $ROOT/genesis-keys/genesis1.skey \
--signing-key-file $ROOT/genesis-keys/genesis2.skey \
--signing-key-file $ROOT/delegate-keys/delegate2.skey \
--signing-key-file $ROOT/delegate-keys/delegate3.skey \
--signing-key-file $ROOT/delegate-keys/delegate1.skey \
    $testnet --tx-body-file matx.raw  \
    --out-file matx.signed

echo "PRESS ENTER TO MINT THE TOKENS"
read REPLY

echo "SURE? ENTER AGAIN!"
read REPLY

forkano-cli transaction submit --tx-file matx.signed $testnet

exit 0
