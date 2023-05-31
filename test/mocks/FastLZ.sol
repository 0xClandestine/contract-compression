// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {LibZip} from "solady/utils/LibZip.sol";

contract FastLZ {
    function compress(bytes memory data) external pure returns (bytes memory) {
        return LibZip.flzCompress(data);
    }

    function decompress(bytes memory data)
        external
        pure
        returns (bytes memory)
    {
        return LibZip.flzDecompress(data);
    }
}
