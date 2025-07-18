// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/src/Test.sol";
import {ClimateFetcher} from "../src/ClimateFetcher.sol";
import {DeployClimateFetcher} from "../script/DeployClimateFetcher.s.sol";

contract ClimateFetcherTest is Test {
    DeployClimateFetcher deployer;
    ClimateFetcher climateFetcher;

    function setUp() public {
        deployer = new DeployClimateFetcher();
        climateFetcher = deployer.run();
    }
}
