// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {PotterToken} from "../src/PotterToken.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public s_merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public s_amountToTransfer = 4 * 25 * 1e18;

    function deployMerkleAirdrop() public returns (MerkleAirdrop, PotterToken) {
        vm.startBroadcast();
        PotterToken token = new PotterToken();
        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(s_merkleRoot, IERC20(address(token)));
        token.mint(token.owner(), s_amountToTransfer);
        token.transfer(address(merkleAirdrop), s_amountToTransfer);
        vm.stopBroadcast();
        return (merkleAirdrop, token);
    }

    function run() public returns (MerkleAirdrop, PotterToken) {
        return deployMerkleAirdrop();
    }
}
