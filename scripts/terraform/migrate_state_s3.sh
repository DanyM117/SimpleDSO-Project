#!/usr/bin/env bash
set -euo pipefail

BACKEND_DIR="bootstrap"
TFVARS_FILE="terraform.tfvars"

echo "[*] Changing to bootstrap migration directory: ${BACKEND_DIR}"
[[ ! -d "$BACKEND_DIR" ]] && { echo "[X] Backend directory not found in root repo directory [X] : " ; realpath "$BACKEND_DIR"; exit 1 ; }

if ! cd "$BACKEND_DIR" ; then
    echo "[X] Unknown error changing to ${BACKEND_DIR}"
    exit 1
fi

# 1. Asegurar un entorno completamente limpio antes de operar
rm -f backend.tf .terraform.lock.hcl
rm -rf .terraform/

echo "[*] Initializing terraform with local backend"
# Se remueve -backend=false, permitiendo el uso normal del estado local en disco
if ! terraform init; then
    echo "[X] Unexpected error while initializing terraform"
    exit 1    
fi

echo "[*] PASS [*]"
echo "[*] Creating bucket s3 and DynamoDb table... [*] "
if ! terraform apply -var-file="$TFVARS_FILE" -auto-approve; then
    echo "[X] Unexpected error creating infrastructure"
    exit 1
fi

# 2. Extracción de variables dinámicas post-creación
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
DYNAMO_TABLE=$(terraform output -raw dynamodb_table_name)
AWS_REGION=$(terraform output -raw aws_region)

echo "[*] Created infra -> REGION: ${AWS_REGION}, BUCKET: ${BUCKET_NAME}, DYNAMODB TABLE: ${DYNAMO_TABLE}"

# 3. Creación del cascarón estructural HCL requerido por Terraform
echo "[*] Inyectando bloque HCL backend 's3'..."
cat <<EOF > backend.tf
terraform {
  backend "s3" {}
}
EOF

echo "[*] Migrating actual state to AWS"

# 4. Migración inyectando variables directamente al bloque recién creado
if ! terraform init -migrate-state -force-copy \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="key=bootstrap/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=${DYNAMO_TABLE}" \
  -backend-config="encrypt=true"; then
    
    echo "[X] Critical error migrating state to S3."
    exit 1
fi

echo "[OK] Migración exitosa. Estado de bootstrap centralizado."