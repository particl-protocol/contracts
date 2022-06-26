import Buffer "mo:base/Buffer";  
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import ENV "../env";
import Fission "fission";
import Fusion "fusion";
import Storage "../storage/main";
import Types "libs/types"; 
import Utils "libs/utils";

actor Main {
    private var ICP_RECEIVING_ACCOUNT: Text = "lorem-ipsum"; 
    private let ONE_YEAR_IN_SECONDS: Nat = 31536000;
    private let BYTES_PER_GB: Float = 1073741824;
    private var CYCLES_COST_SECOND_GB: Nat = 127000;
    private var CYCLES_PER_XDR: Nat = 1000000000000;
    private var MAX_STORAGE: Nat = 5905580032;
    private let CYCLE_SHARE: Nat = 300_000_000_000;  // cycle share each bucket created
    private let FEES = {
        var MINT: Float = 20; // in percent
        var BASE: Float = 0; // in icp
    };

    private var owner: Principal = Principal.fromText(ENV.OWNER);
    private var storage :Types.IStorage  = actor(ENV.STORAGE_ACTOR);
    // private var nns: Types.NNSActor = actor(ENV.NNS_ACTOR);
    
    private var invoicesCounter: Nat = 0;
    private var tokensCounter: Nat = 0;
    private let invoices: Buffer.Buffer<Types.PendingInvoice> =  Buffer.Buffer<Types.PendingInvoice>(0);
    private let tmpTokens: HashMap.HashMap<Nat, Types.TMPToken> = HashMap.HashMap<Nat, Types.TMPToken>(1, Nat.equal, Utils.hashNat); // move from tmp to tokens after all chunks have been upload;
    private let tokens: HashMap.HashMap<Nat, Types.Token> = HashMap.HashMap<Nat, Types.Token>(1, Nat.equal, Utils.hashNat); 

    public shared func mint(data: Blob, metadata: Text, invoiceNumber: Nat, memo: Text, session: Text): async(Types.MintResponse) {
        let caller = session;
        let res = {
            var processed = 0;
            var token: ?Types.Token = null;
            var id = 0;
        };
        switch(_getInvoice(invoiceNumber)) {
            case null assert(false);
            case (?_invoice) {

                Utils.isInvoiceOwner(caller, _invoice.principal);
                assert(_checkPayment(_invoice, memo));
                assert(_invoice.bytesProcessed + data.size() <= _invoice.size);
                if (_invoice.bytesProcessed == 0){
                    var isFull: Bool = false;
                    try {
                        isFull := await storage.changeOffset(_invoice.size);
                    } catch (error) {
                        await _createStorage();
                        ignore await storage.changeOffset(_invoice.size);
                    };

                    let offset = await storage.getOffSet();
                    tmpTokens.put(_invoice.number, {
                        start = offset - _invoice.size;
                    });
                };
                let tmpToken = tmpTokens.get(_invoice.number);
                switch (tmpToken) {
                    case (?t) {

                        await storage.put(t.start + _invoice.bytesProcessed, data);
                        _invoice.bytesProcessed+=data.size();
                        res.processed := _invoice.bytesProcessed;
                        invoices.put(_invoice.number, _invoice);

                        if (_invoice.bytesProcessed == _invoice.size){

                            let _nuclei:Types.Nuclei = Buffer.Buffer<Types.Nucleus>(0);
                            _nuclei.add((t.start, t.start + _invoice.size));
                            let finalToken: Types.Token = {
                                id = tokensCounter;
                                nuclei = _nuclei.toArray();
                                owner = ?caller;
                                rootToken = null;
                                timestamp = Time.now();
                                metadata = metadata;
                                storage = Principal.fromActor(storage);
                            };
                            res.token := ?finalToken; 
                            
                            tokens.put(tokensCounter, finalToken); //creates the nft 
                            tokensCounter+=1;
                            //TODO: remove the invoice
                        };
                    };
                    case null {};
                };
            };
        };
        return {
            processed = res.processed;
            token = res.token;
        };
    };

    public shared func createInvoice(invoiceRequest: Types.InvoiceRequest, session: Text ): async(Types. Invoice){
        let caller = session;
        let _cost: Float = await _getMintingCost(invoiceRequest.size);
        let invoice = {
            size = invoiceRequest.size;
            sendingAccount = invoiceRequest.sendingAccount;
            receivingAccount = ICP_RECEIVING_ACCOUNT;
            cost = _cost;
            principal = caller;
            var number = invoicesCounter;
        };
        invoices.add(Utils.hydrateInvoice(invoice));
        invoicesCounter:=invoicesCounter+1;
        return {
            size = invoiceRequest.size;
            sendingAccount = invoiceRequest.sendingAccount;
            receivingAccount = ICP_RECEIVING_ACCOUNT;
            cost = _cost;
            principal = caller;
            number = invoice.number;
        };
    };
    
    public query func getTokens(ids: [Nat]): async([Types.Token]) {
        let ts: Buffer.Buffer<Types.Token> = Buffer.Buffer<Types.Token>(0);
        var i=0;
        label l loop {
            if (i < ids.size()){
                switch(tokens.get(ids[i])){
                    case null {};
                    case (?t) {
                        ts.add(t);
                        i+=1;
                    } 
                }
            } else {
                break l;
            }
        };
        ts.toArray();        
    };

    public query({caller}) func getUserTokens(session:Text): async([Types.Token]) {
        let caller = session;
        let ts: Buffer.Buffer<Types.Token> = Buffer.Buffer<Types.Token>(0);
        for (token in tokens.vals()){
            switch (token.owner){
                case null {};
                case (?o){
                    if (o == caller) {
                        ts.add(token)
                    };                
                }
            };
        };
        ts.toArray();        
    };

    public func getFileById(tokenId: Nat): async(?Blob) {
        switch (tokens.get(tokenId)){
            case null {null};
            case (?token) {
                switch (token.rootToken) {
                    case null {
                        let (n0, n1) = token.nuclei[0];
                        let file = await storage.get(n0, n1-n0); 
                        ?file;
                    };
                    case (?rt){
                        switch (tokens.get(rt)) {
                            case null {null};
                            case (?r)  {
                                let (n0, n1) = r.nuclei[0];
                                let _storage: Types.IStorage = actor(Principal.toText(r.storage));
                                let file = await _storage.get(n0, n1-n0);
                                ?file; 
                            };
                        };
                    };
                };
            };
        };
    };

    public shared func fission(tokenId: Nat, markers: [Nat], session: Text): async ((Types.Token, Types.Token)) {
        let caller = session;
        let token = tokens.get(tokenId);
        switch (token){
            case (?token) {
                switch (token.owner){
                    case (?owner) {
                        assert(owner == caller);
                        let (_nuclei1, _nuclei0) = Fission.reaction({
                            markersBytes= Utils.arrayToBuffer(markers);
                            nuclei = Utils.arrayToBuffer(token.nuclei);
                        });

                        let _token0 = {
                            timestamp= Time.now();
                            owner= ?caller;
                            rootToken= _getRootToken(token,tokenId);
                            metadata= token.metadata;
                            nuclei= _nuclei0;
                            id = tokensCounter;
                            storage = token.storage;
                        };
                        tokens.put(tokensCounter, _token0);
                        tokensCounter+=1;
                        let _token1 = {
                            timestamp= Time.now();
                            owner=?caller;
                            rootToken= _getRootToken(token,tokenId);
                            metadata = token.metadata;
                            nuclei = _nuclei1;
                            id = tokensCounter;
                            storage = token.storage;
                        };
                        tokens.put(tokensCounter, _token1);
                        tokensCounter+=1;
                        switch (token.rootToken){
                            case null {
                                let noRoot = {
                                    timestamp= token.timestamp;
                                    owner= null;
                                    rootToken= null;
                                    metadata = token.metadata;
                                    nuclei = token.nuclei;
                                    id = token.id;
                                    storage = token.storage;
                                };
                                tokens.put(noRoot.id, noRoot);
                            };
                            case (?rt) {
                                tokens.delete(tokenId);
                            }; 
                        };
                        (_token0, _token1);
                    };
                    case null throw(Error.reject("Not owner"));
                };
            };
            case null throw(Error.reject("Token not found"));
        };
    };

    public shared func fusion(tokenIds: [Nat], session:Text):async (?Types.Token) {
        let allNuclei = Buffer.Buffer<Types.Nuclei>(0);
        let caller = session;
        var i = 0;
        var rootTokenId = 0;
        var res: ?Types.Token = null;
        label l loop {
            if (i < tokenIds.size()){
                switch (tokens.get(tokenIds[i])){
                    case (?token) {
                        if(i==0){
                            switch (token.rootToken){
                                case null throw(Error.reject("Token is first order"));
                                case (?rtoken){
                                    rootTokenId := rtoken;
                                };
                            };
                        };
                        switch (token.rootToken){
                            case null throw(Error.reject("Token is first order"));
                            case (?rtoken){
                                assert(rtoken == rootTokenId);
                            };
                        };
                        let nuclei = Utils.arrayToBuffer<Types.Nucleus>(token.nuclei);
                        allNuclei.add(nuclei);
                    };
                    case (null) throw(Error.reject("Token not found"));
                };
                i+=1;
            } else {
                break l;
            };
        };

        let fused = Fusion.reaction(allNuclei).toArray();
        let (n0, n1) = fused[0];
        let rootToken = tokens.get(rootTokenId);
        switch (rootToken) { 
            case (?rt){
                let (m0, m1) = rt.nuclei[0];
                if (n0==m0 and n1==m1){ //check if it is first order again
                    let _rt: Types.Token = {
                        id = rootTokenId;
                        owner = ?caller;
                        timestamp = rt.timestamp;
                        nuclei = rt.nuclei;
                        metadata = rt.metadata;
                        rootToken = null;
                        storage = rt.storage;
                    };
                    tokens.put(rootTokenId, _rt);
                    res := ?_rt;
                } else {
                    let _token: Types.Token = {
                        id= tokensCounter;
                        timestamp = Time.now();
                        owner= ?caller;
                        rootToken = ?rootTokenId;
                        metadata = rt.metadata;
                        nuclei = fused;
                        storage = rt.storage;
                    };
                    tokens.put(tokensCounter,_token);
                    tokensCounter+=1;
                    res := ?_token;
                };
            };
            case null throw(Error.reject("Root token not found"));
        };
        i:=0;
        label k loop {
            if (i < tokenIds.size()){
                tokens.delete(tokenIds[i]);
                i+=1;
            } else {
                break k;
            };
        };
        res;      
    };

    public shared func healthCheck(): async(Nat, Nat){
        let cycles = Cycles.balance();
        let memoryLeft = await storage.getMemoryLeft();
        return (cycles, memoryLeft);
    };

    private func _createStorage(): async() {
        Cycles.add(CYCLE_SHARE);
        let _storage = await Storage.Storage();
        storage:=_storage;
        return;
    };

    private func _checkPayment(invoice: Types._Invoice, memo:Text): Bool {
        return true;
    };

    private func _getRootToken(token:Types.Token, tokenId: Nat): ?Nat{
        if (token.rootToken == null){
            return ?tokenId;
        } else {
            return token.rootToken;
        }
    };
    private func _yearlyXDRCostPerSize(size:Nat): Float {
        let xdrPerGb: Float = Utils.floatFromNat((ONE_YEAR_IN_SECONDS * CYCLES_COST_SECOND_GB) / CYCLES_PER_XDR);
        let yearlyXDRCostPerSize: Float = (xdrPerGb / BYTES_PER_GB)*Utils.floatFromNat(size);
    };

    private func _getMintingCost(size:Nat): async(Float) {
         let yearlyXDRCostPerSize = _yearlyXDRCostPerSize(size);
        //  let icpxdr = await nns.get_icp_xdr_conversion_rate();
         let cost: Float = FEES.BASE + (FEES.MINT/100)*yearlyXDRCostPerSize + yearlyXDRCostPerSize;
    };

    private func _getInvoice(invoiceNumber: Nat): ?Types.PendingInvoice {
        for (_invoice in invoices.vals()){
            if (_invoice.number == invoiceNumber) {
                return ?_invoice;
            };
        };
        null;
    };
};
