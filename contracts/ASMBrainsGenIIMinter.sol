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
        uint256 maxQuantityPerTx;
    }

    address private _signer;
    IConverter public energyConverter;
    IASMBrainGenII public brain;

    // PeriodId => config
    mapping(uint256 => PeriodConfig) public configuration;

    event ConfigurationUpdated(address indexed operator, uint256 periodId, PeriodConfig config);
    event SignerUpdated(address indexed operator, address signer);
    event ConverterUpdated(address indexed operator, address converter);
    event BrainUpdated(address indexed operator, address _brain);

    constructor(
        address signer,
        address _multisig,
        address _converter,
        address _brain
    ) {
        _signer = signer;
        _grantRole(ADMIN_ROLE, _multisig);

        energyConverter = IConverter(_converter);
        brain = IASMBrainGenII(_brain);
    }

    /**
     * @notice Encode arguments to generate a hash, which will be used for validating signatures
     * @dev This function can only be called inside the contract
     * @param hashes A list of IPFS Multihash digests. Each Gen II Brain should have an unique token hash
     * @param recipient The user wallet address, to verify the signature can only be used by the wallet
     * @param numberMinted The total minted Gen II Brains amount from the user wallet address
     * @return Encoded hash
     */
    function _hash(
        bytes32[] calldata hashes,
        address recipient,
        uint256 numberMinted
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(hashes, recipient, numberMinted));
    }

    /**
     * @notice To verify the `token` is signed by the _signer
     * @dev This function can only be called inside the contract
     * @param hash The encoded hash used for signature
     * @param token The signature passed from the caller
     * @return Verification result
     */
    function _verify(bytes32 hash, bytes memory token) internal view returns (bool) {
        return (_recover(hash, token) == _signer);
    }

    /**
     * @notice Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     * @dev This function can only be called inside the contract
     * @param hash The encoded hash used for signature
     * @param token The signature passed from the caller
     * @return The recovered address
     */
    function _recover(bytes32 hash, bytes memory token) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }

    /**
     * @notice Consume ASTO Energy to mint Gen II Brains with the IPFS hashes
     * @param hashes A list of IPFS Multihash digests. Each Gen II Brain should have an unique token hash
     * @param signature The signature for verification. It should be generated from the Dapp and can only be used once
     * @param periodId Used to get the remaining ASTO Energy for the user
     */
    function mint(
        bytes32[] calldata hashes,
        bytes calldata signature,
        uint256 periodId
    ) external nonReentrant {
        uint256 quantity = hashes.length;
        require(quantity < remainingSupply(periodId) + 1, "Max supply exceeded");
        PeriodConfig memory config = configuration[periodId];
        require(quantity > 0, "Hashes cannot be empty");
        require(quantity < config.maxQuantityPerTx + 1, "Too many hashes");
        require(currentTime() + 1 > config.startTime, "Not started");
        require(currentTime() < config.endTime, "Already finished");
        // Only allow use enery accumulated from previous production cycles. Please refer to the following link for details
        // https://github.com/altered-state-machine/genome-mining-contracts/blob/main/audit/requirements.md#business-requirements
        require(periodId < energyConverter.getCurrentPeriodId(), "Invalid periodId");
        require(_verify(_hash(hashes, msg.sender, brain.numberMinted(msg.sender)), signature), "Invalid signature");

        uint256 remainingEnergy = energyConverter.getEnergy(msg.sender, periodId);
        uint256 energyToUse = quantity * config.energyPerBrain;
        require(energyToUse <= remainingEnergy, "Insufficient energy");
        energyConverter.useEnergy(msg.sender, periodId, energyToUse);

        brain.mint(msg.sender, hashes);
    }

    /**
     * @notice Returns the remaining Gen II Brains supply that can be minted for period `periodId
     * @param periodId The period id to get totalSupply from configuration
     * @return The remaining supply left for the period
     */
    function remainingSupply(uint256 periodId) public view returns (uint256) {
        PeriodConfig memory config = configuration[periodId];
        return config.maxSupply > brain.totalSupply() ? config.maxSupply - brain.totalSupply() : 0;
    }

    /**
     * @notice Update configuration for period `periodId`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param periodId The periodId to update
     * @param config New config data
     */
    function updateConfiguration(uint256 periodId, PeriodConfig calldata config) external onlyRole(ADMIN_ROLE) {
        configuration[periodId] = config;
        emit ConfigurationUpdated(msg.sender, periodId, config);
    }

    /**
     * @notice Update signer to `signer`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param signer The new signer address to update
     */
    function updateSigner(address signer) external onlyRole(ADMIN_ROLE) {
        _signer = signer;
        emit SignerUpdated(msg.sender, signer);
    }

    /**
     * @notice Update converter address to `converter`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param converter The new converter contract address
     */
    function updateConverter(address converter) external onlyRole(ADMIN_ROLE) {
        energyConverter = IConverter(converter);
        emit ConverterUpdated(msg.sender, converter);
    }

    /**
     * @notice Update brain address to `_brain`
     * @dev This function can only to called from contracts or wallets with ADMIN_ROLE
     * @param _brain The new brain contract address
     */
    function updateBrain(address _brain) external onlyRole(ADMIN_ROLE) {
        brain = IASMBrainGenII(_brain);
        emit BrainUpdated(msg.sender, _brain);
    }

    /**
     * @notice Return the current block timestamp
     * @return The current block timestamp
     */
    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}
