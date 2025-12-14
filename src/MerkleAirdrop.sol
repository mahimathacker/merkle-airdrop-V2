// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {IERC20, SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;
    ///////////////
    ///Events///
    ///////////////
    event Claim(address indexed account, uint256 amount);

    //some list of addresses
    //allow someone to claim tokens if they are in the list
    ///////////////
    ///Errors///
    ///////////////
    error MerkleAirdrop__InvalidProof();

    error MerkleAirdrop__AlreadyClaimed();

    bytes32 public immutable i_merkleRoot;
    IERC20 public immutable i_airdroptoken;
    mapping(address claimer => bool claimed) public s_hasClaimed;

    constructor(bytes32 merkleRoot, IERC20 airdroptoken) {
        i_merkleRoot = merkleRoot;
        i_airdroptoken = IERC20(airdroptoken);
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount)))); //Hash twice removed collisions and prevent pre image attacks  //Multiple values → abi.encode, Single value or fixed structure → abi.encodePacked
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        i_airdroptoken.safeTransfer(account, amount);
    }

    ///////////////
    ///Getters///
    ///////////////
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdroptoken;
    }
}
