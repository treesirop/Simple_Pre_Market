module dacade_pre_market::btd {
    use sui::coin::{Self,TreasuryCap,Coin};
    
    public struct BTD has drop {}

    fun init(witness:BTD, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<BTD>(witness, 0, b"BTD", b"MY", b"", option::none(), ctx);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    // Manager can mint new coins
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<BTD>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    /// Manager can burn coins
    public entry fun burn(treasury_cap: &mut TreasuryCap<BTD>, coin: Coin<BTD>) {
        coin::burn(treasury_cap, coin);
    }

}