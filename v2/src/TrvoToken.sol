// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title TrvoToken
/// @notice Fixed-supply ERC20. Entire supply is minted once in the constructor.
/// No owner, no mint function, no burn privilege, no pause.
contract TrvoToken is ERC20 {
    constructor(address recipient, uint256 totalSupply_) ERC20("Trevio", "TRVO") {
        require(recipient != address(0), "recipient=0");
        require(totalSupply_ > 0, "supply=0");
        _mint(recipient, totalSupply_);
    }
}
