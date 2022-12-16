CONTAINER_NAME=forkano_node_test
PORT=3004
LOCAL_DIR=$(pwd)
DATA_DIR="${LOCAL_DIR}/../data"
VOLUME_INIT=--volume=${LOCAL_DIR}:/home/forkano/forkano_init
VOLUME_DATA=--volume=${DATA_DIR}:/home/forkano/git/forkano-babbage
USER=forkano

docker exec --user ${USER} -it ${CONTAINER_NAME} bash