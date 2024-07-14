//:!:>moon
module aptos_asset::meta_coin {
    use std::signer;
    use std::string;
    use aptos_framework::coin;

    const ENOT_ADMIN:u64=0;
    const E_DONT_HAVE_CAPABILITY:u64=1;
    const E_HAVE_CAPABILITY:u64=2;
    const ENOT_ENOUGH_TOKEN:u64=3;

    struct METACoin has key {}

    struct Coinabilities has key{
        mint_cap: coin::MintCapability<METACoin>,
        burn_cap: coin::BurnCapability<METACoin>,
        freeze_cap: coin::FreezeCapability<METACoin>
    }

    public fun is_admin(addr:address){
        assert!(addr==@aptos_asset,ENOT_ADMIN);
    }
    public fun has_coin_capabilities(addr:address){
        assert!(exists<Coinabilities>(addr),E_DONT_HAVE_CAPABILITY);
    }
    public fun not_has_coin_capabilities(addr:address){
        assert!(!exists<Coinabilities>(addr),E_HAVE_CAPABILITY);
    }

    fun init_module(sender: &signer) {
        let account_addr = signer::address_of(sender);
        is_admin(account_addr);
        not_has_coin_capabilities(account_addr);
        let (burn_cap,freeze_cap,mint_cap) = coin::initialize<METACoin>(
            sender,
            string::utf8(b"Meta Coin"),
            string::utf8(b"META"),
            8,
            true,
        );
        move_to(sender,Coinabilities{mint_cap, burn_cap, freeze_cap});
    }

    public entry fun register(account: &signer){
        coin::register<METACoin>(account);
    }

    public entry  fun mint(account:&signer,dst_addr:address,amount:u64) acquires Coinabilities{
        let account_addr = signer::address_of(account);
        is_admin(account_addr);
        has_coin_capabilities(account_addr);
        let mint_cap = &borrow_global<Coinabilities>(account_addr).mint_cap;
        let coins = coin::mint<METACoin>(amount,mint_cap);
        coin::deposit<METACoin>(dst_addr,coins);
    }

    public entry fun burn(account:&signer,amount:u64) acquires Coinabilities{
        let account_addr = signer::address_of(account);
        is_admin(account_addr);
        has_coin_capabilities(account_addr);
        assert!(coin::balance<METACoin>(account_addr)>=amount,ENOT_ENOUGH_TOKEN);
        let burn_cap = &borrow_global<Coinabilities>(account_addr).burn_cap;
        let coins = coin::withdraw<METACoin>(account,amount);
        coin::burn<METACoin>(coins,burn_cap);

    }

    public entry fun transfer(from:&signer,to:address,amount:u64){
        let from_addr = signer::address_of(from);
        assert!(coin::balance<METACoin>(from_addr)>=amount,ENOT_ENOUGH_TOKEN);
        coin::transfer<METACoin>(from,to, amount);
    }

    public entry fun freeze_user(account: &signer, user: address) acquires Coinabilities {
        let account_addr = signer::address_of(account);
        is_admin(account_addr);
        has_coin_capabilities(account_addr);

        let freeze_cap = &borrow_global<Coinabilities>(account_addr).freeze_cap;
        coin::freeze_coin_store<METACoin>(user, freeze_cap);
    }

    public entry fun unfreeze_user(account: &signer, user: address) acquires Coinabilities {
        let account_addr = signer::address_of(account);
        is_admin(account_addr);
        has_coin_capabilities(account_addr);

        let freeze_cap = &borrow_global<Coinabilities>(account_addr).freeze_cap;
        coin::unfreeze_coin_store<METACoin>(user, freeze_cap);
    }

}