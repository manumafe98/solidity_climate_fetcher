// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {ClimateFetcher} from "../src/ClimateFetcher.sol";

contract DeployClimateFetcher is Script {
    function run() public returns (ClimateFetcher) {
        vm.startBroadcast();

        ClimateFetcher climateFetcher = new ClimateFetcher({
            router: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0,
            donId: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000,
            gasLimit: 300000,
            subscriptionId: 5326,
            interval: 60 * 60 * 24
        });

        vm.stopBroadcast();

        return climateFetcher;
    }
}
