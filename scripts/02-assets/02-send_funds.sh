#!/usr/bin/env bash

set -e

ROOT=~/git/forkano-babbage/private-mainnet

export NODE_SOCKET_PATH=$ROOT/main.sock

TOKEN_NAME1="Testtoken31"
TOKEN_NAME2="SecondTesttoken31"
TOKEN_AMOUNT="10000000"

testnet="--mainnet"
tokenname1=$(echo -n "${TOKEN_NAME1}" | xxd -ps | tr -d '\n')
tokenname2=$(echo -n "${TOKEN_NAME2}" | xxd -ps | tr -d '\n')
tokenamount=${TOKEN_AMOUNT}

export TOKEN_PATH=$ROOT/assets

set +e
mkdir $TOKEN_PATH/policy -p
set -e

ommi(){
forkano-cli address key-gen --verification-key-file payment.vkey --signing-key-file $TOKEN_PATH/payment.skey
forkano-cli address build --payment-verification-key-file payment.vkey --out-file $TOKEN_PATH/payment.addr $testnet

forkano-cli address key-gen \
    --verification-key-file $TOKEN_PATH/policy/policy.vkey \
    --signing-key-file $TOKEN_PATH/policy/policy.skey

touch $TOKEN_PATH/policy/policy.script && echo "" > $TOKEN_PATH/policy/policy.script

echo "{" >> $TOKEN_PATH/policy/policy.script 
echo "  \"keyHash\": \"$(forkano-cli address key-hash --payment-verification-key-file $TOKEN_PATH/policy/policy.vkey)\"," >> $TOKEN_PATH/policy/policy.script 
echo "  \"type\": \"sig\"" >> $TOKEN_PATH/policy/policy.script 
echo "}" >> $TOKEN_PATH/policy/policy.script

forkano-cli transaction policyid --script-file $TOKEN_PATH/policy/policy.script > $TOKEN_PATH/policy/policyID
}
address=$(cat $TOKEN_PATH/payment.addr)
#address=$(cat addresses/user1.addr)

  #forkano-cli query utxo --address $address --mainnet
  forkano-cli query utxo --whole-utxo --mainnet
    echo "That's the mainnet utxo"

  forkano-cli query utxo --whole-utxo --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1
  GREATEST_INPUT=$(forkano-cli query utxo --address $address --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1)
  GREATEST_INPUT=$(forkano-cli query utxo --whole-utxo --mainnet | tail -n +3 | awk '{printf "%s#%s %s \n", $1 , $2, $3}' | sort -rn -k2 | head -n1)

  echo "GREATEST INPUT:" $GREATEST_INPUT

    TX=$(cut -d "#" -f 1 <<< $GREATEST_INPUT)
    echo "TX: "${TX}
    
    TXTX=$(forkano-cli query utxo --whole-utxo --mainnet | grep ${TX})
    echo "TXTX: "${TXTX}

  TXID0=$(echo ${GREATEST_INPUT} | awk '{print $1}')
  COINS_IN_INPUT=$(echo ${GREATEST_INPUT} | awk '{print $2}')

    #CREATE FILE
    echo ""
    echo ""
    echo ""
    echo ""
    echo "File txs.details created!"
    $(forkano-cli query utxo --whole-utxo --mainnet --out-file txs.details)
    $(forkano-cli query utxo --address $address --mainnet --out-file txs.details)

    echo "INPUT TXID SELECTION"
    declare -A txids
    i=0
    for txid in $(cat txs.details | jq keys[] -r); do
	txamount=$(cat txs.details | jq .[\"$txid\"].value | jq -c .lovelace)
	txids[$i,0]=$txid;
	txids[$i,1]=$txamount;
	echo "$i -> $txid contains $txamount lovelaces"
	i=$((i+1))
    done
    read TXSEL

    echo "USING ID ${TXSEL} - ${txids[$TXSEL,0]}, containing ${txids[${TXSEL},1]} lovelaces"
    
    TXID0=${txids[$TXSEL,0]}
    COINS_IN_INPUT=${txids[$TXSEL,1]}

    LENGTH=$(cat txs.details | jq .[\"${TXID0}\"].value | jq length)
    $(cat txs.details | jq .[\"${TXID0}\"].value > ${TXID0}.values )
    

    echo "Length: "${LENGTH}

    build=""
    echo "Iterating thru keys..."
    for key in $(cat ${TXID0}.values | jq -c keys_unsorted[] -r ); do
        echo "KEY: "$key
	if [ $key != "lovelace" ]; then
    	    echo "Iterating thru tokens..."
	    for token in $(cat ${TXID0}.values | jq .\"${key}\" | jq -c keys_unsorted[] -r); do
		echo "Token: "$token
        	value=$(cat ${TXID0}.values | jq .\"${key}\" | jq .\"${token}\")
        	echo "VALUE: "$value
		build="$build+$value $key.$token "
	    done
	else 
	    lovelaces=$(cat ${TXID0}.values | jq .\"${key}\")
	    echo "Lovelaces: "$lovelaces
	    #build="$lovelaces $build"
	fi
        #echo $(cat ${TXID0}.values | jq -c keys_unsorted[]);
    done

    echo "Built output: "$build
    read REPLY

  echo "Using ${TXID0}, containing ${COINS_IN_INPUT} lovelace(s)"
  echo "Sending to address:" $address
  policyid=$(cat $TOKEN_PATH/policy/policyID)

  forkano-cli query protocol-parameters \
  --mainnet \
  --out-file protocol-parameters.json

fee="0"
output="0"
funds=2000000000

address_to=$(cat test.addr)
#echo " --tx-out $address+$output$build "
# --tx-out $address+$output"$build" \
read REPLY
forkano-cli transaction build-raw \
 --fee $fee \
 --tx-in $TXID0 \
 --tx-out $address_to+$funds+"$tokenamount $policyid.$tokenname1 + $tokenamount $policyid.$tokenname2" \
 --tx-out $address+$output \
 --mint "$tokenamount $policyid.$tokenname1 + $tokenamount $policyid.$tokenname2" \
 --minting-script-file $TOKEN_PATH/policy/policy.script \
 --out-file matx.raw

fee=$(forkano-cli transaction calculate-min-fee --tx-body-file matx.raw --tx-in-count 1 --tx-out-count 2 --witness-count 25 $testnet --protocol-params-file protocol-parameters.json | cut -d " " -f1)
#funds=$COINS_IN_INPUT
change=$(expr $COINS_IN_INPUT - $funds - $fee)

echo "Calculated fee:" $fee
#output=$(expr $funds - $fee)
echo $address$funds+"$tokenamount $policyid.$tokenname1 + $tokenamount $policyid.$tokenname2"

echo "Sending tokens to address:" $address_to

echo ""
echo "COINS: ${COINS_IN_INPUT}"
echo "FUNDS: ${funds}"
echo "FEE: ${fee}"
echo "CHANGE: ${change}"
echo "Total: $(expr ${change} + ${fee} + ${funds})"

forkano-cli transaction build-raw \
 --fee $fee \
 --tx-in $TXID0 \
 --tx-out $address+$change \
 --tx-out $address+$funds \
 --out-file matx.raw



#    --signing-key-file $ROOT/addresses/wallet1.skey  \
#    --signing-key-file $ROOT/addresses/wallet2.skey  \
#    --signing-key-file $ROOT/addresses/wallet3.skey  \

a() {
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
}

forkano-cli transaction sign  \
    --signing-key-file $ROOT/assets/policy/policy.skey \
    --signing-key-file $ROOT/assets/payment.skey \
    --signing-key-file $ROOT/node-spo5/stake.skey \
    --signing-key-file $ROOT/node-spo5/cold.skey \
    --signing-key-file $ROOT/node-spo5/bak/stake.skey \
    --signing-key-file $ROOT/node-spo5/bak/cold.skey \
    --signing-key-file $ROOT/node-spo5/bak/payment.skey \
    --signing-key-file $ROOT/node-spo5/payment.skey \
    --signing-key-file $ROOT/node-spo5/pool-keys/cold.skey \
    --signing-key-file $ROOT/node-spo6/stake.skey \
    --signing-key-file $ROOT/node-spo6/pool-keys.bak/cold.skey \
    --signing-key-file $ROOT/node-spo6/payment.skey \
    --signing-key-file $ROOT/node-spo6/pool-keys/cold.skey \
    --signing-key-file $ROOT/stake-delegator-keys/payment2.skey \
    --signing-key-file $ROOT/stake-delegator-keys/staking1.skey \
    --signing-key-file $ROOT/stake-delegator-keys/staking2.skey \
    --signing-key-file $ROOT/stake-delegator-keys/staking3.skey \
    --signing-key-file $ROOT/stake-delegator-keys/payment3.skey \
    --signing-key-file $ROOT/stake-delegator-keys/staking4.skey \
    --signing-key-file $ROOT/stake-delegator-keys/payment1.skey \
    --signing-key-file $ROOT/stake-delegator-keys/staking5.skey \
    --signing-key-file $ROOT/node-spo4/stake.skey \
    --signing-key-file $ROOT/node-spo4/cold.skey \
    --signing-key-file $ROOT/node-spo4/payment.skey \
    --signing-key-file $ROOT/utxo-keys/utxo3.skey \
    --signing-key-file $ROOT/utxo-keys/utxo2.skey \
    --signing-key-file $ROOT/utxo-keys/utxo5.skey \
    --signing-key-file $ROOT/utxo-keys/utxo4.skey \
    --signing-key-file $ROOT/utxo-keys/utxo1.skey \
    --signing-key-file $ROOT/pools/staking-reward1.skey \
    --signing-key-file $ROOT/pools/cold3.skey \
    --signing-key-file $ROOT/pools/cold2.skey \
    --signing-key-file $ROOT/pools/cold5.skey \
    --signing-key-file $ROOT/pools/cold6.skey \
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

echo "PRESS ENTER TO SEND THE FUNDS"
read REPLY

echo "SURE? ENTER AGAIN!"
read REPLY

forkano-cli transaction submit --tx-file matx.signed $testnet

exit 0
