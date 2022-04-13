pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("MOCK", "MOCK") {}

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}
