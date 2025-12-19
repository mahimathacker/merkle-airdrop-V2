// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {PotterToken} from "../src/PotterToken.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    MerkleAirdrop public merkleAirdrop;
    PotterToken public token;
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];

    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address user;
    uint256 userPrivateKey;
    address public gasPayer;

    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (merkleAirdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            token = new PotterToken();
            merkleAirdrop = new MerkleAirdrop(ROOT, token);
            token.mint(token.owner(), AMOUNT_TO_SEND);
            token.transfer(address(merkleAirdrop), AMOUNT_TO_SEND);
        }
        (user, userPrivateKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function testUsersCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);
        bytes32 digest = merkleAirdrop.getMessage(user, AMOUNT_TO_CLAIM);

        //User signs the message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        //the gas payer calls using this signed message on behaf of the user
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        uint256 endingBalance = token.balanceOf(user);
        console.log("endingBalance", endingBalance);
        assertEq(endingBalance, startingBalance + AMOUNT_TO_CLAIM);
    }
}
