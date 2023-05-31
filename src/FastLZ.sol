// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "solady/utils/LibZip.sol";

contract FastLZ {
    /// @dev Returns the compressed `data`.
    function compress(bytes memory data) external pure virtual returns (bytes memory) {
        return LibZip.flzCompress(data);
    }

    /// @dev Returns the decompressed `data`.
    function decompress(bytes memory data) external pure virtual returns (bytes memory) {
        return LibZip.flzDecompress(data);
    }

    function __decompressAndCall(bytes memory compressedInitcode, bytes memory data)
        external
        virtual
    {
        bytes memory decompressedInitcode = LibZip.flzDecompress(compressedInitcode);

        address temporaryAddr;

        assembly {
            temporaryAddr := create(0, add(decompressedInitcode, 0x20), mload(decompressedInitcode))
        }

        (bool success, bytes memory returnData) = temporaryAddr.delegatecall(data);

        assembly {
            // If not successful call, return `returnData` using revert statement.
            if iszero(success) { revert(add(returnData, 0x20), mload(returnData)) }

            // Otherwise, return `returnData` using return statement.
            return(add(returnData, 0x20), mload(returnData))
        }
    }

    function decompressAndCall(bytes memory compressedInitcode, bytes memory data)
        external
        virtual
        returns (bytes memory returnData)
    {
        (, returnData) = address(this).delegatecall(
            abi.encodeCall(this.__decompressAndCall, (compressedInitcode, data))
        );
    }
}