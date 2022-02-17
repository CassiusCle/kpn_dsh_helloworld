#!/bin/sh
medir=${0%/*}

############################## Functions ##############################
function section() {
  if [ -z "$QUIET_ENTRY" ]; then
	  echo -e "\n******"
    if [ $# -gt 0 ]; then
      for ar in "$@"; do
        echo "****** $ar"
      done
    else
        echo "******"
    fi
    echo -e "******\n"
  fi
}

function slash2dn() {
  reslt=""
  # change IFS to use '/' as word separator
  SAVEIFS="$IFS"
  IFS='/'
  # read components of the marathon id separated by '/' as words
  for part in $(echo "$1"); do
    if [ -n "$part" ]; then
      # append non-empty words in reverse order separated by dots"
      reslt="$part.$reslt"
    fi
  done
  # restore original IFS
  IFS="$SAVEIFS"
  # print the result removing the dot at the end
  echo ${reslt%.}
}

function checkenv(){
  return_code=0
  for arg in "$@" 
  do
    var_name=`echo '\$'${arg}`
    eval [ -z "${var_name}" ]
    code=$?
    if [ $code -eq 0 ]; then
        echo "ERROR: Missing environment variable: ${arg}" && return_code=1
    fi
  done
  return $return_code
}

function checkerror(){
  code=$?
  if [ $code -ne 0 ]; then
    echo "ERROR: Exiting because the last shell command returned a non-zero exit code: $code"
    exit 1
  fi
}

############################## Main ##############################

section "Setting up DSH tenant certificates and tenant configuration for secure Kafka"

### Prerequisites ###
section "Check required environment variables provided by DSH."
checkenv KAFKA_CONFIG_HOST  DSH_SECRET_TOKEN MESOS_TASK_ID MARATHON_APP_ID DSH_CA_CERTIFICATE
checkerror
echo "KAFKA_CONFIG_HOST  : $KAFKA_CONFIG_HOST"
echo "DSH_SECRET_TOKEN   : XXXXXXXXXX${DSH_SECRET_TOKEN:10}"
echo "MESOS_TASK_ID      : $MESOS_TASK_ID"
echo "MARATHON_APP_ID    : $MARATHON_APP_ID"
echo "DSH_CA_CERTIFICATE :"
echo "$DSH_CA_CERTIFICATE"

### PKI dir ###
section "Create directory to store PKI files." 
PKI_CONFIG_DIR=/home/dsh/pki
mkdir -p $PKI_CONFIG_DIR
echo "PKI_CONFIG_DIR=$PKI_CONFIG_DIR"

### Tenant name ###
section "Determine the tenant name. It is the 1st component of MARATHON_APP_ID"
TENANT_NAME=`echo ${MARATHON_APP_ID} | cut -d / -f 2`
echo "TENANT_NAME=$TENANT_NAME"

### DNS name ###
section "Determine the host name. It is the components of MARATHON_APP_ID" "in reverse, with 'marathon.mesos' suffix"
DNS_NAME=$(slash2dn mesos/marathon/$MARATHON_APP_ID)
echo "DNS_NAME=$DNS_NAME"

### Client certificate ###
section "Store the DSH CA CERTIFICATE in ${PKI_CONFIG_DIR}/ca.crt."
echo "${DSH_CA_CERTIFICATE}" > $PKI_CONFIG_DIR/ca.crt
openssl x509 -in $PKI_CONFIG_DIR/ca.crt -text -noout

section "For our certificate, we request the subject DN from the KAFKA_CONFIG_HOST" \
        "Typically using this:" \
        'curl --cacert "$PKI_CONFIG_DIR/ca.crt" -s "https://$KAFKA_CONFIG_HOST/dn/$TENANT_NAME/$MESOS_TASK_ID"'

echo curl --cacert "$PKI_CONFIG_DIR/ca.crt" "https://$KAFKA_CONFIG_HOST/dn/$TENANT_NAME/$MESOS_TASK_ID"
DN=`curl --cacert "$PKI_CONFIG_DIR/ca.crt" "https://$KAFKA_CONFIG_HOST/dn/$TENANT_NAME/$MESOS_TASK_ID" `
checkerror
echo -e "\nDN=$DN"

section "Use OpenSSL to generate our CSR = Certificate Signing Request, which will become our x509 certificate" \
        "For this we first generate public/private key pair" \
        'openssl genrsa -out ${PKI_CONFIG_DIR}/client.key 4096' \
        'Then generate CSR itself with certificate subject name = $DN we received from KAFKA_CONFIG_HOST' \
        'but separated with "/" instead of ","' \
        'openssl req -key ${PKI_CONFIG_DIR}/client.key -new -out ${PKI_CONFIG_DIR}/client.csr -subj "/${DN//,//}"'
CERTIFICATE_SUBJECT_NAME="/${DN//,//}"
echo CERTIFICATE_SUBJECT_NAME="${CERTIFICATE_SUBJECT_NAME}"

section "Generate public/private key pair in $PKI_CONFIG_DIR/client.key"
openssl genrsa -out $PKI_CONFIG_DIR/client.key 4096
checkerror
echo "..Contents of key is not logged to standard output for security reasons."

section "Generate csr in $PKI_CONFIG_DIR/client.csr"
openssl req -key $PKI_CONFIG_DIR/client.key  -new -out $PKI_CONFIG_DIR/client.csr -subj "${CERTIFICATE_SUBJECT_NAME}"
checkerror
openssl req -in $PKI_CONFIG_DIR/client.csr -text

section "Now we HTTP POST the request to KAFKA_CONFIG_HOST for verification and signature" \
        "it responds with our newly minted x509 cert" \
        'curl --cacert ${PKI_CONFIG_DIR}/ca.crt -o ${PKI_CONFIG_DIR}/client.crt -s --data-binary @${PKI_CONFIG_DIR}/client.csr -H "X-Kafka-Config-Token: ${DSH_SECRET_TOKEN}" "https://${KAFKA_CONFIG_HOST}/sign/${TENANT_NAME}/${MESOS_TASK_ID}"'
echo curl --cacert ${PKI_CONFIG_DIR}/ca.crt -o ${PKI_CONFIG_DIR}/client.crt -s --data-binary @${PKI_CONFIG_DIR}/client.csr -H "X-Kafka-Config-Token: ${DSH_SECRET_TOKEN}" "https://${KAFKA_CONFIG_HOST}/sign/${TENANT_NAME}/${MESOS_TASK_ID}"
curl --cacert ${PKI_CONFIG_DIR}/ca.crt -o ${PKI_CONFIG_DIR}/client.crt -s --data-binary @${PKI_CONFIG_DIR}/client.csr -H "X-Kafka-Config-Token: ${DSH_SECRET_TOKEN}" "https://${KAFKA_CONFIG_HOST}/sign/${TENANT_NAME}/${MESOS_TASK_ID}"
checkerror

section "Store certificate in $PKI_CONFIG_DIR/client.crt"
openssl x509 -in $PKI_CONFIG_DIR/client.crt -text -noout

### Java keystores ###
section "Creating java style keystores. They will only be created when the 'keytool' is on the path."
if [ -x "$(command -v keytool)" ]; then
  echo "keytool is installed, continue with generating keystores."
  DSH_KEYSTORE="$PKI_CONFIG_DIR/keystore.jks"
  DSH_KEYSTORE_PASSWORD=`openssl rand -base64 32`
  DSH_TRUSTSTORE="$PKI_CONFIG_DIR/truststore.jks"
  DSH_TRUSTSTORE_PASSWORD=`openssl rand -base64 32`

  echo "Create pkcs12 from pem key file"
  openssl pkcs12 -export -out "${PKI_CONFIG_DIR}/client.key.p12" -inkey "${PKI_CONFIG_DIR}/client.key" \
  -in "${PKI_CONFIG_DIR}/client.crt" -certfile "${PKI_CONFIG_DIR}/ca.crt" -password pass:${DSH_KEYSTORE_PASSWORD}

  echo "Create keystore"
  keytool -importkeystore -deststorepass ${DSH_KEYSTORE_PASSWORD} -destkeypass ${DSH_KEYSTORE_PASSWORD} \
  -destkeystore "${DSH_KEYSTORE}" -srckeystore "${PKI_CONFIG_DIR}/client.key.p12" -srcstoretype PKCS12 \
  -srcstorepass "${DSH_KEYSTORE_PASSWORD}" -alias 1

  echo "Create truststore"
  keytool -import -alias "dsh ca" -keystore "${DSH_TRUSTSTORE}" -file "${PKI_CONFIG_DIR}/ca.crt" \
  -storepass "${DSH_TRUSTSTORE_PASSWORD}" -noprompt
else
  echo "keytool is not installed, continue without generating keystores."
fi

### Tenant configuration ###
section "Tenant configuration can be requested as follows (with proper TLS params)" \
        "3 formats are available: json, shell, and java" \
        'curl https://${KAFKA_CONFIG_HOST}/kafka/config/${TENANT_NAME}/${MESOS_TASK_ID}?format=json'

echo curl --cacert ${PKI_CONFIG_DIR}/ca.crt --key ${PKI_CONFIG_DIR}/client.key --cert ${PKI_CONFIG_DIR}/client.crt "https://${KAFKA_CONFIG_HOST}/kafka/config/${TENANT_NAME}/${MESOS_TASK_ID}?format=json"
JSON_TENANT_CONFIG=`curl --cacert ${PKI_CONFIG_DIR}/ca.crt --key ${PKI_CONFIG_DIR}/client.key --cert ${PKI_CONFIG_DIR}/client.crt "https://${KAFKA_CONFIG_HOST}/kafka/config/${TENANT_NAME}/${MESOS_TASK_ID}?format=json"`

### Export variables ###
section "Export environment variables to make them available for reuse."
export DSH_PKI_CACERT="$PKI_CONFIG_DIR/ca.crt"
export DSH_PKI_KEY="$PKI_CONFIG_DIR/client.key"
export DSH_PKI_CERT="$PKI_CONFIG_DIR/client.crt"
export TENANT_NAME
export JSON_TENANT_CONFIG
export DNS_NAME

echo DSH_PKI_CACERT="$DSH_PKI_CACERT"
echo DSH_PKI_KEY="$DSH_PKI_KEY"
echo DSH_PKI_CERT="$DSH_PKI_CERT"


[ ! -z "${DSH_KEYSTORE}" ] && export DSH_KEYSTORE && echo "DSH_KEYSTORE=${DSH_KEYSTORE}"
[ ! -z "${DSH_KEYSTORE_PASSWORD}" ] && export DSH_KEYSTORE_PASSWORD && echo "DSH_KEYSTORE_PASSWORD=XXXX"
[ ! -z "${DSH_TRUSTSTORE}" ] && export DSH_TRUSTSTORE && echo "DSH_TRUSTSTORE=${DSH_TRUSTSTORE}"
[ ! -z "${DSH_TRUSTSTORE_PASSWORD}" ] && export DSH_TRUSTSTORE_PASSWORD && echo "DSH_TRUSTSTORE_PASSWORD=XXXX"

echo TENANT_NAME="$TENANT_NAME"
echo DNS_NAME="$DNS_NAME"
echo JSON_TENANT_CONFIG="$JSON_TENANT_CONFIG"


### End ###
section "Completed setup tenant certificates and tenant configuration"
