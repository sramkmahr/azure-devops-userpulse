#!/bin/bash

set -e

# ----------------------------
# CONFIG VARIABLES
# ----------------------------
RESOURCE_GROUP="az-rg"
VM_NAME="userpulse-test-vm"
DISK_NAME="${VM_NAME}-logdisk"
DISK_SIZE_GB=10
MOUNT_POINT="/mnt/logs"
ADMIN_USERNAME="azureuser"
LOCATION="centralindia"

# ----------------------------
# CREATE MANAGED DISK
# ----------------------------
echo "📦 Creating $DISK_SIZE_GB GB data disk: $DISK_NAME"
az disk create \
  --resource-group $RESOURCE_GROUP \
  --name $DISK_NAME \
  --size-gb $DISK_SIZE_GB \
  --location $LOCATION \
  --sku Standard_LRS

# ----------------------------
# ATTACH DISK TO VM
# ----------------------------
echo "🔗 Attaching disk to $VM_NAME"
az vm disk attach \
  --resource-group $RESOURCE_GROUP \
  --vm-name $VM_NAME \
  --name $DISK_NAME

# ----------------------------
# GET PUBLIC IP OF VM
# ----------------------------
IP=$(az vm show \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --show-details \
  --query publicIps -o tsv)

echo "🌐 VM Public IP: $IP"

echo "📝 Disk attached successfully, but formatting and mounting will be done manually inside the VM for this project."

