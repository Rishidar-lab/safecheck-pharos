// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SafeRegistry
/// @notice On-chain registry of community security attestations for the SafeCheck skill.
///         Anyone can publish a verdict about a target address (a token, contract, or
///         wallet). Steward Agents read the latest attestation before a user signs, and
///         auditors write new ones after running the SafeCheck audit flow. All state is
///         append-only: attestations are never mutated or deleted, so history is auditable.
contract SafeRegistry {
    /// @dev Risk verdict for a target address.
    enum Verdict {
        Unknown, // 0 - never audited
        Safe,    // 1 - no material risks found
        Caution, // 2 - non-critical risks (e.g. mintable, pausable)
        Danger   // 3 - critical risks (e.g. honeypot, unlimited-approval drain)
    }

    struct Attestation {
        address auditor;   // who published this verdict
        uint8 verdict;     // Verdict enum value (0-3)
        uint8 riskScore;   // 0 (safe) .. 100 (critical)
        uint64 timestamp;  // block time of publication
        string note;       // short human-readable summary of findings
    }

    /// @dev target => append-only list of attestations, newest at the highest index.
    mapping(address => Attestation[]) private _attestations;

    /// @notice Total number of attestations ever recorded across all targets.
    uint256 public totalAttestations;

    event Attested(
        address indexed target,
        address indexed auditor,
        uint8 verdict,
        uint8 riskScore,
        uint64 timestamp,
        string note
    );

    /// @notice Publish a security attestation about `target`.
    /// @param target The address the verdict is about (token/contract/wallet).
    /// @param verdict Verdict enum value: 1=Safe, 2=Caution, 3=Danger.
    /// @param riskScore Risk score from 0 (safe) to 100 (critical).
    /// @param note Short human-readable summary of the findings.
    function attest(
        address target,
        uint8 verdict,
        uint8 riskScore,
        string calldata note
    ) external {
        require(target != address(0), "Target is zero address");
        require(verdict >= uint8(Verdict.Safe) && verdict <= uint8(Verdict.Danger), "Verdict out of range");
        require(riskScore <= 100, "Risk score over 100");
        require(bytes(note).length <= 280, "Note too long");

        _attestations[target].push(
            Attestation({
                auditor: msg.sender,
                verdict: verdict,
                riskScore: riskScore,
                timestamp: uint64(block.timestamp),
                note: note
            })
        );
        unchecked {
            totalAttestations++;
        }

        emit Attested(target, msg.sender, verdict, riskScore, uint64(block.timestamp), note);
    }

    /// @notice Number of attestations recorded for `target`.
    function attestationCount(address target) external view returns (uint256) {
        return _attestations[target].length;
    }

    /// @notice Read a single attestation for `target` by index (0 = oldest).
    function getAttestation(address target, uint256 index)
        external
        view
        returns (address auditor, uint8 verdict, uint8 riskScore, uint64 timestamp, string memory note)
    {
        require(index < _attestations[target].length, "Index out of range");
        Attestation storage a = _attestations[target][index];
        return (a.auditor, a.verdict, a.riskScore, a.timestamp, a.note);
    }

    /// @notice Read the most recent attestation for `target`.
    /// @dev Reverts if the target has never been audited; callers should check
    ///      attestationCount first, or treat a revert as "Unknown".
    function getLatest(address target)
        external
        view
        returns (address auditor, uint8 verdict, uint8 riskScore, uint64 timestamp, string memory note)
    {
        uint256 len = _attestations[target].length;
        require(len > 0, "No attestations for target");
        Attestation storage a = _attestations[target][len - 1];
        return (a.auditor, a.verdict, a.riskScore, a.timestamp, a.note);
    }
}
