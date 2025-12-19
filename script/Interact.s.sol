// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract Interact is Script {

    error __Interact__InvalidSignatureLength();

    address public CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public CLAIMING_AMOUNT = 25 * 1e18;
    bytes32 public PROOF_1 = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 public PROOF_2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [PROOF_1, PROOF_2];
    bytes private SIGNATURE =
        hex"6c576a2bcd6ec720be706c4a336ac69c3cfee293689bca8205e9ff240e2d69c50084e9509ae54535c86062b05a91e5da8bb22d517e7f72ba879823fd3f56c9361b";

  function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
    if(sig.length != 65) {
        revert __Interact__InvalidSignatureLength();
    }
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
  }

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        // bytes32 digest = MerkleAirdrop(airdrop).getMessage(CLAIMING_ADDRESS, CLAIMING_AMOUNT);

        MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, PROOF, v, r, s);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecent = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecent);
        MerkleAirdrop merkleAirdrop = MerkleAirdrop(mostRecent);
    }
}
