// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {CodeConstants} from "./CodeConstants.sol";
import {MockOracle} from "../test/mocks/MockOracle.sol";

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address router;
        bytes32 donId;
        uint32 gasLimit;
        uint64 subscriptionId;
        bytes encryptedSecret;
        uint256 interval;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].router != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            router: SEPOLIA_ROUTER,
            donId: SEPOLIA_DON_ID,
            gasLimit: GAS_LIMIT,
            subscriptionId: CHAINLINK_FUNCTIONS_SUBSCRIPTION_ID,
            encryptedSecret: ENCRYPTED_SECRET,
            interval: INTERVAL
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.router != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        MockOracle mockOracle = new MockOracle();
        vm.stopBroadcast();

        return localNetworkConfig = NetworkConfig({
            router: address(mockOracle),
            donId: SEPOLIA_DON_ID,
            gasLimit: GAS_LIMIT,
            subscriptionId: CHAINLINK_FUNCTIONS_SUBSCRIPTION_ID,
            encryptedSecret: ENCRYPTED_SECRET,
            interval: INTERVAL
        });
    }
}
