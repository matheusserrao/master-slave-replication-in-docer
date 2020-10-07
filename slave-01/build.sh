#!/bin/bash

echo -e 'Waitting... \n'
echo -e 'Docker-down and docker-compose up -d --build \n'

docker-compose down && docker-compose up -d --build

sleep 20

docker-ip() {
    docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$@"
}

echo -e "Auto detected ip master: $(docker-ip mysql_master) \n"

echo -e "Please, give us information about the mysql [MASTER] \n"
read -p 'USER [MASTER]: ' mastervar
read -sp 'PASSWORD [MASTER]: ' masterpass

echo -e 'Connecting to slave1... \n'

until docker-compose exec mysql_slave sh -c 'export MYSQL_PWD=123456; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave database connection..."
    sleep 5
done

sleep 10

MS_STATUS=`docker exec mysql_master sh -c 'export MYSQL_PWD=123456; mysql -u root -e "SHOW MASTER STATUS"'`
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`

start_slave_stmt="CHANGE MASTER TO MASTER_HOST='$(docker-ip mysql_master)',MASTER_USER='$mastervar',MASTER_PASSWORD='$masterpass',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_slave_cmd='export MYSQL_PWD=123456; mysql -u root -e "'
start_slave_cmd+="$start_slave_stmt"
start_slave_cmd+='"'

docker exec mysql_slave sh -c "$start_slave_cmd"

docker exec mysql_slave sh -c "export MYSQL_PWD=123456; mysql -u root -e 'SHOW SLAVE STATUS \G'"
