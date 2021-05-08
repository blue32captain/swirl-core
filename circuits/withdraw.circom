include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/pedersen.circom";
include "merkleTree.circom";

// computes Pedersen(nullifier + secret)
template CommitmentHasher() {
    signal private input nullifier;
    signal private input secret;

    signal output commitment;
    signal output nullifierHash;

    component commitmentHasher = Pedersen(512);
    component nullifierHasher = Pedersen(256);
    component nullifierBits = Num2Bits(256);
    component secretBits = Num2Bits(256);
    nullifierBits.in <== nullifier;
    secretBits.in <== secret;
    for (var i = 0; i < 256; i++) {
        nullifierHasher.in[i] <== nullifierBits.out[i];
        commitmentHasher.in[i] <== nullifierBits.out[i];
        commitmentHasher.in[i + 256] <== secretBits.out[i];
    }

    commitment <== commitmentHasher.out[0];
    nullifierHash <== nullifierHasher.out[0];
}

// Verifies that commitment that corresponds to given secret and nullifier is included in the merkle tree of deposits
template Withdraw(levels, rounds) {
    signal input root;
    signal input nullifierHash;
    // TODO: Check if we need some kind of explicit constraints or something for those 2 inputs
    signal input receiver; // not taking part in any computations
    signal input fee; // not taking part in any computations
    signal private input nullifier;
    signal private input secret;
    signal private input pathElements[levels];
    signal private input pathIndex[levels];

    component hasher = CommitmentHasher();
    hasher.nullifier <== nullifier;
    hasher.secret <== secret;

    nullifierHash === hasher.nullifierHash;

    component tree = MerkleTree(levels, rounds);
    tree.leaf <== hasher.commitment;
    tree.root <== root;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== pathElements[i];
        tree.pathIndex[i] <== pathIndex[i];
    }
}

component main = Withdraw(16, 220);
