// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title CouncilRegistry - les 10 sièges du conseil de la Solidarité, renouvelés chaque mois.
/// @notice Aucun owner, aucun admin. Choix de conception (le plus sûr et le plus simple) :
///         la rotation est confirmée par un ensemble FIXE de signataires d'élection (immutable),
///         seuil M sur N fixé au déploiement. Chaque signataire confirme la même liste exacte ;
///         quand M confirmations sont atteintes, la liste s'applique.
///         Pourquoi pas un vote du conseil sortant : une supermajorité du conseil pourrait se
///         reconduire elle-même et verrouiller le pouvoir ; les signataires, eux, sont publics et
///         ne siègent pas (ils ne peuvent pas voter les paiements) : ils ne font que publier le résultat
///         des élections (point de confiance explicite, voir docs/COUNCIL.md).
///         Garde-fous : une rotation au plus tous les 30 jours, 10 adresses distinctes, non nulles,
///         et différentes du fondateur. Les confirmations d'une liste sont liées à la période courante
///         (epoch) : après une rotation, les anciennes confirmations ne valent plus rien.
contract CouncilRegistry {
    uint256 public constant COUNCIL_SIZE = 10;
    uint256 public constant MIN_INTERVAL = 30 days;
    uint256 public constant MAX_SIGNERS = 15;

    address public immutable founder;
    uint256 public immutable threshold;
    address[] private _signers;
    mapping(address => bool) public isElectionSigner;

    address[COUNCIL_SIZE] public council;
    mapping(address => bool) public isMember;
    uint256 public lastRotation;
    uint256 public epoch;

    mapping(uint256 => mapping(bytes32 => uint256)) public confirmations;
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) public confirmedBy;

    event CouncilSet(address[COUNCIL_SIZE] council, uint256 indexed epoch);
    event RotationConfirmed(bytes32 indexed listHash, address indexed signer, uint256 count, uint256 indexed epoch);
    event CouncilRotated(address[COUNCIL_SIZE] oldCouncil, address[COUNCIL_SIZE] newCouncil, uint256 indexed epoch);

    constructor(
        address _founder,
        address[COUNCIL_SIZE] memory initial,
        address[] memory signers,
        uint256 _threshold
    ) {
        require(_founder != address(0), "zero founder");
        require(signers.length > 0 && signers.length <= MAX_SIGNERS, "bad signers");
        require(_threshold > 0 && _threshold <= signers.length, "bad threshold");
        founder = _founder;
        threshold = _threshold;
        for (uint256 i; i < signers.length; i++) {
            address s = signers[i];
            require(s != address(0) && !isElectionSigner[s], "bad signer");
            isElectionSigner[s] = true;
            _signers.push(s);
        }
        _validate(initial, _founder);
        _store(initial);
        lastRotation = block.timestamp;
        emit CouncilSet(initial, 0);
    }

    function signers() external view returns (address[] memory) {
        return _signers;
    }

    function currentCouncil() external view returns (address[COUNCIL_SIZE] memory) {
        return council;
    }

    function hashOf(address[COUNCIL_SIZE] calldata list) public pure returns (bytes32) {
        return keccak256(abi.encode(list));
    }

    /// @notice Un signataire propose (première confirmation) ou confirme une nouvelle liste de 10 membres.
    ///         La rotation s'applique dès que le seuil est atteint ; elle est refusée avant 30 jours
    ///         après la précédente.
    function confirmRotation(address[COUNCIL_SIZE] calldata list) external {
        require(isElectionSigner[msg.sender], "not signer");
        require(block.timestamp >= lastRotation + MIN_INTERVAL, "too soon");
        _validate(list, founder);
        bytes32 h = hashOf(list);
        require(!confirmedBy[epoch][h][msg.sender], "already confirmed");
        confirmedBy[epoch][h][msg.sender] = true;
        uint256 c = ++confirmations[epoch][h];
        emit RotationConfirmed(h, msg.sender, c, epoch);
        if (c >= threshold) {
            address[COUNCIL_SIZE] memory old = council;
            for (uint256 i; i < COUNCIL_SIZE; i++) isMember[old[i]] = false;
            _store(list);
            lastRotation = block.timestamp;
            epoch++;
            emit CouncilRotated(old, list, epoch);
        }
    }

    function _validate(address[COUNCIL_SIZE] memory list, address _founder) internal view {
        for (uint256 i; i < COUNCIL_SIZE; i++) {
            address m = list[i];
            require(m != address(0) && m != _founder && !isElectionSigner[m], "bad member");
            for (uint256 j; j < i; j++) require(list[j] != m, "duplicate member");
        }
    }

    function _store(address[COUNCIL_SIZE] memory list) internal {
        for (uint256 i; i < COUNCIL_SIZE; i++) {
            council[i] = list[i];
            isMember[list[i]] = true;
        }
    }
}
