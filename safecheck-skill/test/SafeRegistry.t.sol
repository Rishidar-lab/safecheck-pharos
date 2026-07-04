// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SafeRegistry} from "../src/safecheck/SafeRegistry.sol";

contract SafeRegistryTest is Test {
    SafeRegistry reg;
    address target = address(0xBEEF);

    function setUp() public {
        reg = new SafeRegistry();
    }

    function test_AttestAndReadLatest() public {
        reg.attest(target, uint8(SafeRegistry.Verdict.Danger), 90, "honeypot: sells blocked");
        assertEq(reg.attestationCount(target), 1);
        assertEq(reg.totalAttestations(), 1);

        (address auditor, uint8 verdict, uint8 score, , string memory note) = reg.getLatest(target);
        assertEq(auditor, address(this));
        assertEq(verdict, uint8(SafeRegistry.Verdict.Danger));
        assertEq(score, 90);
        assertEq(note, "honeypot: sells blocked");
    }

    function test_AppendOnlyHistory() public {
        reg.attest(target, uint8(SafeRegistry.Verdict.Caution), 40, "mintable");
        reg.attest(target, uint8(SafeRegistry.Verdict.Safe), 5, "renounced ownership");
        assertEq(reg.attestationCount(target), 2);
        (, uint8 v0, , , ) = reg.getAttestation(target, 0);
        (, uint8 v1, , , ) = reg.getLatest(target);
        assertEq(v0, uint8(SafeRegistry.Verdict.Caution));
        assertEq(v1, uint8(SafeRegistry.Verdict.Safe));
    }

    function test_RevertOnZeroTarget() public {
        vm.expectRevert("Target is zero address");
        reg.attest(address(0), 1, 0, "x");
    }

    function test_RevertOnBadVerdict() public {
        vm.expectRevert("Verdict out of range");
        reg.attest(target, 0, 0, "unknown not allowed");
        vm.expectRevert("Verdict out of range");
        reg.attest(target, 4, 0, "too high");
    }

    function test_RevertOnBadScore() public {
        vm.expectRevert("Risk score over 100");
        reg.attest(target, 1, 101, "x");
    }

    function test_RevertOnLatestWhenEmpty() public {
        vm.expectRevert("No attestations for target");
        reg.getLatest(address(0xCAFE));
    }
}
