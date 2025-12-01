// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestExample {
    function exampleFunction(
        uint256 value1,
        address addr1,
        bytes32 data1,
        bool flag1
    ) public pure returns (uint256) {
        return value1;
    }

    function anotherFunction(
        string memory name,
        uint256 age,
        address wallet
    ) internal pure returns (string memory) {
        return name;
    }

    function caller() public {
        // This should be converted (4 args)
        exampleFunction({
    value1: 10,
    addr1: address(0x123),
    data1: bytes32(0),
    flag1: tru
});

        // This should NOT be converted (3 args, below threshold)
        anotherFunction("Alice", 30, address(0x456));

        // This should be converted (5 args)
        Message.formatMessage({
    version: 1,
    nonce: 0,
    origin: 100,
    sender: bytes32(0),
    destination: 200,
    recipient: bytes32(0),
    body: "hello
});
    }
}

library Message {
    function formatMessage(
        uint8 version,
        uint32 nonce,
        uint32 origin,
        bytes32 sender,
        uint32 destination,
        bytes32 recipient,
        bytes memory body
    ) internal pure returns (bytes memory) {
        return body;
    }
}
