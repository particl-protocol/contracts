import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import Int64 "mo:base/Int64";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Order "mo:base/Order";
import Text "mo:base/Text";

import Types "types";

module {

    public func hydrateInvoice(invoice: Types._Invoice): Types.PendingInvoice {
        let pendingInvoice: Types.PendingInvoice = {
            cost=invoice.cost;
            size=invoice.size;
            sendingAccount= invoice.sendingAccount;
            receivingAccount= invoice.receivingAccount;
            principal=invoice.principal;
            var number = invoice.number;
            var bytesProcessed = 0;   
        };
    };
    
    public func isInvoiceOwner(caller: Text, invoicePrincipal: Text): () {
        assert(caller==invoicePrincipal);
    };

    public func arrayToBuffer<X>(array:[X]): Buffer.Buffer<X>{
        let c = array.size();
        var i=0;
        let x = Buffer.Buffer<X>(0);
        label l loop {
            if (i < c){
                x.add(array[i]);
                i+=1;    
            } else {
                break l;
            }
        };
        x;
    };

    public func hashNat(x:Nat): Hash.Hash {
        Text.hash(Nat.toText(x));
    };

    public func floatFromNat(x:Nat): Float {
        Float.fromInt64((Int64.fromNat64(Nat64.fromNat(x))));
    };

    public func sortBytes(bytes:Buffer.Buffer<Nat>): Buffer.Buffer<Nat> {
        func cmp(a:Nat, b:Nat): Order.Order {
            var order:Order.Order = #less;
            if (a < b) {
                order:= #less;
            };
            if (a == b){
                order:= #equal;
            };
            if (a > b){
                order:= #greater;
            };
            return order;
        };
        let buffer = Buffer.Buffer<Nat>(0);

        return arrayToBuffer<Nat>(Array.sort(bytes.toArray(), cmp));
    };

    public func transformBytesToNuclei(bytes:Buffer.Buffer<Nat>):(Buffer.Buffer<Types.Nucleus>){
        let nuclei = Buffer.Buffer<Types.Nucleus>(0);
        var start = bytes.get(0);
        var end = bytes.get(0);
        var i=0;


        while (i < bytes.size()) {
                var byte = bytes.get(i);
                if (i+1 < bytes.size()){
                    var nextByte = bytes.get(i+1);
                    if (byte+1 == nextByte) {
                        end := nextByte;                   
                    } else {
                        nuclei.add((start, end));
                        start := nextByte;
                        end := nextByte;
                    };  
                } else {
                    end := byte;
                    nuclei.add((start,end));
                };
            i := i+1;
        };
        return nuclei;
    };
};