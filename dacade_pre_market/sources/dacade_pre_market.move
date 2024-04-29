module dacade_pre_market::simple_pre_market {
    /*
    This is a simple pre-market where users can freely buy and sell Coins without logging into the market,
    Administrators can create markets, and users can create orders and cancel orders.
    Users can also buy or sell Coins according to the description of the order.
    */

    /* Dependencies */
    use sui::event::{Self};
    use sui::bag::{Self, Bag};
    use std::type_name::{Self, TypeName};
    use std::string::{Self, String};
    use sui::coin::{Coin};
    use sui::dynamic_object_field as ofield;

    /* Error Constants */
    const EMisMatchOwner: u64 = 0;

    /* Structs */
    // admin capability struct
    public struct AdminCap has key, store {
        id: UID
    }

    // Market struct
    public struct Market has key {
        id: UID,
        items: Bag,
    }

    // Listing struct
    public struct Listing has key, store {
        id: UID,
        is_sell_order: bool,
        amount: u64,
        description: String,
        price: u64,
        owner: address,
        collateral: Coin<T>
    }

    /* Functions */
    fun init(ctx: &mut TxContext) {
        let admin = AdminCap {
            id: object::new(ctx)
        };
        let admin_address = tx_context::sender(ctx);
        transfer::transfer(admin, admin_address);
    }

    // Only admin can create a market
    public entry fun create_market(_: &AdminCap, ctx: &mut TxContext) {
        let market = Market {
            id: object::new(ctx),
            items: bag::new(ctx),
        };
        transfer::share_object(market);
    }

    // User can create a Buy order
    public entry fun create_buy_order<T>(
        market: &mut Market,
        amount: u64,
        collateral: Coin<T>,
        price: u64,
        description: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let mut listing = Listing {
            id: object::new(ctx),
            is_sell_order: false,
            amount,
            description: string::utf8(description),
            price,
            owner: tx_context::sender(ctx),
            collateral,
        };
        bag::add(&mut market.items, object::id(&listing), listing);
    }

    // User can create a Sell order
    public entry fun create_sell_order<T>(
        market: &mut Market,
        amount: u64,
        collateral: Coin<T>,
        price: u64,
        description: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let mut listing = Listing {
            id: object::new(ctx),
            is_sell_order: true,
            amount,
            description: string::utf8(description),
            price,
            owner: tx_context::sender(ctx),
            collateral,
        };
        bag::add(&mut market.items, object::id(&listing), listing);
    }

    // Order creator can cancel the order
    public entry fun cancel_order<T>(
        market: &mut Market,
        item_id: ID,
        ctx: &mut TxContext,
    ) {
        let Listing {
            id,
            is_sell_order: _,
            amount: _,
            description: _,
            price: _,
            owner,
            collateral,
        } = bag::remove<ID, Listing>(&mut market.items, item_id);
        assert!(owner == tx_context::sender(ctx), EMisMatchOwner);
        object::delete(id);
        transfer::public_transfer(collateral, tx_context::sender(ctx));
    }

    // Trade function
    public fun trade<T, U>(
        market: &mut Market,
        item_id: ID,
        trade_object: Coin<U>,
        ctx: &mut TxContext,
    ): Coin<T> {
        let Listing {
            id,
            is_sell_order: _,
            amount: _,
            description: _,
            price: _,
            owner,
            collateral,
        } = bag::remove<ID, Listing>(&mut market.items, item_id);
        transfer::public_transfer(trade_object, owner);
        object::delete(id);
        collateral
    }

    // Trade and take function
    public entry fun trade_and_take<T, U>(
        market: &mut Market,
        item_id: ID,
        trade_object: Coin<U>,
        ctx: &mut TxContext,
    ) {
        let collateral = trade<T, U>(market, item_id, trade_object, ctx);
        transfer::public_transfer(collateral, tx_context::sender(ctx));
    }
}
