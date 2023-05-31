// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {StaticHyVM} from "lib/HyVM/src/StaticHyVM/StaticHyVM.sol";
import {Utils} from "lib/HyVM/test/utils/Utils.sol";

import "./mocks/FastLZ.sol";
import "./mocks/HyVM.sol";

import {calldataload} from "../src/HyVMCalldataHelpers.sol";

contract Addition {
    fallback() external {
        uint256 a = uint256(calldataload(0));
        uint256 b = uint256(calldataload(32));

        bytes memory returnData = abi.encode(a + b);

        assembly {
            return(add(returnData, 0x20), mload(returnData))
        }
    }
}

contract ContractCompressionTest is Test {
    FastLZ immutable flz;
    address immutable hyvm;
    StaticHyVM immutable hyvmStatic;

    constructor() {
        flz = new FastLZ();
        hyvm = deployHyVM();
        hyvmStatic = new StaticHyVM(hyvm);
    }

    function testRoundtripStatic() public {
        uint256 a = 420;
        uint256 b = 69;

        bytes memory compressedRuntime = flz.compress(type(Addition).runtimeCode);
        bytes memory decompressedRuntime = flz.decompress(compressedRuntime);

        // NOTE: Calldata MUST BE appended backwards to runtime code.
        bytes memory callData = abi.encodePacked(b, a);
        bytes memory runtimeCode = abi.encodePacked(decompressedRuntime, callData);

        uint256 result =
            abi.decode(hyvmStatic.staticExec(runtimeCode), (uint256));

        uint256 expected = a + b;

        assertEq(result, expected);
    }
}
