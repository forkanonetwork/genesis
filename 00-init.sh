CONTAINER_NAME=forkano_node_test
PORT=3005
LOCAL_DIR=$(pwd)
DATA_DIR="${LOCAL_DIR}/../data"
VOLUME_INIT=--volume=${LOCAL_DIR}:/home/forkano/forkano_init
VOLUME_DATA=--volume=${DATA_DIR}:/home/forkano/git/forkano-babbage
DOCKER_USER=forkano

echo "################## IF YOU ARE RUNNING THIS SCRIPT FOR THE FIRST TIME ##################"
echo "This script will create ${DATA_DIR} directory for persistant data from the forkano node"
echo "So you can easily play/update/delete/redownload the forkano_node docker image"
echo "and keep your node running ASAP"
echo "################## IF YOU ARE RUNNING THIS SCRIPT FOR THE FIRST TIME ##################"
echo ""
echo ""
echo ""
echo ""
echo "################## IF YOU ALREADY RUN THIS SCRIPT BEFORE ##################"
echo "Attention/Warning/Notice/Cuidado"
echo "This script will erase all data/db/pool info"
echo "If you have/had a pool running in ${DATA_DIR} and don't have a backup of your pool"
echo "you will lose all access to previous rewards and private keys!"
echo "################## IF YOU ALREADY RUN THIS SCRIPT BEFORE ##################"
echo ""
echo ""
echo ""
echo "If you want to continue then write 'YES' and press enter, otherwise just Ctrl+C or ENTER"
read REPLY

set -e

if [ -z $REPLY ]; then
    echo "Ok, see you soon!"
        exit 0
else
    if [ $REPLY == "YES" ]; then
      echo "I'll ask for superuser password ONCE for data deletion"
      set +e
      sudo rm -r ${DATA_DIR}
      set -e
      mkdir ${DATA_DIR}
      chmod 777 ${DATA_DIR}
    fi
fi 

docker container stop ${CONTAINER_NAME}
docker container rm ${CONTAINER_NAME}

docker run --user ${DOCKER_USER} \
--name=${CONTAINER_NAME} ${VOLUME_INIT} ${VOLUME_DATA} \
-p ${PORT}:${PORT} \
-it forkano/forkano_node:latest bash -c ' cd ~ ; /home/forkano/forkano_init/scripts/01-pools/00-create-new-pool.sh '
