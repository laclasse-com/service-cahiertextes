#!/bin/sh

DBNAME=${DBNAME:-cahierdetextes}
DBUSER=${DBUSER:-$DBNAME}
DBPASSWORD=${DBPASSWORD:-}
FILENAME=${DBNAME}_$(date +%F).sql

cat config/database.rb

sudo service laclasse-cahiertextes stop

mysqldump --add-drop-table -u ${DBUSER} -p${DBPASSWORD} ${DBNAME} > $FILENAME
cp ${FILENAME} ${FILENAME}.orig
sed -i 's|CHARSET=latin1|CHARSET=utf8mb4|g' $FILENAME
cat $FILENAME | iconv -f latin1 -t utf8 > ${FILENAME}.utf8mb4
echo "drop database ${DBNAME}; create database ${DBNAME};" | mysql -u ${DBUSER} -p${DBPASSWORD}
mysql -u ${DBUSER} -p${DBPASSWORD} ${DBNAME} < $FILENAME.utf8mb4

sudo service laclasse-cahiertextes start
