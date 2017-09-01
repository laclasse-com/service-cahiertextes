#!/bin/sh

cat config/database.rb

DBNAME=${DBNAME:-cahierdetextes}

FILENAME=${DBNAME}_$(date +%F).sql

mysqldump --add-drop-table -u ${DBNAME} -p ${DBNAME} > $FILENAME
cp ${FILENAME} ${FILENAME}.orig
sed -i 's|CHARSET=latin1|CHARSET=utf8mb4|g' $FILENAME
cat $FILENAME | iconv -f latin1 -t utf8 > ${FILENAME}.utf8mb4
mysql -u ${DBNAME} -p ${DBNAME} < $FILENAME.utf8mb4
