import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

module {
    public type MintResponse = {
        processed: Nat;
        token: ?Token;
    };
    public type InvoiceRequest = {
        size: Nat;
        sendingAccount: Text;
    };

    public type _Invoice = InvoiceRequest and {
        cost: Float;
        principal: Text;
        receivingAccount: Text;
        var number: Nat;
    };

    public type Invoice = InvoiceRequest and {
        cost: Float;
        principal: Text;
        number: Nat;
    };

    public type PendingInvoice = _Invoice and {
        var bytesProcessed: Nat
    };

    public type TMPToken = {
        start: Nat;
    };
                        // start end
    public type Nucleus = (Nat, Nat);

    public type Nuclei = Buffer.Buffer<Nucleus>;

    public type Token = {
        id: Nat;
        nuclei: [Nucleus];
        rootToken: ?Nat;
        owner: ?Text;
        timestamp: Int;
        metadata: Text;
        storage: Principal;
    };

    public type IStorage = actor {
        changeOffset:(size:Nat) -> async(Bool);
        put:(_offset: Nat, data: Blob)-> async();
        get:( _offset: Nat, length: Nat)-> async(Blob);
        getOffSet:()-> async Nat;
        getMemoryLeft:() -> async(Nat);
    };
    
    public type IcpXdrConversionRateCertifiedResponse = {
        certificate : [Nat8];
        data : IcpXdrConversionRate;
        hash_tree : [Nat8];
    };
    public type IcpXdrConversionRate = {
    xdr_permyriad_per_icp : Nat64;
    timestamp_seconds : Nat64;
    };
    
    public type NNSActor = actor { get_icp_xdr_conversion_rate : () -> async IcpXdrConversionRateCertifiedResponse };

};