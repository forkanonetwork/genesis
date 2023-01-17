################## IF YOU ARE RUNNING THIS SCRIPT FOR THE FIRST TIME ##################
This script will create /home/santiago/genesis/../data directory for persistant data from the forkano node
So you can easily play/update/delete/redownload the forkano_node docker image
and keep your node running ASAP
################## IF YOU ARE RUNNING THIS SCRIPT FOR THE FIRST TIME ##################




################## IF YOU ALREADY RUN THIS SCRIPT BEFORE ##################
Attention/Warning/Notice/Cuidado
This script will erase all data/db/pool info
If you have/had a pool running in /home/santiago/genesis/../data and don't have a backup of your pool
you will lose all access to previous rewards and private keys!
################## IF YOU ALREADY RUN THIS SCRIPT BEFORE ##################



If you want to continue then write YES (uppercase only) and press ENTER, otherwise just press Ctrl+C or ENTER
YES
© I'll ask for superuser password ONCE for data deletion
Docker is accessible, continuing...
^C
santiago@UBNT-TUF:~/genesis$ 




santiago@UBNT-TUF:~$ 
santiago@UBNT-TUF:~/genesis$ cat 00-init.sh 
#!/bin/bash 
source common_vars.sh

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
echo "If you want to continue then write YES (uppercase only) and press ENTER, otherwise just press Ctrl+C or ENTER"
read REPLY

set -e

if [ -z $REPLY ]; then
    echo "© Ok, see you soon!"
        exit 0
else
    if [ $REPLY == "YES" ]; then
      echo "© I'll ask for superuser password ONCE for data deletion"
      set +e
      sudo rm -r ${DATA_DIR}
      set -e
      mkdir ${DATA_DIR}
      chmod 777 ${DATA_DIR}
    else
        echo "© Oh :( I was expecting YES but I understand your choice!"
        echo "© See ya later then"
        exit 0
    fi
fi 

fix_docker() {
  echo "© I'll ask for superuser password ONCE for executing the following sentences:"
  echo "sudo groupadd docker"
  echo "sudo usermod -aG docker ${USER}"
  read -p "Press ENTER to continue" REPLY
  sudo groupadd docker
  sudo usermod -aG docker ${USER}
  echo "Now you MUST log-out and re-login, or execute \"su -s ${USER}\" and re-run this script"
  echo "Now you MUST log-out and re-login, or execute \"su -s ${USER}\" and re-run this script"
  echo "Now you MUST log-out and re-login, or execute \"su -s ${USER}\" and re-run this script"
  exit 0
}

set +e
while true; do
  # Attempt to stop the container
  docker container list > /dev/null

  # Check if the previous command failed
  if [ $? -ne 0 ]; then
    # Ask the user for some action
    echo "Error accessing docker. Do you want me to fix this?"
    echo "1. Yes (will require executing some sudo(ed) commands"
    echo "2. No (you'll have to execute \"sudo groupadd docker\" and \"sudo usermod -aG docker ${USER}\" for yourself"
    read -p "Enter your choice (1 or 2): " choice

    # Take action based on user input
    case $choice in
      1) fix_docker ;;
      2) exit 0 ;;
      *) echo "Invalid choice. Please enter 1 or 2."
    esac
  else
    echo "Docker is accessible, continuing..."
    break
  fi
done
set -e

set +e
docker container stop ${CONTAINER_NAME}
docker container rm ${CONTAINER_NAME}
set -e

echo "© It could take some time for the image to be downloaded, please be patient :)"
docker run --user ${DOCKER_USER} \
--name=${CONTAINER_NAME} ${VOLUME_INIT} ${VOLUME_DATA} \
-p ${PORT}:${PORT} \
-it forkano/forkano_node:latest bash -c ' cd ~ ; /home/forkano/forkano_init/scripts/01-pools/00-create-new-pool.sh '