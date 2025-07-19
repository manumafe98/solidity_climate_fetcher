// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract MockOracle {
    error MockOracle__FulfillmentFailed();
    error MockOracle__InvalidRequest();

    struct Request {
        address consumer;
        bytes32 requestId;
        bool fulfilled;
    }

    mapping(bytes32 => Request) public requests;

    event RequestSent(bytes32 indexed requestId, address indexed consumer);
    event RequestFulfilled(bytes32 indexed requestId, address indexed consumer);

    function sendRequest(uint64, bytes calldata, uint16, uint32, bytes32) external returns (bytes32 requestId) {
        requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number));

        requests[requestId] = Request({consumer: msg.sender, requestId: requestId, fulfilled: false});

        emit RequestSent(requestId, msg.sender);
        return requestId;
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) external {
        Request storage request = requests[requestId];

        if (request.consumer == address(0)) {
            revert MockOracle__InvalidRequest();
        }

        if (request.fulfilled) {
            revert MockOracle__InvalidRequest();
        }

        request.fulfilled = true;

        (bool success,) = request.consumer.call(
            abi.encodeWithSignature("handleOracleFulfillment(bytes32,bytes,bytes)", requestId, response, err)
        );

        if (!success) {
            revert MockOracle__FulfillmentFailed();
        }

        emit RequestFulfilled(requestId, request.consumer);
    }

    function getRequest(bytes32 requestId) external view returns (Request memory) {
        return requests[requestId];
    }

    function requestExists(bytes32 requestId) external view returns (bool) {
        return requests[requestId].consumer != address(0);
    }
}
