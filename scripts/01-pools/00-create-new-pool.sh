#!/usr/bin/env bash

#echo "The script you are running has basename $( basename -- "$0"; ), dirname $( dirname -- "$0"; )";
#exit 0
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
# CHANGE THIS!!!
POOL_RELAY_IPV4="127.0.0.1"
#POOL_RELAY_IPV4="your.pool.ip"

a0_create_directories() {
set +e
  rm -r ${NODE_DIR}
set -e
  mkdir ${KEY_DIR} -p
  mkdir ${ADDR_DIR} -p
  mkdir ${COLD_KEY_DIR} -p
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
        --out-file ${ADDR_DIR}/payment${ID}.addr

  # Stake addresses
  forkano-cli stake-address build \
        --stake-verification-key-file ${STAKE_KEY}.vkey \
        --mainnet \
        --out-file ${ADDR_DIR}/staking${ID}.addr

  # Stake addresses registration certs
  forkano-cli stake-address registration-certificate \
        --stake-verification-key-file ${STAKE_KEY}.vkey \
        --out-file ${ADDR_DIR}/staking${ID}.reg.cert

  # Generate Cold Keys and a Cold_counter
  forkano-cli node key-gen \
	--cold-verification-key-file ${COLD_KEY_DIR}/cold${ID}.vkey \
	--cold-signing-key-file ${COLD_KEY_DIR}/cold${ID}.skey \
	--operational-certificate-issue-counter-file ${NODE_DIR}/opcert.counter

  # Create delegation certificate
  forkano-cli stake-address delegation-certificate \
      --stake-verification-key-file ${STAKE_KEY}.vkey \
      --cold-verification-key-file  ${COLD_KEY_DIR}/cold${ID}.vkey \
      --out-file ${ADDR_DIR}/staking${ID}.deleg.cert

  # Generate VRF Key pair
  forkano-cli node key-gen-VRF \
	--verification-key-file ${KEY_DIR}/vrf${ID}.vkey \
	--signing-key-file ${KEY_DIR}/vrf${ID}.skey

  # Generate the KES Key pair
  forkano-cli node key-gen-KES \
	--verification-key-file ${KEY_DIR}/kes${ID}.vkey \
	--signing-key-file ${KEY_DIR}/kes${ID}.skey
}

a7_create_topology_files() {
  # Create topology files

  cat > "${NODE_DIR}/topology.json" <<EOF
  {
    "Producers": [
      {
        "addr": "${FORKANO_NET_URL}",
        "port": 3001,
        "valency": 1
      },
      {
        "addr": "${FORKANO_NET_URL}",
        "port": 3002,
        "valency": 1
      },
      {
        "addr": "${FORKANO_NET_URL}",
        "port": 3003,
        "valency": 1
      }
    ]
  }
EOF

  (
    echo "#!/usr/bin/env bash"
    echo ""
    echo "forkano-node run \\"
    echo "  --config                          '${NODE_DIR}/extra/configuration.yaml' \\"
    echo "  --topology                        '${NODE_DIR}/topology.json' \\"
    echo "  --database-path                   '${NODE_DIR}/db' \\"
    echo "  --socket-path                     '$(sprocket "${NODE_DIR}/node.sock")' \\"
#    echo "  --shelley-kes-key                 '${KEY_DIR}/kes${ID}.skey' \\"
#    echo "  --shelley-vrf-key                 '${KEY_DIR}/vrf${ID}.skey' \\"
#    echo "  --shelley-operational-certificate '${NODE_DIR}/opcert.cert' \\"
    echo "  --port                             '${PORT}'"
  ) > "${NODE_DIR}.sh"

  chmod a+x "${NODE_DIR}.sh"

  echo "${NODE_DIR}.sh Created!"

}

a8_copy_files() {
  mkdir ${NODE_DIR}/extra -p

  SCRIPT_PATH=$( dirname -- "$0"; )
  NET_CONF_PATH="${SCRIPT_PATH}/../.."
  python3 -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=2)' < ${NET_CONF_PATH}/genesis/configuration.yaml > ${NODE_DIR}/extra/configuration.json
  #cp ${SCRIPT_PATH}/configuration.json ${NODE_DIR}/extra
  cp -r ${NET_CONF_PATH}/genesis ${ROOT}
  cp ${NET_CONF_PATH}/genesis/configuration.yaml ${NODE_DIR}/extra
  cp ${SCRIPT_PATH}/gLiveView/* ${NODE_DIR}/extra
  ln -s ${NODE_DIR}/node.sock ${ROOT}/main.sock 
}

a9_replace_params() {
  BASE_NODE_PORT=3000
  ORIG_EKG_PORT=12788
  ORIG_PROMETHEUS_PORT=12789
  i=${ID}
    NODE_PORT=$(expr ${BASE_NODE_PORT} + $i)
    EKG_PORT=$(expr ${ORIG_EKG_PORT} + $(expr $i \* 2))
    PROMETHEUS_PORT=$(expr ${ORIG_PROMETHEUS_PORT} + $(expr $i \* 2))
    echo "EKG port for Node" ${NODE} ":" ${EKG_PORT}
    echo "Prometheus port for Node" ${NODE}":" ${PROMETHEUS_PORT}
    $SED -i "${NODE_DIR}/extra/configuration.yaml" \
        -e 's/hasEKG: '${ORIG_EKG_PORT}'/hasEKG: '${EKG_PORT}'/' \
        -e 's/  - '${ORIG_PROMETHEUS_PORT}'/  - '${PROMETHEUS_PORT}'/' \
        -e 's*logs/mainnet.log*logs/'${NODE}'.log*' \
        -e 's*File: genesis*File: ../../genesis*'

    $SED -i "${NODE_DIR}/extra/configuration.json" \
        -e 's/"hasEKG": '${ORIG_EKG_PORT}'/"hasEKG": '${EKG_PORT}'/' \
        -e 's/'${ORIG_PROMETHEUS_PORT}'/'${PROMETHEUS_PORT}'/' \
        -e 's*logs/mainnet.log*logs/'${NODE_DIR}'.log*' \
        -e 's*File": "genesis/*File": "../../genesis/*'

    $SED -i "${NODE_DIR}/extra/env" \
        -e 's*NODE_HOME=""*NODE_HOME="'${NODE_DIR}'"*' \
        -e 's/CNODE_PORT=0000/CNODE_PORT='${NODE_PORT}'/' \
        -e 's*CONFIG="configuration.json"*CONFIG="'${NODE_DIR}'/extra/configuration.json"*' \
        -e 's/EKG_PORT=12788/EGK_PORT='${EKG_PORT}'/' \
        -e 's/PROM_PORT=12798/PROM_PORT='${PROMETHEUS_PORT}'/' \
        -e 's/#SHELLEY_TRANS_EPOCH=208/SHELLEY_TRANS_EPOCH=0/'

    #$SED -i "${NODE_DIR}.sh" \
    #    -e 's*node-mainnet/configuration.yaml*node-mainnet/'${NODE_DIR}'/extra/configuration.yaml*'
}

a0_create_directories
a1_create_keys
a7_create_topology_files
a8_copy_files
a9_replace_params

  echo "Now WE ARE STARTING THE NEW NODE!!!, PRESS ENTER TWICE to continue or CTRL+C to top this script now!"
  read REPLY
  read REPLY
  sh ${NODE_DIR}.sh

