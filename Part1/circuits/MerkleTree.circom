pragma circom 2.0.0;


include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";
//reference: https://github.com/appliedzkp/incrementalquintree/blob/master/circom/incrementalMerkleTree.circom


template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    var leafHash = (2**n) / 2;
    var innerTreeHash = leafHash - 1;
    var totalHash =  (2**n) - 1;
    component hashes[totalHash];
    var k = 0;

    for (var i=0; i < totalHash; i++) {
        hashes[i] = Poseidon(2);
    }
    for (var i=0; i < leafHash; i++){
        hashes[i].in[0] <== leaves[i*2];
        hashes[i].in[1] <== leaves[i*2+1];
    }
    for (var i=leafHash; i<leafHash + innerTreeHash; i++) {
        //left side is even, right side is odd
        hashes[i].in[0] <== hashes[k*2].hash;
        hashes[i].in[1] <== hashes[k*2+1].hash;
        k++;
    }

    root <== hashes[totalHash-1].hash;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component hashes[n];
    component mux[n];
    signal lvlHash[n + 1];
    
    lvlHash[0] <== leaf;

    for (var i = 0; i < n; i++) {
        path_index[i] * (1 - path_index[i]) === 0;
        hashes[i] = Poseidon(2);
        
        mux[i] = MultiMux1(2);
        mux[i].c[0][0] <== lvlHash[i];
        mux[i].c[0][1] <== path_elements[i];
        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== lvlHash[i];

        mux[i].s <== path_index[i];

        hashes[i].inputs[0] <== mux[i].out[0];
        hashes[i].inputs[1] <== mux[i].out[1];

        lvlHash[i + 1] <== hashes[i].out;
    }

    root <== lvlHash[n];
}