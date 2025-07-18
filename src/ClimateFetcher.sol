// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

/**
 * @title Climate Fetcher Dapp.
 * @author Manuel Maxera.
 * @notice By laveraging Chainlink Functions calls openweathermap Api to get the city current weather.
 * @notice By laveraginh Chainlink Automation we schedule calls to the openweathermap Api with Buenos Aires as default city.
 * Add NatSpec to functions
 * Check how to manage secrets correctly, and how to execute sendRequest automatically when managing secrets with the DON
 * Add testing with mocks -> FunctionsV1EventsMock
 */
contract ClimateFetcher is FunctionsClient, AutomationCompatibleInterface, ConfirmedOwner {
    error ClimateFetcher__UnexpectedRequestId(bytes32 requestId);
    error ClimateFetcher__InvalidArgs();
    error ClimateFetcher__UpkeepNotNeeded();

    using FunctionsRequest for FunctionsRequest.Request;

    address private s_router;
    bytes32 private s_donId;
    bytes32 private s_lastRequestId;
    uint32 private s_gasLimit;
    uint64 private s_subscriptionId;

    string private s_weather;
    bytes private s_lastResponse;
    bytes private s_lastError;
    string private constant DEFAULT_CITY = "Buenos Aires";

    uint256 private s_lastTimeStamp;
    uint256 private s_interval;

    string constant SOURCE = "const city = args[0];" "if (!secrets.SOLIDITY_API_KEY) {"
        "  throw Error('API key required');" "}" "const config = {"
        "  url: `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${secrets.SOLIDITY_API_KEY}`," "};"
        "const request = await Functions.makeHttpRequest(config);" "const response = await request;"
        "const weather = response.data.weather[0].main;" "return Functions.encodeString(weather);";

    event Response(bytes32 indexed requestId, string weather, bytes response, bytes err);

    constructor(
        address router,
        bytes32 donId,
        uint32 gasLimit,
        uint64 subscriptionId,
        uint256 interval
    ) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        s_router = router;
        s_donId = donId;
        s_gasLimit = gasLimit;
        s_subscriptionId = subscriptionId;
        s_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert ClimateFetcher__UpkeepNotNeeded();
        }

        s_lastTimeStamp = block.timestamp;
        string[] memory args;
        args[0] = DEFAULT_CITY;
        sendRequest(args);
    }

    function sendRequest(string[] memory args) public onlyOwner returns (bytes32 requestId) {
        if (args.length == 0) {
            revert ClimateFetcher__InvalidArgs();
        }

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(SOURCE);
        req.setArgs(args);
        req.addSecretsReference(s_encryptedSecret);

        s_lastRequestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, s_gasLimit, s_donId);

        return s_lastRequestId;
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (s_lastRequestId != requestId) {
            revert ClimateFetcher__UnexpectedRequestId(requestId);
        }

        s_lastResponse = response;
        s_weather = string(response);
        s_lastError = err;

        emit Response(requestId, s_weather, s_lastResponse, s_lastError);
    }

    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        upkeepNeeded = (block.timestamp - s_lastTimeStamp) > s_interval;
        return (upkeepNeeded, "");
    }

    function getRouter() external view returns (address router) {
        router = s_router;
    }

    function getDonId() external view returns (bytes32 donId) {
        donId = s_donId;
    }

    function getLastRequestId() external view returns (bytes32 lastRequestId) {
        lastRequestId = s_lastRequestId;
    }

    function getGasLimit() external view returns (uint32 gasLimit) {
        gasLimit = s_gasLimit;
    }

    function getSubscriptionId() external view returns (uint64 subscriptionId) {
        subscriptionId = s_subscriptionId;
    }

    function getWeather() external view returns (string memory weather) {
        weather = s_weather;
    }

    function getLastResponse() external view returns (bytes memory lastResponse) {
        lastResponse = s_lastResponse;
    }

    function getLastError() external view returns (bytes memory lastError) {
        lastError = s_lastError;
    }

    function getLastTimestamp() external view returns (uint256 lastTimeStamp) {
        lastTimeStamp = s_lastTimeStamp;
    }

    function getInterval() external view returns (uint256 interval) {
        interval = s_interval;
    }
}
