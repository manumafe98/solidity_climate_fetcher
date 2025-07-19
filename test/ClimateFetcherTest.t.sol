// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ClimateFetcher} from "../src/ClimateFetcher.sol";
import {DeployClimateFetcher} from "../script/DeployClimateFetcher.s.sol";
import {CodeConstants} from "../script/CodeConstants.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract ClimateFetcherTest is Test, CodeConstants {
    DeployClimateFetcher deployer;
    ClimateFetcher climateFetcher;
    MockOracle mockOracle;
    HelperConfig.NetworkConfig config;

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
        (climateFetcher, config) = deployer.run();
        mockOracle = MockOracle(config.router);
    }

    function testRouterIsMockWhenLocal() public view skipWhenSepolia {
        assertNotEq(climateFetcher.getRouter(), SEPOLIA_ROUTER);
    }

    function testIsSepoliaRouter() public view skipWhenLocal {
        assertEq(climateFetcher.getRouter(), SEPOLIA_ROUTER);
    }

    function testFulfillSetsResult() public skipWhenSepolia {
        string[] memory args = new string[](1);
        args[0] = "Buenos Aires";

        vm.prank(climateFetcher.owner());
        bytes32 requestId = climateFetcher.sendRequest(args);

        string memory expectedResult = "Mist";
        bytes memory response = abi.encode(expectedResult);
        bytes memory err = "";

        mockOracle.fulfillRequest(requestId, response, err);

        assertEq(climateFetcher.getWeather(), expectedResult);
        assertEq(climateFetcher.getLastResponse(), response);
        assertEq(climateFetcher.getLastError(), err);

        MockOracle.Request memory request = mockOracle.getRequest(requestId);
        assertTrue(request.fulfilled);
    }
}
