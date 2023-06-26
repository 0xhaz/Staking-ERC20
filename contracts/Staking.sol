// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    address public owner;
    uint256 public ethUsdPrice;
    string[] public tokenSymbols;
    uint public currentTokenId = 1;
    uint256 public currentPositionId = 1;

    struct Token {
        uint tokenId;
        string name;
        string symbol;
        address tokenAddress;
        uint256 usdPrice;
        uint256 ethPrice;
        uint apy;
    }

    struct Position {
        uint256 positionId;
        address walletAddress;
        string name;
        string symbol;
        uint256 createdDate;
        uint256 apy;
        uint256 tokenQuantity;
        uint256 usdValue;
        uint256 ethValue;
        bool open;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    mapping(string => Token) public tokens;
    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) public positionIdsByAddress;
    mapping(string => uint256) public stakedTokens;

    constructor(uint256 currentEthPrice) payable {
        ethUsdPrice = currentEthPrice;
        owner = msg.sender;
    }

    function addToken(
        string calldata _name,
        string calldata _symbol,
        address _tokenAddress,
        uint256 _usdPrice,
        uint256 _apy
    ) external onlyOwner {
        tokenSymbols.push(_symbol);
        tokens[_symbol] = Token(
            currentTokenId,
            _name,
            _symbol,
            _tokenAddress,
            _usdPrice,
            _usdPrice / ethUsdPrice,
            _apy
        );

        currentTokenId++;
    }

    function stakeTokens(
        string calldata _symbol,
        uint256 _tokenQuantity
    ) external {
        require(tokens[_symbol].tokenId != 0, "This token cannot be staked");

        IERC20(tokens[_symbol].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenQuantity
        );

        positions[currentPositionId] = Position(
            currentPositionId,
            msg.sender,
            tokens[_symbol].name,
            _symbol,
            block.timestamp,
            tokens[_symbol].apy,
            _tokenQuantity,
            tokens[_symbol].usdPrice * _tokenQuantity,
            (tokens[_symbol].usdPrice * _tokenQuantity) / ethUsdPrice,
            true
        );

        positionIdsByAddress[msg.sender].push(currentPositionId);
        currentPositionId++;
        stakedTokens[_symbol] += _tokenQuantity;
    }

    function closePosition(uint _positionId) external {
        require(
            positions[_positionId].walletAddress == msg.sender,
            "You are not the owner of this position"
        );
        require(
            positions[_positionId].open == true,
            "This position is already closed"
        );

        positions[_positionId].open = false;

        IERC20(tokens[positions[_positionId].symbol].tokenAddress).transfer(
            msg.sender,
            positions[_positionId].tokenQuantity
        );

        uint numberDays = calculateNumberDays(
            positions[_positionId].createdDate
        );

        uint weiAmount = calculateInterest(
            positions[_positionId].apy,
            positions[_positionId].ethValue,
            numberDays
        );

        (bool success, ) = payable(msg.sender).call{value: weiAmount}("");
        require(success, "Transfer failed.");
    }

    function modifyCreatedDate(
        uint _positionId,
        uint _newCreatedDate
    ) external onlyOwner {
        positions[_positionId].createdDate = _newCreatedDate;
    }

    function calculateNumberDays(uint _createdDate) public view returns (uint) {
        return (block.timestamp - _createdDate) / 60 / 60 / 24;
    }

    function getPositionIdsForAddress()
        external
        view
        returns (uint256[] memory)
    {
        return positionIdsByAddress[msg.sender];
    }

    function getPositionById(
        uint _positionId
    ) external view returns (Position memory) {
        return positions[_positionId];
    }

    function getTokenSymbols() public view returns (string[] memory) {
        return tokenSymbols;
    }

    function getToken(
        string calldata _tokenSymbol
    ) public view returns (Token memory) {
        return tokens[_tokenSymbol];
    }

    function calculateInterest(
        uint _apy,
        uint _value,
        uint _numberDays
    ) public pure returns (uint) {
        return (_apy * _value * _numberDays) / 10000 / 365;
    }
}
