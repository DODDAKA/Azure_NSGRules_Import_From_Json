#!/bin/bash

source ./Azure_NSG_Import_Var.sh

# === Azure login if needed ===
az account set --subscription "$SUBSCRIPTION_ID"

# Create the Resource group if not exists
az group show --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1 || \
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --tags "$tag1" "$tag2" "$tag3"

# Create the NSG if not exists
az network nsg show --resource-group "$RESOURCE_GROUP" --name "$NSG_NAME" >/dev/null 2>&1 || \
az network nsg create --resource-group "$RESOURCE_GROUP" --name "$NSG_NAME" --location "$LOCATION" --tags "$tag1" "$tag2" "$tag3" "$tag4"

jq -c '.rules[]' "$FILE" | while read -r rule; do
  rule_name=$(echo "$rule" | jq -r '.name')
  priority=$(echo "$rule" | jq -r '.priority')
  direction=$(echo "$rule" | jq -r '.direction')
  access=$(echo "$rule" | jq -r '.access')
  protocol=$(echo "$rule" | jq -r '.protocol')
  source_port_range=$(echo "$rule" | jq -r '.source_port_range')
  destination_port_range=$(echo "$rule" | jq -r '.destination_port_range')
  source_address_prefix=$(echo "$rule" | jq -r '.source_address_prefix')
  destination_address_prefix=$(echo "$rule" | jq -r '.destination_address_prefix')
  description=$(echo "$rule" | jq -r '.description')

  echo "Creating rule $rule_name"

  # Check if source_address_prefix contains multiple IPs (comma-separated)
  if [[ "$source_address_prefix" =~ , ]]; then
    # For multiple IPs, use --source-address-prefixes and split by comma
    az network nsg rule create \
      --resource-group "$RESOURCE_GROUP" \
      --nsg-name "$NSG_NAME" \
      --name "$rule_name" \
      --protocol "$protocol" \
      --direction "$direction" \
      --priority "$priority" \
      --access "$access" \
      --source-address-prefixes $(echo "$source_address_prefix" | tr ',' ' ') \
      --source-port-range "$source_port_range" \
      --destination-address-prefix "$destination_address_prefix" \
      --destination-port-range "$destination_port_range" \
      --description "$description"
  else
    # For single IP, use --source-address-prefix
    az network nsg rule create \
      --resource-group "$RESOURCE_GROUP" \
      --nsg-name "$NSG_NAME" \
      --name "$rule_name" \
      --protocol "$protocol" \
      --direction "$direction" \
      --priority "$priority" \
      --access "$access" \
      --source-address-prefix "$source_address_prefix" \
      --source-port-range "$source_port_range" \
      --destination-address-prefix "$destination_address_prefix" \
      --destination-port-range "$destination_port_range" \
      --description "$description"
  fi
done
