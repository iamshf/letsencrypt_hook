#!/bin/bash
_ali_api_url="https://alidns.aliyuncs.com/"
_ali_access_key_id="your access key"
_ali_access_key_secret="your access key secret"
_ali_signature_method="HMAC-SHA1"
_ali_format="JSON"
_ali_action=""
_ali_signature_version="1.0"
_ali_api_version="2015-01-09"
_ali_api_timestamp=$(date -u +"%Y-%m-%dT%TZ")
_ali_api_signature=""
_ali_api_method="GET"
_ali_api_params=""
#CERTBOT_DOMAIN=""
#CERTBOT_VALIDATION=""
#CERTBOT_AUTH_OUTPUT=""
function _urlencode() {
    local _lang=$LANG
    local _lc_collate=$LC_COLLATE
    local _length=${#1}
    LANG=C
    LC_COLLATE=C

    for (( i = 0, l = ${#1}; i < l; i++)); 
    do
        local _c=${1:i:1}
        case ${_c} in 
            [a-zA-Z0-9.~_-])
                printf "%s" ${_c}
                ;;
            *)
                printf "%%%02X" "'${_c}"
                ;;
        esac
    done

    LANG=${_lang}
    LC_COLLATE=${_lc_collate}
}
function _ali_add_record() {
    _ali_action="AddDomainRecord"
    _ali_api_method="POST"
    _ali_add_record_query

    #local _record_id=$(curl -s -X "${_ali_api_method}" "${_ali_api_url}" -d "${_ali_api_params}" | ./jq -r ".RecordId")
    local _result=$(curl -s -X "${_ali_api_method}" "${_ali_api_url}" -d "${_ali_api_params}")
    local _record_id=$(echo ${_result} | $(dirname $0)/jq -r ".RecordId")

    if [[ -n "${_record_id}" ]] && [[ "${_record_id}" != "null" ]]
    then
        printf "%s" ${_record_id}
    fi
    
    sleep 60
}
function _ali_add_record_query(){
    _ali_api_params=""
    _ali_api_params="${_ali_api_params}AccessKeyId=$(_urlencode ${_ali_access_key_id})"
    _ali_api_params="${_ali_api_params}&Action=$(_urlencode ${_ali_action})"
    _ali_api_params="${_ali_api_params}&DomainName=$(_urlencode ${CERTBOT_DOMAIN})"
    _ali_api_params="${_ali_api_params}&Format=$(_urlencode ${_ali_format})"
    _ali_api_params="${_ali_api_params}&RR=$(_urlencode "_acme-challenge")"
    _ali_api_params="${_ali_api_params}&SignatureMethod=$(_urlencode ${_ali_signature_method})"
    _ali_api_params="${_ali_api_params}&SignatureNonce=$(_urlencode $(openssl rand -hex 32))"
    _ali_api_params="${_ali_api_params}&SignatureVersion=$(_urlencode ${_ali_signature_version})"
    _ali_api_params="${_ali_api_params}&Timestamp=$(_urlencode ${_ali_api_timestamp})"
    _ali_api_params="${_ali_api_params}&Type=$(_urlencode "TXT")"
    _ali_api_params="${_ali_api_params}&Value=$(_urlencode ${CERTBOT_VALIDATION})"
    _ali_api_params="${_ali_api_params}&Version=$(_urlencode ${_ali_api_version})"

    _ali_signature

    _ali_api_params="${_ali_api_params}&Signature=$(_urlencode ${_ali_api_signature})"
}
function _ali_signature(){
    local _string_to_sign=${_ali_api_method}"&%2F&"$(_urlencode ${_ali_api_params})
    _ali_api_signature=$(echo -n ${_string_to_sign} | openssl dgst "-sha1" -hmac "${_ali_access_key_secret}&" -binary | base64)
}
function _ali_del_record(){
    _ali_action="DeleteDomainRecord"
    _ali_api_method="POST"
    local _line=""

    _ali_del_record_query
    curl -s -X "${_ali_api_method}" "${_ali_api_url}" -d "${_ali_api_params}" >/dev/null
}
function _ali_del_record_query(){
    _ali_api_params=""
    _ali_api_params="${_ali_api_params}AccessKeyId=$(_urlencode ${_ali_access_key_id})"
    _ali_api_params="${_ali_api_params}&Action=$(_urlencode ${_ali_action})"
    _ali_api_params="${_ali_api_params}&Format=$(_urlencode ${_ali_format})"
    _ali_api_params="${_ali_api_params}&RecordId=$(_urlencode ${CERTBOT_AUTH_OUTPUT})"
    _ali_api_params="${_ali_api_params}&SignatureMethod=$(_urlencode ${_ali_signature_method})"
    _ali_api_params="${_ali_api_params}&SignatureNonce=$(_urlencode $(openssl rand -hex 32))"
    _ali_api_params="${_ali_api_params}&SignatureVersion=$(_urlencode ${_ali_signature_version})"
    _ali_api_params="${_ali_api_params}&Timestamp=$(_urlencode ${_ali_api_timestamp})"
    _ali_api_params="${_ali_api_params}&Version=$(_urlencode ${_ali_api_version})"

    _ali_signature

    _ali_api_params="${_ali_api_params}&Signature=$(_urlencode ${_ali_api_signature})"
}

if [[ "${CERTBOT_AUTH_OUTPUT}" ]] && [[ -n "${CERTBOT_AUTH_OUTPUT}" ]]
then
    _ali_del_record
elif [[ "${CERTBOT_DOMAIN}" ]] && [[ -n "${CERTBOT_DOMAIN}" ]] && [[ "${CERTBOT_VALIDATION}" ]] && [[ -n "${CERTBOT_VALIDATION}" ]]
then
    _ali_add_record
else
    echo "do nothing"
fi
