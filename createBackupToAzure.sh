#!/bin/sh

export AZURE_STORAGE_ACCOUNT=YourAccount
export AZURE_STORAGE_KEY=19RInNKq8765CD876eA6FcA54JGYinwtWs4rkLy3wmv+EeauB==
export container_name=bckucp

URLDOCKERUCP="https://xxxxxx"
URLAZUREDESTINY="https://xxxxxx/bckdtr/dtr-metadata-backup.tar_"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

DATE=`date +%Y-%m-%d`
RETRIES=3

echo -e "${BLUE}Generando backup...${NC}"

while [[ ! -s /home/deeadmin/dtr-metadata-backup.tar_$DATE  && $RETRIES -gt 0 ]]
do
    echo 'p3M1q.J$yz@g[b' | sudo -S  docker run --log-driver none -i --rm \
        --env UCP_PASSWORD=changeme \
        docker/dtr:2.6.5 backup \
        --ucp-url $URLDOCKERUCP \
        --ucp-insecure-tls \
        --ucp-username deeadmin \
        --existing-replica-id 9a2ed22acc57 > /home/deeadmin/dtr-metadata-backup.tar_$DATE

        let RETRIES=$RETRIES-1
        [ -s /home/deeadmin/dtr-metadata-backup.tar_$DATE ] && echo -e "${GREEN}Fichero de backup generado : /home/deeadmin/dtr-metadata-backup.tar_$DATE${NC}" || sleep 5m
done

echo -e "${BLUE}Subiendo fichero al storage de Azure...${NC}"

azcopy --quiet \
    --source /home/deeadmin/dtr-metadata-backup.tar_$DATE \
    --destination $URLAZUREDESTINY$DATE \
    --dest-key $AZURE_STORAGE_KEY

PURGE_DATE=$(date -d "-15days" +%Y-%m-%d)
echo -e "${BLUE}Eliminamos los ficheros de Azure anteriores a:${NC} ${RED}$PURGE_DATE${NC}"

outputAzure=(`az storage blob list  --container-name $container_name --output table | grep dtr-metadata-backup.tar | awk '{print $6}'`)

for uploadDate in "${outputAzure[@]}"
do
        backupDate=$(echo "$uploadDate" | cut -d 'T' -f 1)

        if [ $(date -d"${PURGE_DATE}" +%s) -gt $(date -d"${backupDate}" +%s) ]
        then
          echo -e  "${BLUE}Eliminando ficheros: $backupDate${NC}"
          outputAzure=(`az storage blob delete -c $container_name  -n dtr-metadata-backup.tar_$backupDate`)
        fi
done

echo -e "${GREEN}Eliminamos los ficheros de backup de la maquina${NC}"
find /home/deeadmin/ -type f -name 'dtr-metadata-backup.tar_*' -delete

echo "${GREEN}Completado.${NC}"
