// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract MockOracle {
    error MockOracle__FullfillmentFailed();

    function fulfillRequest(
        address consumer,
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) external {
        (bool success, ) = consumer.call(
            abi.encodeWithSignature(
                "handleOracleFulfillment(bytes32,bytes,bytes)",
                requestId,
                response,
                err
            )
        );
        if (!success) {
            revert MockOracle__FullfillmentFailed();
        }
    }
}
