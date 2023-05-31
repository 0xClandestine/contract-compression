// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/FastLZ.sol";

contract Foo {
    function bar() external pure returns (string memory) {
        return "bar";
    }
}

contract ContractCompressionTest is Test {
    FastLZ public immutable flz;

    constructor() {
        flz = new FastLZ();
    }

    function testRoundtrip() public {
        bytes memory compressed = flz.compress(type(Foo).creationCode);
        bytes memory decompressed = flz.decompress(compressed);

        console.log("Encoded length:", compressed.length);
        console.log("Decoded length:", decompressed.length);

        unchecked {
            console.log("Savings:", decompressed.length - compressed.length);
        }

        assertEq(decompressed, type(Foo).creationCode);

        // reverts with "StateChangeDuringStaticCall" when using StaticFastLZ interface with added view keyword
        bytes memory returnData =
            flz.decompressAndCall(compressed, abi.encodeCall(Foo.bar, ()));

        assertEq(abi.decode(returnData, (string)), "bar");
    }
}
