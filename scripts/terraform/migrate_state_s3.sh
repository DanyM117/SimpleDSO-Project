#!/usr/bin/env bash
set -euo pipefail

BACKEND_DIR="bootstrap"
TFVARS_FILE="terraform.tfvars"

echo "[*] Changing to bootstarp migration direcory: ${BACKEND_DIR}"
[[ ! -d ../../$BACKEND_DIR ]] && { echo "[X] Backend directory not found in root repo directory [X]" ; exit 1 ; }
if ! cd ../../$BACKEND_DIR ; then
    echo "[X] Unknown error changing to ${BACKEND_DIR}"
    exit 1
fi

[[ ! -f ./backend.tf ]] && { echo "[!] backend.tf fule not found. Creating..." ; touch backend.tf && echo "terraform { backend "'"s3"'" {} }" > backend.tf ; }

echo "[*] Backend found. Initializing terraform without it"
if ! terraform init -backend=false; then
    echo "[X] Unexpected error while initializing terraform"
    exit 1    
fi

echo "[*] PASS [*]"
echo "[*] Creating bucket s3 and DynamoDb table... [*] "
if ! terraform apply -var-file="$TFVARS_FILE" -auto-approve; then
    echo "[X] Unexpected error creating infraestructure"
    exit 1
fi

BUCKET_NAME=$(terraform output -raw s3_bucket_name)
DYNAMO_TABLE=$(terraform output -raw dynamodb_table_name)
AWS_REGION=$(terraform output -raw aws_region)

echo "[*] Created infra -> REGION: ${AWS_REGION}, BUCKET: ${BUCKET_NAME}, DYNAMODB TABLE: ${DYNAMO_TABLE}"

echo "[*] Migrating actual state to AWS"

terraform init -force-copy \
-backend-config="bucket=${BUCKET_NAME}" \
-backend-config="key=bootstrap/terraform.tfstate" \
-backend-config="region=${AWS_REGION}" \
-backend-config="dynamodb_table=${DYNAMO_TABLE}" \
-backend-config="encrypt=true"