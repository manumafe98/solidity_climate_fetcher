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
        assertEq(climateFetcher.getRouter(), address(mockOracle));
    }

    function testIsSepoliaRouter() public view skipWhenLocal {
        assertEq(climateFetcher.getRouter(), SEPOLIA_ROUTER);
    }

    function testSendRequestCreatesValidRequest() public skipWhenSepolia {
        string[] memory args = new string[](1);
        args[0] = "Buenos Aires";

        vm.prank(climateFetcher.owner());
        bytes32 requestId = climateFetcher.sendRequest(args);

        assertTrue(mockOracle.requestExists(requestId));

        MockOracle.Request memory request = mockOracle.getRequest(requestId);
        assertEq(request.consumer, address(climateFetcher));
        assertEq(request.requestId, requestId);
        assertFalse(request.fulfilled);
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

    function testFulfillWithError() public skipWhenSepolia {
        string[] memory args = new string[](1);
        args[0] = "InvalidCity";

        vm.prank(climateFetcher.owner());
        bytes32 requestId = climateFetcher.sendRequest(args);

        bytes memory response = abi.encode("InvalidResponse");
        bytes memory err = abi.encode("404: City not found");

        mockOracle.fulfillRequest(requestId, response, err);

        assertEq(climateFetcher.getLastError(), err);
        assertEq(climateFetcher.getLastResponse(), response);
    }

    function testSendInvalidRequestIdReverts() public skipWhenSepolia {
        string[] memory args = new string[](1);
        args[0] = "Test";

        vm.prank(climateFetcher.owner());
        climateFetcher.sendRequest(args);

        bytes memory response = abi.encode("");
        bytes memory err = abi.encode("");

        vm.expectRevert(abi.encodeWithSelector(MockOracle.MockOracle__InvalidRequest.selector));
        mockOracle.fulfillRequest(bytes32(abi.encode(5)), response, err);
    }
}
