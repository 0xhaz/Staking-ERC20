// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Chainlink is ERC20 {
    constructor() ERC20("Chainlink", "LINK") {
        _mint(msg.sender, 5000 * 1e18);
    }
}
