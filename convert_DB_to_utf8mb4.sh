#!/bin/sh

cat config/database.rb

FILENAME=cahierdetextes_$(date+%F).sql

mysqldump --add-drop-table -u cahierdetextes -p cahierdetextes > $FILENAME
cp ${FILENAME} ${FILENAME}.orig
sed -i 's|CHARSET=latin1|CHARSET=utf8mb4|g' $FILENAME
cat $FILENAME | iconv -f latin1 -t utf8 > ${FILENAME}.utf8mb4
mysql -u cahierdetextes -p cahierdetextes < $FILENAME.utf8mb4
