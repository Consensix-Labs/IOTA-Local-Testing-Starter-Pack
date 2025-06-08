#!/bin/bash

set -e

mkdir -p /tmp/iota
cd /tmp/iota
rm -rf *

iota genesis-ceremony init

for i in {1..2}; do
    iota genesis-ceremony add-validator \
        --name "iota-validator-node-$i" \
        --authority-key-file "/opt/iota/iota-validator-node-$i/keys/authority.key" \
        --protocol-key-file "/opt/iota/iota-validator-node-$i/keys/protocol.key" \
        --account-key-file "/opt/iota/iota-validator-node-$i/keys/account.key" \
        --network-key-file "/opt/iota/iota-validator-node-$i/keys/network.key" \
        --network-address "/dns/iota-validator-node-$i/tcp/8080/http" \
        --p2p-address "/dns/iota-validator-node-$i/udp/8084" \
        --primary-address "/dns/iota-validator-node-$i/udp/8090"
done

iota genesis-ceremony init-token-distribution-schedule \
    --token-allocations-path "/opt/iota/iota-tools/token-allocations.csv"

iota genesis-ceremony build-unsigned-checkpoint

for i in {1..2}; do
    iota genesis-ceremony verify-and-sign \
        --key-file "/opt/iota/iota-validator-node-$i/keys/authority.key"
done

iota genesis-ceremony finalize
