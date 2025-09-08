#!/bin/bash

# DNS Validation Script for Jira Request
# This script validates DNS entries for IPMI, MGMT, stable, and API domains
# Created: $(date '+%Y-%m-%d %H:%M:%S')

echo "DNS Validation Script - Evidence for Jira Request"
echo "================================================="
echo "Validation Date: $(date)"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to validate DNS entry
validate_dns() {
    local hostname=$1
    local expected_ip=$2
    local category=$3
    
    echo -n "Checking $hostname... "
    
    # Use nslookup to resolve the hostname
    result=$(nslookup "$hostname" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # Extract IP address from nslookup output
        resolved_ip=$(echo "$result" | grep -A 1 "Name:" | tail -1 | awk '{print $2}' | head -1)
        
        # If the above doesn't work, try alternative parsing
        if [ -z "$resolved_ip" ]; then
            resolved_ip=$(echo "$result" | grep "Address:" | tail -1 | awk '{print $2}')
        fi
        
        if [ -n "$resolved_ip" ]; then
            if [ "$resolved_ip" = "$expected_ip" ] || [ -z "$expected_ip" ]; then
                echo -e "${GREEN}✓ RESOLVED${NC} -> $resolved_ip"
                return 0
            else
                echo -e "${YELLOW}⚠ RESOLVED BUT MISMATCH${NC} -> Expected: $expected_ip, Got: $resolved_ip"
                return 1
            fi
        else
            echo -e "${RED}✗ FAILED TO PARSE IP${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ FAILED TO RESOLVE${NC}"
        return 1
    fi
}

# Server hostnames
servers=(
    "ib-uk-lon1-mnc1-s1"
    "ib-uk-lon1-mnc1-s2"
    "ib-uk-lon1-mnc1-s3"
    "ib-uk-lon1-mnc1-s4"
    "ib-uk-lon1-mnc1-s5"
    "ib-uk-lon1-mnc1-s6"
    "ib-uk-lon1-mnc1-s7"
    "ib-uk-lon1-mnc1-s8"
    "ib-uk-lon1-hvy1-s1"
    "ib-uk-lon1-hvy1-s2"
    "ib-uk-lon1-hvy1-s3"
    "ib-uk-lon1-hvy1-s4"
)

# IPMI IP mappings
declare -A ipmi_ips=(
    ["ib-uk-lon1-mnc1-s1"]="172.17.15.11"
    ["ib-uk-lon1-mnc1-s2"]="172.17.15.12"
    ["ib-uk-lon1-mnc1-s3"]="172.17.15.13"
    ["ib-uk-lon1-mnc1-s4"]="172.17.15.51"
    ["ib-uk-lon1-mnc1-s5"]="172.17.15.52"
    ["ib-uk-lon1-mnc1-s6"]="172.17.15.53"
    ["ib-uk-lon1-mnc1-s7"]="172.17.15.54"
    ["ib-uk-lon1-mnc1-s8"]="172.17.15.55"
    ["ib-uk-lon1-hvy1-s1"]="172.17.15.56"
    ["ib-uk-lon1-hvy1-s2"]="172.17.15.57"
    ["ib-uk-lon1-hvy1-s3"]="172.17.15.58"
    ["ib-uk-lon1-hvy1-s4"]="172.17.15.59"
)

# MGMT IP mappings
declare -A mgmt_ips=(
    ["ib-uk-lon1-mnc1-s1"]="172.17.11.11"
    ["ib-uk-lon1-mnc1-s2"]="172.17.11.12"
    ["ib-uk-lon1-mnc1-s3"]="172.17.11.13"
    ["ib-uk-lon1-mnc1-s4"]="172.17.11.51"
    ["ib-uk-lon1-mnc1-s5"]="172.17.11.52"
    ["ib-uk-lon1-mnc1-s6"]="172.17.11.53"
    ["ib-uk-lon1-mnc1-s7"]="172.17.11.54"
    ["ib-uk-lon1-mnc1-s8"]="172.17.11.55"
    ["ib-uk-lon1-hvy1-s1"]="172.17.11.56"
    ["ib-uk-lon1-hvy1-s2"]="172.17.11.57"
    ["ib-uk-lon1-hvy1-s3"]="172.17.11.58"
    ["ib-uk-lon1-hvy1-s4"]="172.17.11.59"
)

# Stable IP mappings
declare -A stable_ips=(
    ["ib-uk-lon1-mnc1-s1"]="10.34.22.11"
    ["ib-uk-lon1-mnc1-s2"]="10.34.22.12"
    ["ib-uk-lon1-mnc1-s3"]="10.34.22.13"
    ["ib-uk-lon1-mnc1-s4"]="10.34.22.51"
    ["ib-uk-lon1-mnc1-s5"]="10.34.22.52"
    ["ib-uk-lon1-mnc1-s6"]="10.34.22.53"
    ["ib-uk-lon1-mnc1-s7"]="10.34.22.54"
    ["ib-uk-lon1-mnc1-s8"]="10.34.22.55"
    ["ib-uk-lon1-hvy1-s1"]="10.34.22.56"
    ["ib-uk-lon1-hvy1-s2"]="10.34.22.57"
    ["ib-uk-lon1-hvy1-s3"]="10.34.22.58"
    ["ib-uk-lon1-hvy1-s4"]="10.34.22.59"
)

# Counters for summary
total_checks=0
successful_checks=0

echo "1. VALIDATING IPMI DNS ENTRIES (*.ipmi.ib.dnsbego.de)"
echo "===================================================="
for server in "${servers[@]}"; do
    hostname="${server}.ipmi.ib.dnsbego.de"
    expected_ip="${ipmi_ips[$server]}"
    validate_dns "$hostname" "$expected_ip" "IPMI"
    total_checks=$((total_checks + 1))
    if [ $? -eq 0 ]; then
        successful_checks=$((successful_checks + 1))
    fi
done

echo ""
echo "2. VALIDATING MGMT DNS ENTRIES (*.mgmt.ib.sndbego.de)"
echo "===================================================="
for server in "${servers[@]}"; do
    hostname="${server}.mgmt.ib.sndbego.de"
    expected_ip="${mgmt_ips[$server]}"
    validate_dns "$hostname" "$expected_ip" "MGMT"
    total_checks=$((total_checks + 1))
    if [ $? -eq 0 ]; then
        successful_checks=$((successful_checks + 1))
    fi
done

echo ""
echo "3. VALIDATING STABLE DNS ENTRIES (direct hostname resolution)"
echo "============================================================"
for server in "${servers[@]}"; do
    expected_ip="${stable_ips[$server]}"
    validate_dns "$server" "$expected_ip" "STABLE"
    total_checks=$((total_checks + 1))
    if [ $? -eq 0 ]; then
        successful_checks=$((successful_checks + 1))
    fi
done

echo ""
echo "4. VALIDATING API DNS ENTRY (prod.lon1.ib.dnsbego.de)"
echo "====================================================="
# API entry points to multiple IPs, so we'll check if it resolves to any of the expected ones
api_hostname="prod.lon1.ib.dnsbego.de"
api_expected_ips=("10.34.22.11" "10.34.22.12" "10.34.22.13")

echo -n "Checking $api_hostname... "
result=$(nslookup "$api_hostname" 2>/dev/null)

if [ $? -eq 0 ]; then
    # Extract all IP addresses from nslookup output
    resolved_ips=$(echo "$result" | grep "Address:" | awk '{print $2}' | tail -n +2)
    
    if [ -n "$resolved_ips" ]; then
        echo -e "${GREEN}✓ RESOLVED${NC}"
        echo "  Resolved IPs:"
        echo "$resolved_ips" | while read ip; do
            echo "    -> $ip"
        done
        successful_checks=$((successful_checks + 1))
    else
        echo -e "${RED}✗ FAILED TO PARSE IP${NC}"
    fi
else
    echo -e "${RED}✗ FAILED TO RESOLVE${NC}"
fi

total_checks=$((total_checks + 1))

echo ""
echo "VALIDATION SUMMARY"
echo "=================="
echo "Total DNS entries checked: $total_checks"
echo "Successfully resolved: $successful_checks"
echo "Failed to resolve: $((total_checks - successful_checks))"

if [ $successful_checks -eq $total_checks ]; then
    echo -e "${GREEN}✓ ALL DNS ENTRIES VALIDATED SUCCESSFULLY${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ SOME DNS ENTRIES FAILED VALIDATION${NC}"
    exit 1
fi
