#!/usr/bin/env bash
set -euo pipefail

BACKEND_DIR="bootstrap"
TFVARS_FILE="terraform.tfvars"

echo "[*] Changing to bootstrap directory: ${BACKEND_DIR}"
cd "$BACKEND_DIR" || exit 1

# 1. Recuperar variables deterministas mediante el acceso OIDC
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="simpledso-infra-tfstate-${ACCOUNT_ID}"
DYNAMO_TABLE="SimpleDSo-infra-tfstate-lock"
AWS_REGION="us-east-1"

# 2. Asegurar entorno limpio
rm -f backend.tf .terraform.lock.hcl
rm -rf .terraform/

# 3. Construir cascarón para conectarse al estado actual en AWS
echo "[*] Inicializando conexión con el backend remoto en S3..."
cat <<EOF > backend.tf
terraform {
  backend "s3" {}
}
EOF

terraform init \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="key=bootstrap/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=${DYNAMO_TABLE}" \
  -backend-config="encrypt=true"

# 4. Migración Inversa (S3 -> Runner)
echo "[*] Desconectando S3 y migrando el estado a la VM local..."
rm -f backend.tf

# Al inicializar sin bloque backend, Terraform extrae el .tfstate hacia disco local
terraform init -migrate-state -force-copy

# 5. Destrucción
echo "[*] Ejecutando Terraform Destroy utilizando el estado local..."
terraform destroy -var-file="$TFVARS_FILE" -auto-approve

echo "[OK] Infraestructura base destruida con éxito. El estado efímero desaparecerá al apagarse el Runner."