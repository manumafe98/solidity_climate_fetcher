// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {ClimateFetcher} from "../src/ClimateFetcher.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployClimateFetcher is Script {
    function run() public returns (ClimateFetcher) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        ClimateFetcher climateFetcher = new ClimateFetcher({
            router: config.router,
            donId: config.donId,
            gasLimit: config.gasLimit,
            subscriptionId: config.subscriptionId,
            encryptedSecret: config.encryptedSecret,
            interval: config.interval
        });
        vm.stopBroadcast();

        return climateFetcher;
    }
}
