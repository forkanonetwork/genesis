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

echo "Write the First Token name and press enter"
read TOKEN1_NAME
echo "Now write the amount to mint for the token called \"${TOKEN1_NAME}\""
read TOKEN1_AMOUNT

echo "Write the Second Token name and press enter"
read TOKEN2_NAME
echo "Now write the amount to mint for the token called \"${TOKEN2_NAME}\""
read TOKEN2_AMOUNT

# Max_Token_Amount = 9223372036854775807
# This is the max integer number that javascript (ergo Pip-Boy) could handle in A SINGLE tx
# If you have a larger amount in Pip-Boy Vault, you won't be able to transfer a portion
# You'll have to transfer all to a forkano-node and then you'll be able to divide and conquer
Max_Token_Amount=9223372036854775807

testnet="--mainnet"
token1name=$(echo -n "${TOKEN1_NAME}" | xxd -ps | tr -d '\n')
token2name=$(echo -n "${TOKEN2_NAME}" | xxd -ps | tr -d '\n')

TOKEN_PATH=$ROOT/assets

set +e
mkdir ${TOKEN_PATH}/policy -p
set -e

generate_new_policy_id() {
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

echo -n "Do you want to RE-GENERATE PolicyID?, write YES, and then press ENTER, otherwise just press ENTER: "
read REPLY

if [ -z $REPLY ]; then
    echo "Ok, using previous"
else
    if [ $REPLY == "YES" ]; then
	echo "Generating new POLICY ID, F**K THE PREVIOUS ONE!"
  echo "Maybe a backup would be great in the future, right?"
  echo "So the F**K word could be FORK :)"
  ecoh "Oh, I'm so funny"
	generate_new_policy_id
    fi
fi

address=$(cat ${ADDR_DIR}/payment${ID}.addr)

    # Creating txs details file
    echo "File txs.details created!"

    # This is the list for EVERY UTXO
    # Skipping for now
    # $(forkano-cli query utxo --whole-utxo --mainnet --out-file txs.details)

    #This is the list for the UTXO associated with $address!
    #Then we need to identify the skey files associated with THIS address
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
    echo -n "Select your TXID: "
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
		echo "Token: " $(echo -n $token | xxd -ps -r | tr -d '\n')
        	value=$(cat ${TXID0}.values | jq .\"${key}\" | jq .\"${token}\")
        	echo "VALUE: "$value
		build="$build+$value $key.$token "
	    done
	else 
	    lovelaces=$(cat ${TXID0}.values | jq .\"${key}\")
	    echo "Lovelaces: "$lovelaces
	    # build="$lovelaces $build"
	fi
        # echo $(cat ${TXID0}.values | jq -c keys_unsorted[]);
    done

    echo "Built output: "$build
    read REPLY

# REMOVING tmp files
rm ${TXID0}.values

echo "Enter the destination address"
read address_to
#address_to=$(cat ../forkano.addr)

echo "Using ${TXID0}, containing ${COINS_IN_INPUT} lovelace(s)"
echo "Sending from address:" $address
echo "Sending to address:" $address_to
policyid=$(cat $TOKEN_PATH/policy/policyID)

forkano-cli query protocol-parameters \
  --mainnet \
  --out-file protocol-parameters.json

fee="0"
output="0"
echo "How many CAP © would you transfer with your tokens? (Recommended 100, you need to write 100 plus 6 (six) zeroes)"
read FUNDS

echo "
forkano-cli transaction build-raw \
 --fee $fee \
 --tx-in $TXID0 \
 --tx-out $address_to+${FUNDS}+"${TOKEN1_AMOUNT} $policyid.$token1name + ${TOKEN2_AMOUNT} $policyid.$token2name" \
 --tx-out $address+$output"$build" \
 --mint "${TOKEN1_AMOUNT} $policyid.$token2name + ${TOKEN2_AMOUNT} $policyid.$token2name" \
 --minting-script-file $TOKEN_PATH/policy/policy.script \
 --out-file matx.raw
"
fee=$(forkano-cli transaction calculate-min-fee --tx-body-file matx.raw --tx-in-count 1 --tx-out-count 2 --witness-count 25 $testnet --protocol-params-file protocol-parameters.json | cut -d " " -f1)
#funds=$COINS_IN_INPUT
change=$(expr $COINS_IN_INPUT - ${FUNDS} - $fee)

echo "Calculated fee:" $fee
#output=$(expr $funds - $fee)
#echo $address${FUNDS}+"${TOKEN1_AMOUNT} $policyid.$token1name + ${TOKEN2_AMOUNT} $policyid.$token2name"

echo "Sending tokens to address:" $address_to

echo ""
echo "COINS: ${COINS_IN_INPUT}"
echo "FUNDS: ${FUNDS}"
echo "FEE: ${fee}"
echo "CHANGE: ${change}"
echo "Total: $(expr ${change} + ${fee} + ${FUNDS})"

# I don't remember why this formula
# --tx-out $address_to+$funds+"$(expr $tokenamount - 0) $policyid.$tokenname1 + $(expr $tokenamount - 0) $policyid.$tokenname2" \
# --mint "$tokenamount $policyid.$tokenname1 + $tokenamount $policyid.$tokenname2" \

forkano-cli transaction build-raw \
 --fee $fee \
 --tx-in $TXID0 \
 --tx-out $address+$change"$build" \
 --tx-out $address_to+${FUNDS}+"${TOKEN1_AMOUNT} $policyid.$token1name + ${TOKEN2_AMOUNT} $policyid.$token2name" \
 --mint "${TOKEN1_AMOUNT} $policyid.$token1name + ${TOKEN2_AMOUNT} $policyid.$token2name" \
 --minting-script-file $TOKEN_PATH/policy/policy.script \
 --out-file matx.raw

forkano-cli transaction sign  \
    --signing-key-file ${TOKEN_PATH}/policy/policy.skey \
    --signing-key-file ${KEY_DIR}/payment${ID}.skey \
    $testnet --tx-body-file matx.raw  \
    --out-file matx.signed

# REMOVING tmp files
rm matx.raw
rm txs.details

echo "PRESS ENTER TO MINT THE TOKENS"
read REPLY

echo "SURE? ENTER AGAIN!"
read REPLY

# Submit TX
forkano-cli transaction submit --tx-file matx.signed $testnet

# REMOVING tmp files
rm matx.signed
