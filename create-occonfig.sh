# Update these to match your environment.
# Replace TOKEN_INDEX with the correct value
# from the output in the previous step. If you
# didn't change anything else above, don't change
# anything else here.

SERVICE_ACCOUNT_NAME=astracontrol-service-account
NAMESPACE=default
NEW_CONTEXT=astracontrol
OCCONFIG_FILE='occonfig-sa'

CONTEXT=$(oc config current-context)

SECRET_NAME=$(oc get serviceaccount ${SERVICE_ACCOUNT_NAME} \
  --context ${CONTEXT} \
  --namespace ${NAMESPACE} \
  -o jsonpath='{.secrets[TOKEN_INDEX].name}')
TOKEN_DATA=$(oc get secret ${SECRET_NAME} \
  --context ${CONTEXT} \
  --namespace ${NAMESPACE} \
  -o jsonpath='{.data.token}')

TOKEN=$(echo ${TOKEN_DATA} | base64 -d)

# Create dedicated occonfig
# Create a full copy
oc config view --raw > ${OCCONFIG_FILE}.full.tmp

# Switch working context to correct context
oc --config ${OCCONFIG_FILE}.full.tmp config use-context ${CONTEXT}

# Minify
oc --config ${OCCONFIG_FILE}.full.tmp \
  config view --flatten --minify > ${OCCONFIG_FILE}.tmp

# Rename context
oc config --config ${OCCONFIG_FILE}.tmp \
  rename-context ${CONTEXT} ${NEW_CONTEXT}

# Create token user
oc config --config ${OCCONFIG_FILE}.tmp \
  set-credentials ${CONTEXT}-${NAMESPACE}-token-user \
  --token ${TOKEN}

# Set context to use token user
oc config --config ${OCCONFIG_FILE}.tmp \
  set-context ${NEW_CONTEXT} --user ${CONTEXT}-${NAMESPACE}-token-user

# Set context to correct namespace
oc config --config ${OCCONFIG_FILE}.tmp \
  set-context ${NEW_CONTEXT} --namespace ${NAMESPACE}

# Flatten/minify occonfig
oc config --onfig ${OCCONFIG_FILE}.tmp \
  view --flatten --minify > ${OCCONFIG_FILE}

# Remove tmp
rm ${OCCONFIG_FILE}.full.tmp
rm ${OCCONFIG_FILE}.tmp