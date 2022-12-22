CONTAINER_NAME=forkano_node
PORT=3004
LOCAL_DIR=$(pwd)
DATA_DIR="${LOCAL_DIR}/../data"
VOLUME_INIT=--volume=${LOCAL_DIR}:/home/forkano/forkano_init
VOLUME_DATA=--volume=${DATA_DIR}:/home/forkano/git/forkano-babbage
DOCKER_USER=forkano
