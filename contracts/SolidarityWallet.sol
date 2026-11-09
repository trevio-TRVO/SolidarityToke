// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Min {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

interface ICommunityLots {
    function hasBought(address who) external view returns (bool);
}

/// @title SolidarityWallet - reçoit les 5 % d'aide directe et paie les factures validées.
/// @notice Sans admin sur le token. Dernier contrôle humain sur la distribution :
///         conseil de 10 comptes (poids 1) + fondateur (poids 3), seuil de 5.
///         Le fondateur seul ne peut pas valider (3 < 5) : il lui faut 2 membres du conseil.
///         Un paiement exige : >= 5 validateurs (acquéreurs de lots) + poids >= 5 + délai de 24 h.
///         Les fonds ne peuvent aller qu'au bénéficiaire de la demande, jamais ailleurs.
contract SolidarityWallet {
    uint256 public constant COUNCIL_SIZE = 10;
    uint256 public constant FOUNDER_WEIGHT = 3;
    uint256 public constant THRESHOLD = 5;
    uint256 public constant MIN_VALIDATORS = 5;
    uint256 public constant CYCLE = 24 hours;
    uint256 public constant PAYEE_COOLDOWN = 30 days;
    uint256 public constant MAX_BPS_PER_PAYMENT = 2000; // 20 % du solde max par paiement

    IERC20Min public immutable token;
    ICommunityLots public immutable lots;
    address public immutable founder;
    address[COUNCIL_SIZE] public council;
    mapping(address => bool) public isCouncil;

    enum Status { None, Open, Executed, Cancelled }

    struct Request {
        address payee;
        uint256 amount;
        bytes32 invoiceHash; // empreinte du dossier hors chaîne (aucune donnée privée sur la chaîne)
        uint64 validatedAt;  // 0 tant que < MIN_VALIDATORS
        uint32 validators;
        uint32 weight;
        Status status;
    }

    Request[] public requests;
    mapping(uint256 => mapping(address => bool)) public validated;
    mapping(uint256 => mapping(address => bool)) public approved;
    mapping(address => uint256) public lastPaid;

    event RequestCreated(uint256 indexed id, address indexed payee, uint256 amount, bytes32 invoiceHash);
    event Validated(uint256 indexed id, address indexed validator, uint256 validators);
    event Approved(uint256 indexed id, address indexed signer, uint256 weight);
    event Cancelled(uint256 indexed id, address indexed by);
    event Paid(uint256 indexed id, address indexed payee, uint256 amount);

    constructor(IERC20Min _token, ICommunityLots _lots, address _founder, address[COUNCIL_SIZE] memory _council) {
        require(_founder != address(0), "zero founder");
        token = _token;
        lots = _lots;
        founder = _founder;
        for (uint256 i; i < COUNCIL_SIZE; i++) {
            address m = _council[i];
            require(m != address(0) && m != _founder && !isCouncil[m], "bad member");
            isCouncil[m] = true;
            council[i] = m;
        }
    }

    function _cooledDown(address a) internal view returns (bool) {
        uint256 t = lastPaid[a];
        return t == 0 || block.timestamp >= t + PAYEE_COOLDOWN;
    }

    function _weightOf(address a) internal view returns (uint256) {
        if (a == founder) return FOUNDER_WEIGHT;
        return isCouncil[a] ? 1 : 0;
    }

    /// @notice Dépose une demande (le dossier complet reste hors chaîne, seule son empreinte est publiée).
    function createRequest(address payee, uint256 amount, bytes32 invoiceHash) external returns (uint256 id) {
        require(payee != address(0) && amount > 0, "bad request");
        require(amount <= token.balanceOf(address(this)) * MAX_BPS_PER_PAYMENT / 10_000, "above cap");
        require(_cooledDown(payee), "payee cooldown");
        id = requests.length;
        requests.push(Request(payee, amount, invoiceHash, 0, 0, 0, Status.Open));
        emit RequestCreated(id, payee, amount, invoiceHash);
    }

    /// @notice Validation par un acquéreur de lot (un wallet, une voix par demande).
    function validate(uint256 id) external {
        Request storage r = requests[id];
        require(r.status == Status.Open, "not open");
        require(lots.hasBought(msg.sender), "not a lot holder");
        require(msg.sender != r.payee, "payee");
        require(!validated[id][msg.sender], "already validated");
        validated[id][msg.sender] = true;
        r.validators++;
        if (r.validators == MIN_VALIDATORS) r.validatedAt = uint64(block.timestamp);
        emit Validated(id, msg.sender, r.validators);
    }

    /// @notice Approbation du conseil (poids 1) ou du fondateur (poids 3).
    function approve(uint256 id) external {
        Request storage r = requests[id];
        require(r.status == Status.Open, "not open");
        uint256 w = _weightOf(msg.sender);
        require(w > 0, "not council");
        require(!approved[id][msg.sender], "already approved");
        approved[id][msg.sender] = true;
        r.weight += uint32(w);
        emit Approved(id, msg.sender, r.weight);
    }

    /// @notice Le fondateur seul, ou un poids de 5 via cancelVotes, peut annuler. Voir cancelByCouncil.
    function cancel(uint256 id) external {
        require(msg.sender == founder, "founder only");
        _cancel(id);
    }

    mapping(uint256 => mapping(address => bool)) public cancelVoted;
    mapping(uint256 => uint256) public cancelWeight;

    /// @notice Le conseil peut annuler à un poids cumulé de 5.
    function cancelByCouncil(uint256 id) external {
        uint256 w = _weightOf(msg.sender);
        require(w > 0, "not council");
        require(!cancelVoted[id][msg.sender], "already voted");
        cancelVoted[id][msg.sender] = true;
        cancelWeight[id] += w;
        if (cancelWeight[id] >= THRESHOLD) _cancel(id);
    }

    function _cancel(uint256 id) internal {
        Request storage r = requests[id];
        require(r.status == Status.Open, "not open");
        r.status = Status.Cancelled;
        emit Cancelled(id, msg.sender);
    }

    /// @notice Exécutable par n'importe qui une fois toutes les conditions réunies.
    function execute(uint256 id) external {
        Request storage r = requests[id];
        require(r.status == Status.Open, "not open");
        require(r.validators >= MIN_VALIDATORS, "validators");
        require(r.weight >= THRESHOLD, "council weight");
        require(block.timestamp >= r.validatedAt + CYCLE, "cycle not elapsed");
        require(_cooledDown(r.payee), "payee cooldown");
        r.status = Status.Executed;
        lastPaid[r.payee] = block.timestamp;
        require(token.transfer(r.payee, r.amount), "transfer failed");
        emit Paid(id, r.payee, r.amount);
    }

    function requestCount() external view returns (uint256) {
        return requests.length;
    }
}
