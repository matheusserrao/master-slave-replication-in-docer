#!/bin/bash

docker-compose down && docker-compose up -d --build

echo 'waitting...'

sleep 20

echo 'connecting mysql_master'

docker-ip() {
    docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$@"
}

#echo 'please, give us information about the mysql master'
#echo "Auto detected ip master: $(docker-ip mysql_master)"
#read -p 'user master: ' mastervar
#read -sp 'password master: ' masterpass

until docker-compose exec mysql_slave sh -c 'export MYSQL_PWD=123456; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave database connection..."
    sleep 5
done

sleep 10

MS_STATUS=`docker exec mysql_master sh -c 'export MYSQL_PWD=123456; mysql -u root -e "SHOW MASTER STATUS"'`
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`

start_slave_stmt="CHANGE MASTER TO MASTER_HOST='$(docker-ip mysql_master)',MASTER_USER='slave1',MASTER_PASSWORD='gladyoucame',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_slave_cmd='export MYSQL_PWD=123456; mysql -u root -e "'
start_slave_cmd+="$start_slave_stmt"
start_slave_cmd+='"'

docker exec mysql_slave sh -c "$start_slave_cmd"

docker exec mysql_slave sh -c "export MYSQL_PWD=123456; mysql -u root -e 'SHOW SLAVE STATUS \G'"
