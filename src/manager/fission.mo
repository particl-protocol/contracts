import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";

import Types "libs/types";
import Utils "libs/utils";

module {

    public func reaction(args: ReactionArgs): ([Types.Nucleus], [Types.Nucleus]) {
        let nucleiBytes = _transformNucleisToOptBytes(args.nuclei);
        let markersBytes = Utils.sortBytes(_validateMarkers(args.markersBytes, args.nuclei));
        let token0Bytes = Buffer.Buffer<Nat>(0);
        let token1Bytes = Buffer.Buffer<Nat>(0);

        var lastMByteIndex = 0; 
        let lastByteInNuclei = nucleiBytes.get(nucleiBytes.size()-1); 
        
        label m for (mByte in markersBytes.vals()) {
            switch (lastByteInNuclei){
                case (?lastByteInNuclei) {
                    if (mByte <= lastByteInNuclei) {
                        var i = lastMByteIndex + 1;
                        label n while (i < nucleiBytes.size()) {
                            let current = nucleiBytes.get(i);
                            switch (current) {
                                case (?current) {
                                    if  (current == mByte ){
                                        token0Bytes.add(mByte);
                                        nucleiBytes.put(i, null);
                                        lastMByteIndex:= i;
                                        break n;
                                        continue m;
                                    };
                                };
                                case _ {};
                            };
                            i := i+1;
                        };
                    } else {
                        break m;
                    }
                };
                case _ {};
            };
        };
        
        for (byte in nucleiBytes.vals()){
            switch (byte) {
                case (?byte) {
                  token1Bytes.add(byte);  
                };
                case _ {};
            };
        };
        let nuclei0 = Utils.transformBytesToNuclei(token0Bytes);
        let nuclei1 = Utils.transformBytesToNuclei(token1Bytes);

        return (nuclei0.toArray(), nuclei1.toArray());
    };

    private func _transformNucleisToOptBytes(nucleis: Types.Nuclei): Buffer.Buffer<?Nat> {
        let bytes = Buffer.Buffer<?Nat>(0);
            for (nucleus in nucleis.vals()){
                let (_nStart, _nEnd) = nucleus;
                var nStart = _nStart;
                var nEnd = _nEnd;
                while (nStart <= nEnd) {
                    bytes.add(?nStart);
                    nStart:=nStart +1;
                };
            };
        return bytes;
    };   

    private func _validateMarkers(markers:Buffer.Buffer<Nat>, nucleis: Types.Nuclei): Buffer.Buffer<Nat>{
        let unique = HashMap.HashMap<Nat,Nat>(1, Nat.equal, Utils.hashNat);
        let validMarkers = Buffer.Buffer<Nat>(0);

        for (marker in markers.vals()){
            switch (unique.get(marker)){
                case (null){                        
                    for (nucleus in nucleis.vals()) {
                        let (n0,n1) = nucleus;
                        if (marker >= n0 and marker <= n1){
                            unique.put(marker, marker);
                            validMarkers.add(marker);
                        }
                    };                
                };
                case _{};
                
                };
        };
        assert(validMarkers.size() > 0);
        return validMarkers;
    };

    type ReactionArgs = {
        nuclei: Types.Nuclei;
        markersBytes: Buffer.Buffer<Nat>;
    };

};