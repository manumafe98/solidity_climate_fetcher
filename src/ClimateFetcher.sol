// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

/**
 * @title Climate Fetcher
 * @author Manuel Maxera
 * @notice This contract fetches the current weather for a specified city by making an API call to OpenWeatherMap using Chainlink Functions.
 * @notice It also uses Chainlink Automation to periodically trigger these API calls for a default city (Buenos Aires).
 * @dev Implements `FunctionsClient` for Chainlink Functions, `AutomationCompatibleInterface` for Chainlink Automation, and `ConfirmedOwner` for access control.
 */
contract ClimateFetcher is FunctionsClient, AutomationCompatibleInterface, ConfirmedOwner {
    error ClimateFetcher__UnexpectedRequestId(bytes32 requestId);
    error ClimateFetcher__InvalidArgs();
    error ClimateFetcher__UpkeepNotNeeded();

    using FunctionsRequest for FunctionsRequest.Request;

    /* State Variables */

    address private s_router;
    bytes32 private s_donId;
    bytes32 private s_lastRequestId;
    uint32 private s_gasLimit;
    uint64 private s_subscriptionId;
    bytes private s_encryptedSecret;

    uint256 private s_lastTimeStamp;
    uint256 private s_interval;

    string private s_weather;
    bytes private s_lastResponse;
    bytes private s_lastError;
    string private constant DEFAULT_CITY = "Buenos Aires";

    /**
     * @notice The JavaScript source code to be executed by the Chainlink Functions DON.
     * @dev Fetches weather data from OpenWeatherMap API using a city name from `args` and an API key from `secrets`.
     */
    string constant SOURCE =
        "const city = args[0];if (!secrets.SOLIDITY_API_KEY) {throw Error('API key required');}const config = {url: `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${secrets.SOLIDITY_API_KEY}`};const request = await Functions.makeHttpRequest(config);const response = await request;const weather = response.data.weather[0].main;return Functions.encodeString(weather);";

    /* Events */

    event Response(bytes32 indexed requestId, string weather, bytes response, bytes err);

    /**
     * @notice Initializes the contract with Chainlink Functions and Automation configurations.
     * @param router The address of the Chainlink Functions router.
     * @param donId The ID of the DON to execute the Functions request.
     * @param gasLimit The gas limit for the fulfillment callback.
     * @param subscriptionId The Chainlink Functions subscription ID.
     * @param encryptedSecret The encrypted API key for OpenWeatherMap, stored as bytes.
     * @param interval The time interval (in seconds) for Chainlink Automation to trigger upkeep.
     */
    constructor(
        address router,
        bytes32 donId,
        uint32 gasLimit,
        uint64 subscriptionId,
        bytes memory encryptedSecret,
        uint256 interval
    ) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        s_router = router;
        s_donId = donId;
        s_gasLimit = gasLimit;
        s_subscriptionId = subscriptionId;
        s_interval = interval;
        s_encryptedSecret = encryptedSecret;
        s_lastTimeStamp = block.timestamp;
    }

    /**
     * @notice Called by Chainlink Automation to trigger a weather data request for the default city.
     * @notice performData The data passed from `checkUpkeep`, not used in this implementation.
     * @dev Checks if upkeep is needed based on the interval. If so, it updates the timestamp and calls `sendRequest`.
     */
    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert ClimateFetcher__UpkeepNotNeeded();
        }
        s_lastTimeStamp = block.timestamp;
        string[] memory args = new string[](1);
        args[0] = DEFAULT_CITY;
        sendRequest(args);
    }

    /**
     * @notice Updates the encrypted secrets reference used for API calls.
     * @dev Only callable by the contract owner.
     * @param newEncryptedSecret The new encrypted secrets data as bytes.
     */
    function setEncryptedSecret(bytes memory newEncryptedSecret) external onlyOwner {
        s_encryptedSecret = newEncryptedSecret;
    }

    /**
     * @notice Updates the Chainlink Functions subscription ID.
     * @dev Only callable by the contract owner.
     * @param newSubscriptionId The new subscription ID.
     */
    function setSubscriptionId(uint64 newSubscriptionId) external onlyOwner {
        s_subscriptionId = newSubscriptionId;
    }

    /**
     * @notice Updates the gas limit for the Chainlink Functions callback.
     * @dev Only callable by the contract owner.
     * @param newGasLimit The new gas limit for the fulfillment callback.
     */
    function setGasLimit(uint32 newGasLimit) external onlyOwner {
        s_gasLimit = newGasLimit;
    }

    /**
     * @notice Sends a request to Chainlink Functions to fetch weather data for a given city.
     * @dev Only callable by the contract owner. Constructs and sends an inline JavaScript request.
     * @param args An array of strings, where the first element is the city name.
     * @return requestId The ID of the Chainlink Functions request.
     */
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

    /**
     * @notice The callback function that receives the result from the Chainlink Functions oracle.
     * @dev This function is called by the Functions oracle. It verifies the request ID, decodes the response, and stores the weather data.
     * @param requestId The unique ID of the fulfilled request.
     * @param response The response data from the Functions request, ABI-encoded.
     * @param err Any error data from the Functions request.
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (s_lastRequestId != requestId) {
            revert ClimateFetcher__UnexpectedRequestId(requestId);
        }
        s_lastResponse = response;
        s_weather = abi.decode(response, (string));
        s_lastError = err;
        emit Response(requestId, s_weather, s_lastResponse, s_lastError);
    }

    /**
     * @notice Checks if the time interval has passed, indicating that a new upkeep is needed.
     * @notice checkData Data passed to the contract, not used in this implementation.
     * @dev Called by the Chainlink Automation network to determine if `performUpkeep` should be executed.
     * @return upkeepNeeded True if the interval has passed since the last upkeep, false otherwise.
     * @return performData Data to be passed to `performUpkeep`, not used here.
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        upkeepNeeded = (block.timestamp - s_lastTimeStamp) > s_interval;
        return (upkeepNeeded, "");
    }

    /* Getter Functions */

    /**
     * @notice Gets the address of the Chainlink Functions router.
     * @return router The router address.
     */
    function getRouter() external view returns (address router) {
        router = s_router;
    }

    /**
     * @notice Gets the ID of the DON used for Functions requests.
     * @return donId The DON ID.
     */
    function getDonId() external view returns (bytes32 donId) {
        donId = s_donId;
    }

    /**
     * @notice Gets the ID of the most recent Chainlink Functions request.
     * @return lastRequestId The last request ID.
     */
    function getLastRequestId() external view returns (bytes32 lastRequestId) {
        lastRequestId = s_lastRequestId;
    }

    /**
     * @notice Gets the gas limit configured for the callback.
     * @return gasLimit The callback gas limit.
     */
    function getGasLimit() external view returns (uint32 gasLimit) {
        gasLimit = s_gasLimit;
    }

    /**
     * @notice Gets the Chainlink Functions subscription ID.
     * @return subscriptionId The subscription ID.
     */
    function getSubscriptionId() external view returns (uint64 subscriptionId) {
        subscriptionId = s_subscriptionId;
    }

    /**
     * @notice Gets the most recently fetched weather data.
     * @return weather A string describing the current weather (e.g., "Clouds", "Clear").
     */
    function getWeather() external view returns (string memory weather) {
        weather = s_weather;
    }

    /**
     * @notice Gets the full raw response from the last Functions request.
     * @return lastResponse The last response as bytes.
     */
    function getLastResponse() external view returns (bytes memory lastResponse) {
        lastResponse = s_lastResponse;
    }

    /**
     * @notice Gets any error data from the last Functions request.
     * @return lastError The last error as bytes.
     */
    function getLastError() external view returns (bytes memory lastError) {
        lastError = s_lastError;
    }

    /**
     * @notice Gets the timestamp of the last automated upkeep.
     * @return lastTimeStamp The Unix timestamp of the last upkeep.
     */
    function getLastTimestamp() external view returns (uint256 lastTimeStamp) {
        lastTimeStamp = s_lastTimeStamp;
    }

    /**
     * @notice Gets the currently configured encrypted secrets reference.
     * @return encryptedSecret The encrypted secrets data as bytes.
     */
    function getEncryptedSecret() external view returns (bytes memory encryptedSecret) {
        encryptedSecret = s_encryptedSecret;
    }

    /**
     * @notice Gets the configured automation interval.
     * @return interval The time in seconds between automated upkeeps.
     */
    function getInterval() external view returns (uint256 interval) {
        interval = s_interval;
    }
}
