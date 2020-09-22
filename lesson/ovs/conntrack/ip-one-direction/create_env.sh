#/bin/sh
CUR_DIR=`pwd`
docker run -it -d --privileged -v $CUR_DIR:/root/ovn_lab/lesson --name 'ovn_lab_lesson1' ovn_lab:v2 bash

docker exec -it ovn_lab_lesson1 start_ovs.sh
