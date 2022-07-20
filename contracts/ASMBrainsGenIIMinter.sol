// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IASMBrainGenII.sol";
import "./interfaces/IConverter.sol";

contract ASMBrainGenIIMinter is AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct PeriodConfig {
        uint256 startTime;
        uint256 endTime;
        uint256 energyPerBrain;
        uint256 maxSupply;
    }

    address private _signer;
    IConverter public energyConverter;
    IASMBrainGenII public brain;

    uint256 public energyPerBrain;
    mapping(uint256 => PeriodConfig) public configuration;

    constructor(
        address signer,
        address _multisig,
        address _converter,
        address _brain,
        uint256 _energyPerBrain
    ) {
        _signer = signer;
        _grantRole(ADMIN_ROLE, _multisig);

        energyConverter = IConverter(_converter);
        brain = IASMBrainGenII(_brain);

        energyPerBrain = _energyPerBrain;
    }

    mapping(bytes => bool) private _usedSig;

    function _hash(bytes32[] calldata hashes, address recipient) internal pure returns (bytes32) {
        return keccak256(abi.encode(hashes, recipient));
    }

    function _verify(bytes32 hash, bytes memory token) internal view returns (bool) {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function mint(
        bytes32[] calldata hashes,
        bytes calldata signature,
        uint256 periodId
    ) external nonReentrant {
        // TODO check invalid periodId
        PeriodConfig memory config = configuration[periodId];
        require(currentTime() < config.startTime, "Not started");
        require(currentTime() >= config.endTime, "Already finished");

        uint256 quantity = hashes.length;
        require(brain.totalSupply() + quantity <= config.maxSupply, "Max supply exceeded");
        require(_verify(_hash(hashes, msg.sender), signature), "Invalid signature");
        require(!_usedSig[signature], "Signature already used");
        require(quantity > 0, "Hashes cannot be empty");

        uint256 remainingEnergy = energyConverter.getEnergy(msg.sender, periodId);
        uint256 energyToUse = quantity * config.energyPerBrain;
        require(energyToUse <= remainingEnergy, "Insufficient energy");
        energyConverter.useEnergy(msg.sender, periodId, energyToUse);

        brain.mint(msg.sender, hashes);
        _usedSig[signature] = true;
    }

    function updateConfiguration(uint256 periodId, PeriodConfig calldata config) external onlyRole(ADMIN_ROLE) {
        configuration[periodId] = config;
        // TODO event
    }

    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}
