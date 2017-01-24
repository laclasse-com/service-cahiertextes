#!/bin/bash
#
# Tester l'api du cahier de textes avec curl.
#
SERVEUR_ENT="www.dev.laclasse.com"
SERVEUR_SSO="www.dev.laclasse.com"
URL_SSO="http://$SERVEUR_SSO/sso/api/tickets"
URL_SSO_SRV_VALIDATE="http://$SERVEUR_SSO/sso/serviceValidate"
URL_CT="http://$SERVEUR_ENT/ct"
#URL_CT="http%3A%2F%2F$SERVEUR_ENT%2Fct%2F"
USER="BAS14ELV11"
PWD="kreactive123"
rm -f ./cookieCT.txt

# Login au cahier de textes : Imoortant pour récupérer le cookie de session
# de l'application cahier de textes, dans cookieCT.txt
#curl_cmd='curl --cookie-jar ./cookieCT.txt --insecure http://192.168.123.2:9292/ct/login/?restmod=Y&username=$USER&password=$PWD'
curl_cmd='curl --data "username=$USER&password=$PWD" --cookie-jar ./cookieCT.txt --insecure --location '$URL_CT'/login/?restmod=Y'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

# Intérrogation de l'api cahier de textes
curl_cmd='curl --cookie ./cookieCT.txt '$URL_CT'/api/users/current'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

curl_cmd='curl --cookie ./cookieCT.txt '$URL_CT'/api/plages_horaires'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

curl_cmd='curl --cookie ./cookieCT.txt '$URL_CT'/api/annuaire/regroupements/31499'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

curl_cmd='curl --cookie ./cookieCT.txt '$URL_CT'/api/cahiers_de_textes/regroupement/31499'
result=$(eval $curl_cmd)
echo "Received Data : "$result;
