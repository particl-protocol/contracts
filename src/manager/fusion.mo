import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";

import Types "libs/types";
import Utils "libs/utils";

module {
    public func reaction(nucleis:Buffer.Buffer<Types.Nuclei>):Buffer.Buffer<Types.Nucleus>{
        let bytes = _transformNucleisToBytes(nucleis);
        let sorted = Utils.sortBytes(bytes);
        return Utils.transformBytesToNuclei(sorted);
    };

    private func _transformNucleisToBytes(arrayOfNucleis: Buffer.Buffer<Types.Nuclei>): Buffer.Buffer<Nat> {
        let bytes = Buffer.Buffer<Nat>(0);
        for (nuclei in arrayOfNucleis.vals()){
            for (nucleus in nuclei.vals()){
                let (_nStart, _nEnd) = nucleus;
                var nStart = _nStart;
                var nEnd = _nEnd;
                while (nStart <= nEnd) {
                    bytes.add(nStart);
                    nStart:=nStart +1;
                };
            };
        };
        return bytes;
    }; 
}
