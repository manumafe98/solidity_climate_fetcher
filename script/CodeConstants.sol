// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract CodeConstants {
    address public constant SEPOLIA_ROUTER = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 public constant SEPOLIA_DON_ID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
    uint32 public constant GAS_LIMIT = 300000;
    uint64 public constant CHAINLINK_FUNCTIONS_SUBSCRIPTION_ID = 5326;
    bytes public constant ENCRYPTED_SECRET =
        "0xc9fb4b683d80a8403592a099d5960e720324f17d26150e1d04b7cc5f57de8437c7daecf8a1b80d7bccc650e9c27d6f58ef423472d1094e5946cbc5119ac9252298904367869952e9a2fc988ed939df02984c26829ef6d38084c5c224f7225760cbc4bb4d8e65b1ba24692cff2b78b7dd6d5282dd7691fc4dfe129cbf692ad2a1f74196ff8fd83e0f6b5cf6712344615cf996bdb310ddac508944cd1fd7a9d4f4e4d48f27b4cb0415373b82ceacf245544e";
    uint256 public constant INTERVAL = 60 * 60 * 24;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}
