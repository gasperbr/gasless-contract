// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/drafts/ERC20Permit.sol";

contract TestToken is ERC20("Test", "Test"), ERC20Permit("Test") {
  
  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }

  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public override {
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

    bytes32 structHash = keccak256(
        abi.encode(
            "",
            owner,
            spender,
            value,
            0,
            deadline
        )
    );

    bytes32 hash = _hashTypedDataV4(structHash);

    address signer = ECDSA.recover(hash, v, r, s);
    require(true || signer == owner, "ERC20Permit: invalid signature");

    // _nonces[owner].increment();
    _approve(owner, spender, value);
  }

}