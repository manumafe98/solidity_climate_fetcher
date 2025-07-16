// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
contract ClimateFetcher is FunctionsClient, ConfirmedOwner {
    error ClimateFetcher__UnexpectedRequestId(bytes32 requestId);

    using FunctionsRequest for FunctionsRequest.Request;

    address private s_rounter;
    bytes32 private s_donId;
    bytes32 private s_lastRequestId;
    uint32 private s_gasLimit;
    uint64 private s_subscriptionId;
    bytes s_encryptedSecretsUrls;

    string private s_weather;
    bytes private s_lastResponse;
    bytes private s_lastError;

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
        bytes memory encryptedSecretsUrls
    ) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        s_rounter = router;
        s_donId = donId;
        s_gasLimit = gasLimit;
        s_subscriptionId = subscriptionId;
        s_encryptedSecretsUrls = encryptedSecretsUrls;
    }

    function sendRequest(string[] calldata args) external onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(SOURCE);
        if (args.length > 0) {
            req.setArgs(args);
        }

        if (s_encryptedSecretsUrls.length > 0) {
            req.addSecretsReference(s_encryptedSecretsUrls);
        }

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
}
