#!/bin/bash

# Exit if any command fails
set -e

# Load secret blob SAS URL
SCRIPT_URL="$SCRIPT_URL"
# ----------------------------
# CONFIG VARIABLES
# ----------------------------
RESOURCE_GROUP="az-rg"
VM_NAME="userpulse-test-vm"
LOCATION="centralindia"
ADMIN_USERNAME="azureuser"
VM_SIZE="Standard_B1s"
IMAGE="Ubuntu2204"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"

VNET_NAME="${VM_NAME}-vnet"
SUBNET_NAME="${VM_NAME}-subnet"
NSG_NAME="${VM_NAME}-nsg"
NIC_NAME="${VM_NAME}-nic"
IP_NAME="${VM_NAME}-ip"

# ----------------------------
# CREATE RESOURCE GROUP (if not exists)
# ----------------------------
echo "🔧 Creating resource group: $RESOURCE_GROUP"
az group create --name $RESOURCE_GROUP --location $LOCATION

# ----------------------------
# CREATE VNET + SUBNET
# ----------------------------
echo "🌐 Creating VNet and Subnet"
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefix 10.0.0.0/16 \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix 10.0.1.0/24 \
  --location $LOCATION

# ----------------------------
# CREATE NSG + RULES (22 and 9090 open)
# ----------------------------
echo "🔐 Creating NSG and opening ports"
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name $NSG_NAME \
  --location $LOCATION

# SSH rule
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --name AllowSSH \
  --priority 1000 \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --destination-port-range 22

# Prometheus port rule
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --name AllowPrometheus \
  --priority 1010 \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --destination-port-range 9090

# ----------------------------
# CREATE PUBLIC IP
# ----------------------------
echo "🌍 Creating Public IP"
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name $IP_NAME \
  --sku Standard \
  --location $LOCATION

# ----------------------------
# CREATE NIC and attach NSG, IP, Subnet
# ----------------------------
echo "🔌 Creating NIC: $NIC_NAME"
az network nic create \
  --resource-group $RESOURCE_GROUP \
  --name $NIC_NAME \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --network-security-group $NSG_NAME \
  --public-ip-address $IP_NAME \
  --location $LOCATION

# ----------------------------
# CREATE LINUX VM
# ----------------------------
echo "🚀 Creating Linux VM: $VM_NAME"
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --location $LOCATION \
  --nics $NIC_NAME \
  --image $IMAGE \
  --size $VM_SIZE \
  --admin-username $ADMIN_USERNAME \
  --authentication-type ssh \
  --ssh-key-values $SSH_KEY_PATH \
  --public-ip-sku Standard \
  --output table

echo "✅ VM $VM_NAME created successfully!"

echo "📦 Installing app from blob inside VM..."

az vm run-command invoke \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --command-id RunShellScript \
  --scripts "curl -o /tmp/userpulse-installer.sh '$SCRIPT_URL' && chmod +x /tmp/userpulse-installer.sh && /tmp/userpulse-installer.sh"

