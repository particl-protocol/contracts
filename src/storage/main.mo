/// `--max-stable-pages <n>` (the default is 65536 PAGES, or 4GiB).
/// Each page is 64KiB (65536 bytes).
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import SM "mo:base/ExperimentalStableMemory";
import Text "mo:base/Int64";

shared({caller}) actor class Storage(){
    private let pageSize: Nat = 65536; // bytes
    private stable var offset: Nat = 0; // last memory location
    private let owner: Principal = caller;
    private let _MAX_STORAGE = 5905580032; // 5.5 G 5905580032;
    
    public shared({caller}) func changeOffset(size: Nat): async(Bool) {
        _isOwner(caller);
        let memoryLeft = _getMemoryLeftFromCurrentPages();
        if (_getMemoryLeftFromCurrentPages() < size){
            let isFull = _addMoreMemoryPages(size);
            offset+=(size +1);
            return isFull;
        } else {
            offset+=(size +1);
            return false
        };
    };

    public shared({caller}) func put(_offset: Nat, data: Blob): async() {
        SM.storeBlob(Nat64.fromNat(_offset), data);  
        return;
    };

    public shared({caller}) func get(_offset: Nat, length: Nat): async(Blob) {
        _isOwner(caller);
        SM.loadBlob(Nat64.fromNat(_offset), length);
    };

    public shared({caller}) func getOffSet(): async Nat {
        _isOwner(caller);
        offset;
    };

    public shared ({caller}) func getMemoryLeft(): async (Nat) {
        let totalMemoryPages: Nat64 = SM.size();
        let totalMemoryBytes: Nat64 = totalMemoryPages << 16;
        _MAX_STORAGE - Nat64.toNat(totalMemoryBytes);
    };

    private func _getMemoryLeftFromCurrentPages(): Nat { // in bytes
        let totalMemoryPages: Nat64 = SM.size();
        let totalMemoryBytes: Nat64 = totalMemoryPages << 16; // Every new page is zero-initialized
        let memoryLeft: Nat = Nat64.toNat(totalMemoryBytes - Nat64.fromNat(offset));
        memoryLeft;
    };

    private func _addMoreMemoryPages(size: Nat): Bool { // size is in bytes
        let memoryNeededInBytes: Nat = size - _getMemoryLeftFromCurrentPages();
        let memoryNeededInPages = Nat64.fromNat(memoryNeededInBytes) >> 16 + 1;
        if (memoryNeededInBytes + 1*pageSize + offset < _MAX_STORAGE){
            let lastPages = SM.grow(memoryNeededInPages);

            return false; // current bucket still has memory 
        } else {
            return true; // create new bucket;
        };
    };

    private func _isOwner(caller: Principal): () {
        assert(owner==caller);
    }; 
}