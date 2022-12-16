CONTAINER_NAME=forkano_node_test
PORT=3004
LOCAL_DIR=$(pwd)
DATA_DIR="${LOCAL_DIR}/../data"
VOLUME_INIT=--volume=${LOCAL_DIR}:/home/forkano/forkano_init
VOLUME_DATA=--volume=${DATA_DIR}:/home/forkano/git/forkano-babbage
USER=forkano

docker container stop ${CONTAINER_NAME}
docker container rm ${CONTAINER_NAME}

docker run --user ${USER} \
--name=${CONTAINER_NAME} ${VOLUME_INIT} ${VOLUME_DATA} \
-p ${PORT}:${PORT} \
-it forkano/forkano_node:latest