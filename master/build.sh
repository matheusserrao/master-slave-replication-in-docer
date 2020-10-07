#!/bin/bash

echo 'docker-compose down...'
docker-compose down
echo 'docker-compose up -d --build'
docker-compose up -d --build

echo 'waitting...'
sleep 10

echo 'connecting mysql_master'

until docker exec mysql_master sh -c 'export MYSQL_PWD=123456; mysql -u root -e ";"'
do
    echo "Waiting for mysql_master database connection..."
    sleep 5
done

echo 'please, give us information about the mysql slave'

read -p 'user slave: ' slavevar
read -sp 'password slave: ' slavepass

#priv_stmt='GRANT REPLICATION SLAVE ON *.* TO "slave1"@"%" IDENTIFIED BY "gladyoucame"; FLUSH PRIVILEGES;'

priv_stmt='GRANT REPLICATION SLAVE ON *.* TO "'$slavevar'"@"%" IDENTIFIED BY "'$slavepass'"; FLUSH PRIVILEGES;'

docker exec mysql_master sh -c "export MYSQL_PWD=123456; mysql -u root -e '$priv_stmt'"

docker exec mysql_master sh -c 'export MYSQL_PWD=123456; mysql -u root -e "SHOW MASTER STATUS"'
