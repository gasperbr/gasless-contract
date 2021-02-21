// SPDX-License-Identifier: MIT
import './Agent.sol';
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

pragma solidity 0.7.6;

// expose internal functions so they can be tested
contract Agent_ is Agent {
    
    constructor(ERC20[] memory tokens) Agent(tokens) { }

    function _claimTokens(
        ERC20 token,
        address owner,
        uint8 permitVersion,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        claimTokens(token, owner, permitVersion, amount, nonce, deadline, v, r, s);
    }
    
    function _swapTokensForEth(address token, uint256 amount) public {
        swapTokensForEth(token, amount);
    }
    
    function _sendETHMinusFee(address payable receiver, uint256 ethReceived, uint256 startingGas) public {
        sendETHMinusFee(receiver, ethReceived, startingGas);
    }

    function _sendETHToReceiver(address payable receiver, uint256 amount) public {
        sendETHToReceiver(receiver, amount);
    }

    function setUniRouter(address addr) public {
        uniswapRouter = IUniswapV2Router02(addr);
    }
    
}