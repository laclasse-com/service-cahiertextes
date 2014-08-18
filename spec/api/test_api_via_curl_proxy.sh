#!/bin/bash
#
# Tester l'api du cahier de textes avec curl.
#
URL_SSO="http://www.dev.laclasse.com/sso/api/v1/tickets"
URL_SSO_SRV_VALIDATE="http://www.dev.laclasse.com/sso/serviceValidate"
URL_CT="http%3A%2F%2Fwww.dev.laclasse.com%2Fct%2F"
URL_CT="http%3A%2F%2F192.168.123.2:9292%2Fct%2F"
USER="BAS14ELV11"
PWD="kreactive123"
rm -f ./cookieCT.txt

# Login au cahier de textes : Imoortant pour récupérer le cookie de session 
# de l'application cahier de textes, dans cookieCT.txt
#curl_cmd='curl --cookie-jar ./cookieCT.txt --insecure http://192.168.123.2:9292/ct/login/?restmod=Y&username=$USER&password=$PWD'
curl_cmd='curl --data "username=$USER&password=$PWD" --cookie-jar ./cookieCT.txt --insecure --location http://192.168.123.2:9292/ct/login/?restmod=Y'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

# Intérrogation de l'api cahier de textes
curl_cmd='curl --cookie ./cookieCT.txt http://192.168.123.2:9292/ct/api/v1/users/current.json'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

curl_cmd='curl --cookie ./cookieCT.txt http://192.168.123.2:9292/ct/api/v1/plages_horaires.json'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

curl_cmd='curl --cookie ./cookieCT.txt http://192.168.123.2:9292/ct/api/v1/annuaire/regroupements/31499.json'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

curl_cmd='curl --cookie ./cookieCT.txt http://192.168.123.2:9292/ct/api/v1/cahiers_de_textes/regroupement/31499.json'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

