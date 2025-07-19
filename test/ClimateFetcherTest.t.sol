// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ClimateFetcher} from "../src/ClimateFetcher.sol";
import {DeployClimateFetcher} from "../script/DeployClimateFetcher.s.sol";
import {CodeConstants} from "../script/CodeConstants.sol";

contract ClimateFetcherTest is Test, CodeConstants {
    DeployClimateFetcher deployer;
    ClimateFetcher climateFetcher;

    modifier skipWhenSepolia() {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            return;
        }
        _;
    }

    modifier skipWhenLocal() {
        if (block.chainid == LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }    

    function setUp() public {
        deployer = new DeployClimateFetcher();
        climateFetcher = deployer.run();
    }

    function testRouterIsMockWhenLocal() public view skipWhenSepolia {
        assertNotEq(climateFetcher.getRouter(), SEPOLIA_ROUTER);
    }

    function testIsSepoliaRouter() public view skipWhenLocal {
        assertEq(climateFetcher.getRouter(), SEPOLIA_ROUTER);
    }
}
