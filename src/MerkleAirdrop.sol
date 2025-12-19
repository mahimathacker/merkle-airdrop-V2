// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {IERC20, SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
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
    error MerkleAirdrop__InvalidSignature();

    bytes32 public immutable i_merkleRoot;
    IERC20 public immutable i_airdroptoken;
    mapping(address claimer => bool claimed) public s_hasClaimed;
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    constructor(bytes32 merkleRoot, IERC20 airdroptoken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdroptoken = IERC20(airdroptoken);
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        //Check the signature
        if (!_isValidSignature(account, getMessage(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount)))); //Hash twice removed collisions and prevent pre image attacks  //Multiple values → abi.encode, Single value or fixed structure → abi.encodePacked
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        i_airdroptoken.safeTransfer(account, amount);
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }

    ///////////////
    ///Getters///
    ///////////////

    function getMessage(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdroptoken;
    }
}
