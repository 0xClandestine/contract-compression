// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// @notice To circumvent the lack of CALLDATA opcode support in
/// Hypervisor-VM, we use CODECOPY and CODESIZE for loading CALLDATA.
/// @dev Calldata must be appended backwards to the end of runtime code.
/// Additionally, 'argOffset' is not validated, thus you may read from
/// runtime if offset is too large.
function calldataload(uint256 argOffset) pure returns (bytes32 arg) {
    assembly {
        codecopy(0x0, sub(codesize(), add(argOffset, 0x20)), 0x20)

        arg := mload(0x0)
    }
}
