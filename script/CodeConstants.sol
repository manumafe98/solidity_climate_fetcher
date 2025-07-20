// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract CodeConstants {
    address public constant SEPOLIA_ROUTER =
        0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;

    bytes32 public constant SEPOLIA_DON_ID =
        0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    uint32 public constant GAS_LIMIT = 300000;
    uint64 public constant CHAINLINK_FUNCTIONS_SUBSCRIPTION_ID = 5326;

    bytes public constant ENCRYPTED_SECRET = hex"c746ba3955c8a0b8d5c69f17bdd461cb03fc21c334860e07590790786cd9c297d57141ac6215ea9b7626d8372ea34f5878cd841cf3aae234f2c94f287832de1497b814faaeb95e901fea57b971d792a7c06604e5362a2d02c092ca7f92f46dd331f3de33f6829411996e449b6e441d8e4a6f26e60d08fe00a38fe53ef86ac3d360ae0790c6eca6e7f48c5fe4252f1c843fd66d56dd7ca538a734b6e526d37fa5cc";

    uint256 public constant INTERVAL = 60 * 60 * 24;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}
