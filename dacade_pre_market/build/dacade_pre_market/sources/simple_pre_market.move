module dacade_pre_market::simple_pre_market {
    /*
    This is a simple pre market where users can freely buy and sell Coins without logging into the market, 
    Administrators can create markets and users can create orders and cancel orders.
    Users can also buy or sell Coins according to the description of the oder.
    */

    /* Dependencies */
    use sui::event::{Self};
    use sui::bag::{Self,Bag};
    use std::type_name::{Self,TypeName};
    use std::string::{Self,String};
    use sui::coin::{Coin};
    use sui::dynamic_object_field as ofield;

    /* Error Constants */
    const EMisMatchOwner: u64 = 0;

    /* Structs */
    // admin capability struct
    public struct AdminCap has key {
        id: UID
    }

    // Market struct
    public struct Market has key {
        id: UID,
        items: Bag,
    }

    //Buy order or Sell order struct 
    //"buy_or_sell" is a bool type, setting false for buy,true for sell 
    public struct Listing has key, store{
        id: UID,
        buy_or_sell: bool,
        amount : u64,
        for_object: String,
        price: u64,
        owner: address,
    }

    //Order listed 
    public struct Listed has copy, drop{
        buy_or_sell: bool,
        amount : u64,
        price: u64,
        for_object: String,
        collateral_type: TypeName,
        owner: address
    }
 
    /* Functions */
    fun init (ctx: &mut TxContext) {
       transfer::transfer(AdminCap{id: object::new(ctx)}, ctx.sender());
    }

    //only admin can create a market
    public entry fun create_market(_: &AdminCap, ctx: &mut TxContext) {
        let market = Market{
            id: object::new(ctx),
            items: bag::new(ctx),
        };
        transfer::share_object(market);
    }

    //User can create a Buy order or Sell order
    public entry fun create_order<T> (
        market: &mut Market,
        buy_or_sell: bool,
        amount : u64,
        collateral: Coin<T>,
        price: u64,
        for_object: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let key = object::id(&collateral);
        let mut listing = Listing{
            id: object::new(ctx),
            buy_or_sell,
            amount,
            for_object: string::utf8(for_object),
            price,
            owner: tx_context::sender(ctx),
        };
        ofield::add(&mut listing.id,true,collateral);
        bag::add(&mut market.items,key,listing);

        let listed = Listed{
            buy_or_sell,
            amount,   
            for_object: string::utf8(for_object),
            price,
            collateral_type: type_name::get<Coin<T>>(),
            owner: tx_context::sender(ctx),
        };
        event::emit<Listed>(listed);
    }

    //Order creator can cancel the order 
    public entry fun cancel_order<T> (
        market: &mut Market,
        item_id: ID,
        ctx: &mut TxContext,
    ) {
        let Listing{
            mut id,
            buy_or_sell:_,
            amount:_,
            for_object:_,
            price:_,
            owner,
        } = bag::remove<ID,Listing>(&mut market.items,item_id);
        assert!(owner == tx_context::sender(ctx),EMisMatchOwner);
        let collateral = ofield::remove<bool,Coin<T>>(&mut id,true);
        object::delete(id);
        transfer::public_transfer(collateral,tx_context::sender(ctx));
    }

    //trade function 
    public fun trade<T,U>(
        market: &mut Market,
        item_id: ID,
        trade_object: Coin<U>,
        _ctx: &mut TxContext,
    ): Coin<T> {
        let Listing{
            mut id,
            //false for buy true for sell
            buy_or_sell:_,
            amount:_,
            for_object:_,
            price:_,
            owner,
        } = bag::remove<ID,Listing>(&mut market.items,item_id);
        transfer::public_transfer(trade_object,owner);
        let collateral = ofield::remove<bool,Coin<T>>(&mut id,true);
        object::delete(id);
        collateral
    }

    //trade and take function
    public entry fun trade_and_take<T ,U>(
        market: &mut Market,
        item_id: ID,
        trade_object: Coin<U>,
        ctx: &mut TxContext,
    ) {
        let collateral = trade<T,U>(market,item_id,trade_object,ctx);
        transfer::public_transfer(
            collateral,
            tx_context::sender(ctx)
        );
    }
}
