#!/bin/bash 
source common_vars.sh

# Ask user for language selection
echo "Please select a language/Por favor elija el idioma:"
echo "1. English"
echo "2. Español"
read -p "Enter your choice (1 or 2): " choice

# Set language based on user input
if [ $choice -eq 1 ]; then
    LANGUAGE="en"
elif [ $choice -eq 2 ]; then
    LANGUAGE="es"
else
    echo "Invalid choice. Please enter 1 or 2."
    exit 1
fi

# Load messages from dictionary file based on language 
if [ "$LANGUAGE" == "es" ]; then
    source dictionary_es.txt
elif [ "$LANGUAGE" == "en" ]; then
    source dictionary_en.txt
else
    echo "Invalid language. Please specify 'en' or 'es'"
    exit 1
fi

echo -e "\033[1;35m################## $FIRST_TIME_WARNING ##################\033[0m"
echo -e "\033[1;35m$FIRST_TIME_INFO\033[0m"
echo ""
echo ""
echo -e "\033[1;31m################## $IF_RUN_BEFORE_WARNING ##################\033[0m"
echo -e "\033[1;31m$IF_RUN_BEFORE_NOTICE\033[0m"
echo ""
echo ""

read -p "$CONTINUE_PROMPT" REPLY

# Exit if user did not enter 'YES'
if [ -z $REPLY ] || [[ "$REPLY" != "YES" && "$REPLY" != "SI" ]]; then
    echo -e "\033[1;33m$EXIT_MSG\033[0m"
    exit 0
fi

# Exit if data directory already exists
if [ -d ${DATA_DIR} ]; then
    echo -e "\033[1;31m$DATA_DIR_EXISTS_ERROR\033[0m"
fi

# Create data directory and set permissions
echo -e "\033[1;33m$DELETE_DATA_MSG\033[0m"
sudo rm -r ${DATA_DIR}
sudo chmod -R o+w scripts
mkdir ${DATA_DIR}
chmod 777 ${DATA_DIR}

fix_docker() {
  echo -e "\033[1;33m$FIX_DOCKER_MSG\033[0m"
  read -p "$PRESS_ENTER_PROMPT" REPLY
  sudo groupadd docker
  sudo usermod -aG docker ${USER}
  echo -e "\033[1;33m$LOGOUT_MSG\033[0m"
  exit 0
}

# Check if user has access to Docker
set +e
while true; do
  # Attempt to list containers
  docker container list > /dev/null

  # Check if the previous command failed
  if [ $? -ne 0 ]; then
    # Ask the user for some action
    echo -e "\033[1;31m$DOCKER_ACCESS_ERROR\033[0m"
    echo "$FIX_DOCKER_PROMPT"
    echo "$DONT_FIX_DOCKER_PROMPT"
    read -p "$ENTER_CHOICE_PROMPT" choice

    # Take action based on user input
    case $choice in
      1) fix_docker ;;
      2) echo -e "\033[1;33m$EXIT_MSG\033[0m"; exit 0 ;;
      *) echo -e "\033[1;31m$INVALID_CHOICE_ERROR\033[0m"
    esac
  else
    echo -e "\033[1;33m$DOCKER_ACCESSIBLE_MSG\033[0m"
    break
  fi
done
set -e

# Stop and remove previous container
set +e
docker container stop ${CONTAINER_NAME}
docker container rm ${CONTAINER_NAME}
set -e


echo "© It could take some time for the image to be downloaded, please be patient :)"


# Run new container
echo -e "\033[1;33m$DOWNLOAD_IMAGE_MSG\033[0m"
docker run --user ${DOCKER_USER} \
--name=${CONTAINER_NAME} ${VOLUME_INIT} ${VOLUME_DATA} \
-p ${PORT}:${PORT} \
-it forkano/forkano_node:latest bash -c ' cd ~ ; /home/forkano/forkano_init/scripts/01-pools/00-create-new-pool.sh '

# Check if container started successfully
set +e
docker container list | grep ${CONTAINER_NAME} > /dev/null
if [ $? -ne 0 ]; then
    echo -e "\033[1;31m$CONTAINER_START_ERROR\033[0m"
    exit 1
fi
set -e

echo -e "\033[1;33m$CONTAINER_STARTED_MSG\033[0m"