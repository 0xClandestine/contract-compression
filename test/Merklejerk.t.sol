// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {LibZip} from "solady/utils/LibZip.sol";

contract FastLZ {
    function compress(bytes memory data) external pure returns (bytes memory) {
        return LibZip.flzCompress(data);
    }

    function decompress(bytes memory data) external pure returns (bytes memory) {
        return LibZip.flzDecompress(data);
    }

    function __decompressAndCall(bytes memory compressedCreationCode, bytes memory data) external {
        bytes memory decompressedCreationCode = LibZip.flzDecompress(compressedCreationCode);

        address temporaryAddr;

        assembly {
            temporaryAddr :=
                create(0, add(decompressedCreationCode, 0x20), mload(decompressedCreationCode))
        }

        (bool success, bytes memory returnData) = temporaryAddr.call(data);

        // Ensure any modifications are reverted
        assembly {
            if success { revert(add(returnData, 0x20), mload(returnData)) }

            return(add(returnData, 0x20), mload(returnData))
        }
    }

    function decompressAndCall(bytes memory compressedCreationCode, bytes memory data)
        external
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodeCall(this.__decompressAndCall, (compressedCreationCode, data))
        );

        if (success) revert();

        return returnData;
    }
}

contract Foo {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }
}

contract ContractCompressionTest is Test {
    FastLZ public immutable flz;

    constructor() {
        flz = new FastLZ();
    }

    function testRoundtrip() public {
        bytes memory compressedCreationCode = flz.compress(type(Foo).creationCode);

        assertEq(
            abi.decode(
                flz.decompressAndCall(compressedCreationCode, abi.encodeCall(Foo.add, (400, 20))),
                (uint256)
            ),
            420
        );
    }
}
