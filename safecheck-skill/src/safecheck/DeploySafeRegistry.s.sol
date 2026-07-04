// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SafeRegistry} from "./SafeRegistry.sol";

/// @notice Deploy script for SafeRegistry.
///         Run: forge script src/safecheck/DeploySafeRegistry.s.sol:DeploySafeRegistry \
///                --rpc-url $RPC --private-key $PRIVATE_KEY --broadcast
contract DeploySafeRegistry is Script {
    function run() external returns (SafeRegistry registry) {
        vm.startBroadcast();
        registry = new SafeRegistry();
        vm.stopBroadcast();
    }
}
