#!/bin/bash

set -eux
DNS_SERVERS=$(spruce json terraform-yaml/state.yml | jq -r ".terraform_outputs.${ENVIRONMENT}_dns_public_ips[]")

for DNS_SERVER in ${DNS_SERVERS}; do
  dig . DNSKEY @8.8.8.8 | grep -Ev '^($|;)' > root.keys

  for ZONE in ${ZONES}; do
    dig +sigchase +dnssec +trusted-key=./root.keys "${ZONE}." A "@${DNS_SERVER}" \
      | grep -P "^;; VERIFYING A RRset for ${ZONE}. with DNSKEY:\d+: success$"
  done
done
