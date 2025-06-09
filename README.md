# IOTA Local Testing Starter Pack

This repository provides a simple setup for testing IOTA applications locally using Docker Compose services. It includes a set of IOTA nodes and a script to manage the environment.

## Setup

The setup consists of the following Docker Compose services:

- **iota-validator-node-1**
- **iota-validator-node-2** \
  Validator nodes that validate transactions and participate in consensus process.
- **iota-full-node-1**
- **iota-full-node-2** \
  Full nodes that store the complete ledger and provide access to the IOTA network.
- **iota-tools** \
  A container with the IOTA client tools for interacting with the IOTA network, such as sending transactions, checking balances, etc. Also used to perform the genesis ceremony to initialize the network.

Certain ports on the nodes are mapped to host ports to allow for external access:

- **iota-validator-node-1**
  - Guest UDP port 8084 -> UDP port **41084** (P2P gossip-like protocol)
- **iota-validator-node-2**
  - Guest UDP port 8084 -> UDP port **42084** (P2P gossip-like protocol)
- **iota-full-node-1**
  - Guest TCP port 9000 -> TCP port **43900** (JSON-RPC API)
  - Guest UDP port 8084 -> UDP port **43084** (P2P gossip-like protocol)
- **iota-full-node-2**
  - Guest TCP port 9000 -> TCP port **44900** (JSON-RPC API)
  - Guest UDP port 8084 -> UDP port **44084** (P2P gossip-like protocol)


## IOTA Accounts

There are two preconfigured IOTA test accounts, each associated with a different environment:

- `test-1-wallet-1`
  - Address: `0x6e7e7f006415396c89f30ad0482f5a580e18f23af808f3e81bb2f7185f2c0cf6`
  - Assigned to the `test-1` client environment
  - Seed: `ask hub slide fantasy shield stairs grace other myself tiny pumpkin shop`
- `test-2-wallet-1`
  - Address: `0x83c86688e0d2dbbd68dd8f3caf4634b0b0fe9d2e9229f2260ae21598683bfa67`
  - Assigned to the `test-2` client environment
  - Seed: `system section brass fence carbon tilt chunk net refuse awkward shoulder wink`

Both wallets have an initial balance of 2000.00 IOTA (2000000000000 NANOS).

In addition to these two, each node has its own account:

- **iota-validator-node-1**
  - Account address: `0xc4c48f3d9a4be46172969509bdb714a27b52de3fe0982ac0ce13d16f227c5b44`
  - Seed: `critic butter enact rebel release normal pencil vital barrel green essay milk`
- **iota-validator-node-2**
  - Account address: `0x3dbf5890902710514cd2f08d6aba75a303056660689c8586ad0ec96d4fe3658d`
  - Seed: `cause stay involve great jewel dignity blood order envelope coconut base aim`
- **iota-full-node-1**
  - Account address: `0x268d1ce051163380a5247ca102053a1dde2ff4bc4eab591dd2d7c3144982823a`
  - Seed: `screen walk useless tiny barrel water slice exclude chapter trust pink lamp`
- **iota-full-node-2**
  - Account address: `0xb86c03ae85e13c23d73d77397e2176195041242e5964234b5d5b37de69e72075`
  - Seed: `depart gadget reform siren acid arrive obvious model person stable harsh cause`

The accounts belonging to full nodes are initially allocated 5000.00 IOTA (5000000000000 NANOS) each. Validator node accounts are allocated 1500000.00 IOTA (1500000000000000 NANOS) each, and the entire balance is staked.
