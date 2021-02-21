// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// Standard ERC20 interface
interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// used by Uniswap tokens, USDC...
interface ERC20Permit0 is ERC20 {
    
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    
    function nonces(address owner) external view returns (uint256);
}

// used by DAI
interface ERC20Permit1 is ERC20 {

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    
    function nonces(address owner) external view returns (uint256);
    
}

/// @title Agent contract for executing transaction for behalf of users
/// @author Gašper Brvar
contract Agent {
    
    address payable public _owner;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    constructor(ERC20[] memory tokens) {
        approveTokens(tokens);
        _owner = payable(msg.sender);
    }
    
    /// @notice Will call permit function of token, claim tokens, trade them and return eth to receiver (minus a fee)
    /// @param token Address of token being transfered
    /// @param permitVersion Which permit version does the token use
    /// @param receiver Address that will recieve the Ether
    /// @param owner    - passed to permit function
    /// @param amount   - passed to permit function
    /// @param nonce    - passed to permit function
    /// @param deadline - passed to permit function
    /// @param v        - passed to permit function
    /// @param r        - passed to permit function
    /// @param s        - passed to permit function
    /// @param noRelay If a fee should be deducted or not
    /// @return status of transaction
    /// @dev set permitVersion to 1 if token is DAI and 0 if it is USDC / UNI ...
    /// @dev if user is manually sending the transaction useRealay should be set to false and no fee will be deducted
    function executeTransaction(
        address token,
        address owner,
        address payable receiver,
        uint8 permitVersion,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool noRelay
    ) public returns (bool) {
        
        uint256 startingGas = gasleft();
        
        claimTokens(ERC20(token), owner, permitVersion, amount, nonce, deadline, v, r, s);
        
        uint256 ethReceived = swapTokensForEth(token, amount);
        
        if (noRelay) {
            
            return sendETHToReceiver(receiver, ethReceived);

        } else {
            
            return sendETHMinusFee(receiver, ethReceived, startingGas);

        }
        
    }
    
    function claimTokens(
        ERC20 token,
        address owner,
        uint8 permitVersion,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        
        require(token.balanceOf(owner) >= amount);
        
        if (permitVersion == 0) {
            
            ERC20Permit0(address(token)).permit(owner, address(this), amount, deadline, v, r, s);
            
        } else if (permitVersion == 1) {
            
            ERC20Permit1(address(token)).permit(owner, address(this), nonce, deadline, true, v, r, s);
            
        }
        
        require(token.transferFrom(owner, address(this), amount));
        
    }
    
    function swapTokensForEth(address token, uint256 amount) internal returns (uint) {
        
        address[] memory path = new address[](2);
        
        path[0] = token;
        
        path[1] = uniswapRouter.WETH();
        
        uint[] memory amounts =  uniswapRouter.swapExactTokensForETH(amount, 0, path, address(this), block.timestamp);
        
        return amounts[amounts.length - 1];
    }
    
    function sendETHMinusFee(address payable receiver, uint256 ethReceived, uint256 startingGas) internal returns (bool) {
        
        uint256 etherFee = (/* 23000 +  */startingGas - gasleft()) * tx.gasprice * 2;
        
        if (etherFee < ethReceived) { // should always be true
           
            return sendETHToReceiver(receiver, ethReceived - etherFee);

        } else {

            return true;
            
        }

    }

    function sendETHToReceiver(address payable receiver, uint256 amount) internal returns (bool success) {
        (success, ) = receiver.call{value: amount, gas: 23000}("");
    }

    function transferOwnership(address payable newOwner) public {
        require(msg.sender == _owner);
        _owner = newOwner;
    }
    
    function withdrawToken(ERC20 token) public {
        token.transfer(_owner, token.balanceOf(address(this)));
    }
    
    function withdrawEther() public returns (bool, bytes memory) {
        return _owner.call{value: address(this).balance}("");
    }

    function approveTokens(ERC20[] memory tokens) public {
        for (uint i = 0; i < tokens.length; i++) {
            tokens[i].approve(address(uniswapRouter), uint256(-1));
        }
    }
    
    function exit() public {
        require(msg.sender == _owner);
        selfdestruct(_owner);
    }

    receive() external payable {}
    
}