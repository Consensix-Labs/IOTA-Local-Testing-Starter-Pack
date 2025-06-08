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
