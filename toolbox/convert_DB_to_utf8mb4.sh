#!/bin/sh

DBNAME=${DBNAME:-cahierdetextes}
DBUSER=${DBUSER:-$DBNAME}
DBPASSWORD=${DBPASSWORD:-}
FILENAME=${DBNAME}_$(date +%F).sql

cat config/database.rb

echo "sudo service laclasse-cahiertextes stop"
sudo service laclasse-cahiertextes stop

echo "mysqldump --add-drop-table -u ${DBUSER} -p${DBPASSWORD} ${DBNAME} > $FILENAME"
mysqldump --add-drop-table -u ${DBUSER} -p${DBPASSWORD} ${DBNAME} > $FILENAME

echo "cp ${FILENAME} ${FILENAME}.orig"
cp ${FILENAME} ${FILENAME}.orig

echo "sed -i 's|CHARSET=latin1|CHARSET=utf8mb4|g' $FILENAME"
sed -i 's|CHARSET=latin1|CHARSET=utf8mb4|g' $FILENAME

echo "cat $FILENAME | iconv -f latin1 -t utf8 > ${FILENAME}.utf8mb4"
cat $FILENAME | iconv -f latin1 -t utf8 > ${FILENAME}.utf8mb4

echo "echo \"drop database ${DBNAME}; create database ${DBNAME};\" | mysql -u ${DBUSER} -p${DBPASSWORD}"
echo "drop database ${DBNAME}; create database ${DBNAME};" | mysql -u ${DBUSER} -p${DBPASSWORD}

echo "mysql -u ${DBUSER} -p${DBPASSWORD} ${DBNAME} < $FILENAME.utf8mb4"
mysql -u ${DBUSER} -p${DBPASSWORD} ${DBNAME} < $FILENAME.utf8mb4

echo "sudo service laclasse-cahiertextes start"
sudo service laclasse-cahiertextes start
