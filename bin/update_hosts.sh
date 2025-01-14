#!/usr/bin/env bash
set -e

: "${HOSTS_FILE:=/etc/hosts}"
: "${COREFILE:=services/coredns/Corefile}"
: "${MORPH_CHAIN_CONFIG:=services/morph_chain/protocol.privnet.yml}"
temp_file=$(mktemp)

# Get default hosts
make hosts > "$temp_file"

# Get the morph-chain IP address from the $COREFILE file
morph_chain_ip=$(grep "morph-chain.neofs.devenv" "$temp_file" | awk '{print $1}')

# Replace the IP address in the $COREFILE file
sed -i -E "s/(nns[[:space:]]*http\:\/\/)([0-9]{1,3}[.]){3}[0-9]{1,3}(:30333)/\1$morph_chain_ip\3/" "$COREFILE"

# Get the line numbers of "Addresses:"
addresses_lines=$(grep -n "Addresses:" "$MORPH_CHAIN_CONFIG" | cut -d ':' -f 1)

# Loop through each line number with "Addresses:"
for addresses_line in $addresses_lines; do
  # Increment the line number to find the line with the IP and port
  target_line=$((addresses_line + 1))

  # Replace the IP address in the target line in the MORPH_CHAIN_CONFIG file
  sed -i "${target_line}s/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/$morph_chain_ip/" "$MORPH_CHAIN_CONFIG"
done

while IFS=" " read -r ip domain; do
  updated=false

  # Check if the domain starts with "*", and if so, escape it for use in regex
  if [[ "${domain:0:1}" == "*" ]]; then
    domain_escaped="\\${domain}"
  else
    domain_escaped="${domain//./\\.}"
  fi

  # Check if the IP and domain pair already exists in the hosts file
  if grep -Eq "^(([0-9]{1,3}[.]){3}[0-9]{1,3})[[:space:]]+${domain_escaped}$" "$HOSTS_FILE"; then
    existing_ip=$(grep -Eo "^(([0-9]{1,3}[.]){3}[0-9]{1,3})[[:space:]]+${domain_escaped}$" "$HOSTS_FILE" | awk '{print $1}')
    
    # If the IP addresses don't match, update the entry in the hosts file
    if [[ "$existing_ip" != "$ip" ]]; then
      sed -i -r "s/(([0-9]{1,3}[.]){3}[0-9]{1,3})[[:space:]]+${domain_escaped}/$ip $domain/" "$HOSTS_FILE"
      updated=true
    fi
  else
    # If the IP and domain pair doesn't exist in the hosts file, append it
    echo "$ip $domain" >> "$HOSTS_FILE"
    echo "Added: $ip $domain"
  fi
  
  # Print an update message if an entry has been updated
  if [[ "$updated" = true ]]; then
    echo "Updated: $ip $domain"
  fi
done < "$temp_file"

rm "$temp_file"
