#!/bin/bash
#
# DNS Entry Checker
# Version: 1.0.0
# Author: devopsbyday1
# Created: 2025-01-01
# Updated: 2026-02-12
#
# Description:
#   Validates DNS records by comparing live DNS resolution against expected values.
#   Reads a structured input file containing hostnames and their expected IPs,
#   resolves each entry using dig, and reports matches or mismatches with
#   color-coded output. Returns a non-zero exit code if any validation fails,
#   making it suitable for use in CI/CD pipelines or automated checks.
#
# Dependencies:
#   - dig (part of the dnsutils / bind-utils package)
#
# Usage:
#   ./dns-checker.sh <dns_entries_file>
#
# Input File Format:
#   The input file uses a simple line-based format:
#   - Lines WITHOUT commas are treated as domain suffixes. All subsequent
#     hostname entries will be appended with this domain (e.g. hostname.domain).
#   - Lines WITH commas are hostname,ip pairs: hostname,expected_ip1,expected_ip2,...
#   - Use the special domain "FQDN" to indicate that hostnames are already
#     fully qualified and should not have a domain suffix appended.
#   - Empty lines are ignored.
#
# Example Input File:
#   example.com
#   web01,192.168.1.10
#   web02,192.168.1.11,192.168.1.12
#   internal.corp.local
#   db01,10.0.0.50
#   FQDN
#   cdn.provider.net,203.0.113.5
#
# Examples:
#   ./dns-checker.sh dns-entries.txt          # Validate all entries in the file
#   ./dns-checker.sh dns-entries.txt && echo "All OK"  # Use exit code in scripts
#
# Installation:
#   1. Save this file as dns-checker.sh
#   2. Make executable: chmod +x dns-checker.sh
#   3. Optional: move to a directory in your PATH to use from anywhere
#      Example: sudo cp dns-checker.sh /usr/local/bin/dns-checker
#

# Validate that exactly one argument (the input file) was provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <dns_entries_file>"
    exit 1
fi

input_file="$1"
current_domain=""   # Tracks the active domain suffix for subsequent entries
exit_status=0       # Tracks overall pass/fail; set to 1 on any failure

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to validate a single DNS entry
# Resolves the FQDN with dig and compares against the expected IP.
# Arguments:
#   $1 - hostname (used for display purposes)
#   $2 - expected IP address
#   $3 - fully qualified domain name to resolve
# Returns:
#   0 if resolved IP matches expected, 1 otherwise
validate_dns() {
    local hostname=$1
    local expected_ip=$2
    local fqdn=$3

    # Resolve the FQDN using dig (+short returns just the IP)
    resolved_ip=$(dig +short "$fqdn")

    if [ -z "$resolved_ip" ]; then
        echo -e "${RED}ERROR: No DNS resolution for $fqdn${NC}"
        return 1
    elif [[ "$resolved_ip" == *"$expected_ip"* ]]; then
        echo -e "${GREEN}✓ $fqdn resolved to $resolved_ip (matches expected $expected_ip)${NC}"
        return 0
    else
        echo -e "${RED}✗ $fqdn resolved to $resolved_ip (expected $expected_ip)${NC}"
        return 1
    fi
}

# Process the input file line by line
# The '|| [ -n "$line" ]' ensures the last line is read even without a trailing newline
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines
    [ -z "$line" ] && continue

    # Lines without commas are domain suffixes (section headers)
    if [[ $line != *","* ]]; then
        current_domain="$line"
        echo -e "\n${BLUE}=== Checking entries for domain: $current_domain ===${NC}"
        continue
    fi

    # Parse CSV: first field is the hostname, remaining fields are expected IPs
    hostname=$(echo "$line" | cut -d',' -f1)
    IFS=',' read -ra ips <<< "$(echo "$line" | cut -d',' -f2-)"

    # Build the FQDN: if the domain is "FQDN", use the hostname as-is
    if [ "$current_domain" = "FQDN" ]; then
        fqdn="${hostname}"
    else
        fqdn="${hostname}.${current_domain}"
    fi

    # Validate each expected IP for this hostname
    for ip in "${ips[@]}"; do
        if ! validate_dns "$hostname" "$ip" "$fqdn"; then
            exit_status=1
        fi
    done
done < "$input_file"

# Print summary
if [ $exit_status -eq 0 ]; then
    echo -e "\n${GREEN}All DNS validations passed successfully${NC}"
else
    echo -e "\n${RED}Some DNS validations failed${NC}"
fi

exit $exit_status
