// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "./mocks/HyVM.sol";

import {Utils} from "lib/HyVM/test/utils/Utils.sol";
import {LibZip} from "solady/utils/LibZip.sol";

contract FastLZ {
    function compress(bytes memory data) external pure returns (bytes memory) {
        return LibZip.flzCompress(data);
    }

    function decompress(bytes memory data) external pure returns (bytes memory) {
        return LibZip.flzDecompress(data);
    }
}

contract Foo {
    function _getArgUint256(uint256 argOffset) internal pure returns (uint256 arg) {
        assembly {
            codecopy(0x0, sub(codesize(), add(argOffset, 0x20)), 0x20)

            arg := mload(0x0)
        }
    }

    function a() internal pure returns (uint256) {
        return _getArgUint256(0);
    }

    function b() internal pure returns (uint256) {
        return _getArgUint256(32);
    }

    fallback(bytes calldata) external returns (bytes memory) {
        return abi.encode(a() + b());
    }
}

contract ContractCompressionTest is Test {
    address immutable hyvm;
    FastLZ immutable flz;

    constructor() {
        hyvm = deployHyVM();
        flz = new FastLZ();
        vm.label(hyvm, "HyVM");
        vm.label(address(flz), "FastLZ");
    }

    function testRoundtrip() public {
        bytes memory runtimeCode = abi.encodePacked(
            flz.decompress(flz.compress(type(Foo).runtimeCode)),
            // args
            uint256(420),
            uint256(69)
        );

        (, bytes memory returnData) = hyvm.delegatecall(runtimeCode);

        assertEq(abi.decode(returnData, (uint256)), 420 + 69);
    }
}
