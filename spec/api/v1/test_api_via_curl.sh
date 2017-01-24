#!/bin/bash
#
# Tester l'api du cahier de textes avec curl.
#
URL_SSO="http://www.dev.laclasse.com/sso/api/tickets"
URL_SSO_SRV_VALIDATE="http://www.dev.laclasse.com/sso/serviceValidate"
URL_CT="http%3A%2F%2Fwww.dev.laclasse.com%2Fct%2F"
USER="BAS14ELV11"
PWD="kreactive123"
rm -f ./cookieCT.txt

# Poster l'authentification CAS et récupérer un TGT
curl_cmd='curl --data "username=$USER&password=$PWD" $URL_SSO'
tgt=$(eval $curl_cmd)
echo "Received TGT : "$tgt;

# Récupérer un ST
curl_cmd='curl --data-urlencode "service=$URL_CT" $URL_SSO/$tgt'
st=$(eval $curl_cmd)
echo "Received ST : "$st;

# Valider le ST et récupérer le Jeton XML CAS.
curl_cmd='curl --cookie-jar ./cookieCas.txt $URL_SSO_SRV_VALIDATE"?ticket="$st"&service="$URL_CT'
echo $URL_SSO_SRV_VALIDATE"?ticket="$st"&service="$URL_CT
xmltoken=$(eval $curl_cmd)
echo "Received XML Token : "$xmltoken;

# Login au cahier de textes : Imoortant pour récupérer le cookie de session
# de l'application cahier de textes, dans cookieCT.txt
curl_cmd='curl --cookie "CASTGC=$tgt" --cookie-jar ./cookieCT.txt --location http://www.dev.laclasse.com/ct/login --insecure'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

# Intérrogation de l'api cahier de textes
curl_cmd='curl --cookie ./cookieCT.txt http://www.dev.laclasse.com:80/ct/api/users/current.json'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

curl_cmd='curl --cookie ./cookieCT.txt http://www.dev.laclasse.com:80/ct/api/annuaire/regroupements/31499.json'
result=$(eval $curl_cmd)
echo "Received Data : "$result;

curl_cmd='curl --cookie ./cookieCT.txt http://www.dev.laclasse.com:80/ct/api/cahiers_de_textes/regroupement/31499.json'
result=$(eval $curl_cmd)
echo "Received Data : "$result;
