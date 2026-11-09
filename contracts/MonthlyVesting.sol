// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20MV {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

/// @title MonthlyVesting - déblocage par paliers mensuels (30 jours), sans admin.
/// @notice 1/MONTHS du total à la fin de chaque période de 30 jours, à partir de `start`.
contract MonthlyVesting {
    uint256 public constant PERIOD = 30 days;

    address public immutable beneficiary;
    uint256 public immutable start;
    uint256 public immutable months;
    mapping(address => uint256) public released;

    event Released(address indexed token, uint256 amount);

    constructor(address _beneficiary, uint256 _start, uint256 _months) {
        require(_beneficiary != address(0) && _months > 0, "bad params");
        beneficiary = _beneficiary;
        start = _start;
        months = _months;
    }

    function vestedAmount(IERC20MV token) public view returns (uint256) {
        uint256 total = token.balanceOf(address(this)) + released[address(token)];
        if (block.timestamp < start) return 0;
        uint256 elapsed = (block.timestamp - start) / PERIOD;
        if (elapsed >= months) return total;
        return (total * elapsed) / months;
    }

    function release(IERC20MV token) external {
        uint256 amount = vestedAmount(token) - released[address(token)];
        require(amount > 0, "nothing to release");
        released[address(token)] += amount;
        require(token.transfer(beneficiary, amount), "transfer failed");
        emit Released(address(token), amount);
    }
}
