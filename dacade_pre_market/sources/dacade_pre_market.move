module dacade_pre_market::simple_pre_market {
    /*
    This is a simple pre market where users can freely buy and sell Coins without logging into the market,
    Administrators can create markets and users can create orders and cancel orders.
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
    const EInvalidOrder: u64 = 1;

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

    //Buy order struct
    public struct BuyOrder has key, store {
        id: UID,
        amount: u64,
        for_object: String,
        price: u64,
        owner: address,
    }

    //Sell order struct
    public struct SellOrder has key, store {
        id: UID,
        amount: u64,
        for_object: String,
        price: u64,
        owner: address,
    }

    //Order listed
    public struct Listed has copy, drop {
        order_id: UID,
        is_buy_order: bool,
        amount: u64,
        price: u64,
        for_object: String,
        collateral_type: TypeName,
        owner: address
    }

    /* Functions */
    fun init(ctx: &mut TxContext) {
        let admin = AdminCap {
            id: object::new(ctx)
        };
        let admin_address = tx_context::sender(ctx);
        transfer::transfer(admin, admin_address);
    }

    //only admin can create a market
    public entry fun create_market(_: &AdminCap, ctx: &mut TxContext) {
        let market = Market {
            id: object::new(ctx),
            items: bag::new(ctx),
        };
        transfer::share_object(market);
    }

    //User can create a Buy order
    public entry fun create_buy_order<T>(
        market: &mut Market,
        amount: u64,
        collateral: Coin<T>,
        price: u64,
        for_object: String,
        ctx: &mut TxContext,
    ) {
        let key = object::id(&collateral);
        let mut buy_order = BuyOrder {
            id: object::new(ctx),
            amount,
            for_object,
            price,
            owner: tx_context::sender(ctx),
        };
        ofield::add(&mut buy_order.id, true, collateral);
        bag::add(&mut market.items, key, buy_order);

        let listed = Listed {
            order_id: buy_order.id,
            is_buy_order: true,
            amount,
            for_object,
            price,
            collateral_type: type_name::get<Coin<T>>(),
            owner: tx_context::sender(ctx),
        };
        event::emit<Listed>(listed);
    }

    //User can create a Sell order
    public entry fun create_sell_order<T>(
        market: &mut Market,
        amount: u64,
        collateral: Coin<T>,
        price: u64,
        for_object: String,
        ctx: &mut TxContext,
    ) {
        let key = object::id(&collateral);
        let mut sell_order = SellOrder {
            id: object::new(ctx),
            amount,
            for_object,
            price,
            owner: tx_context::sender(ctx),
        };
        ofield::add(&mut sell_order.id, true, collateral);
        bag::add(&mut market.items, key, sell_order);

        let listed = Listed {
            order_id: sell_order.id,
            is_buy_order: false,
            amount,
            for_object,
            price,
            collateral_type: type_name::get<Coin<T>>(),
            owner: tx_context::sender(ctx),
        };
        event::emit<Listed>(listed);
    }

    //Order creator can cancel the order
    public entry fun cancel_order<T>(
        market: &mut Market,
        item_id: ID,
        ctx: &mut TxContext,
    ) {
        assert!(bag::contains(&market.items, item_id), EInvalidOrder);

        let (owner, collateral) = if (bag::contains_with_type<BuyOrder>(&market.items, item_id)) {
            let BuyOrder {
                mut id,
                amount: _,
                for_object: _,
                price: _,
                owner,
            } = bag::remove<ID, BuyOrder>(&mut market.items, item_id);
            (owner, ofield::remove<bool, Coin<T>>(&mut id, true))
        } else if (bag::contains_with_type<SellOrder>(&market.items, item_id)) {
            let SellOrder {
                mut id,
                amount: _,
                for_object: _,
                price: _,
                owner,
            } = bag::remove<ID, SellOrder>(&mut market.items, item_id);
            (owner, ofield::remove<bool, Coin<T>>(&mut id, true))
        } else {
            abort EInvalidOrder
        };

        assert!(owner == tx_context::sender(ctx), EMisMatchOwner);
        object::delete(id);
        transfer::public_transfer(collateral, tx_context::sender(ctx));
    }

    //trade function
    public fun trade<T, U>(
        market: &mut Market,
        item_id: ID,
        trade_object: Coin<U>,
        ctx: &mut TxContext,
    ): (bool, Coin<T>) {
        assert!(bag::contains(&market.items, item_id), EInvalidOrder);

        let (price, collateral) = if (bag::contains_with_type<BuyOrder>(&market.items, item_id)) {
            let BuyOrder {
                mut id,
                amount,
                for_object: _,
                price,
                owner,
            } = bag::remove<ID, BuyOrder>(&mut market.items, item_id);
            let trade_value = coin::value(&trade_object);
            let expected_value = price * amount;
            if (trade_value < expected_value) {
                bag::add(&mut market.items, item_id, BuyOrder { id, amount, for_object: _, price, owner });
                return (false, Coin {})
            };
            transfer::public_transfer(trade_object, owner);
            let collateral = ofield::remove<bool, Coin<T>>(&mut id, true);
            object::delete(id);
            (price, collateral)
        } else if (bag::contains_with_type<SellOrder>(&market.items, item_id)) {
            let SellOrder {
                mut id,
                amount,
                for_object: _,
                price,
                owner,
            } = bag::remove<ID, SellOrder>(&mut market.items, item_id);
            let trade_value = coin::value(&trade_object);
            let expected_value = price * amount;
            if (trade_value < expected_value) {
                bag::add(&mut market.items, item_id, SellOrder { id, amount, for_object: _, price, owner });
                return (false, Coin {})
            };
            transfer::public_transfer(trade_object, owner);
            let collateral = ofield::remove<bool, Coin<T>>(&mut id, true);
            object::delete(id);
            (true, collateral)
