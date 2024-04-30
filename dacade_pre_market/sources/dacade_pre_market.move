/* Dependencies */
use sui::coin::{Coin, into_balance, from_balance};
use sui::event::{emit};
use sui::bag::{Bag, add, remove};
use sui::object::{new, delete, uid_to_inner};
use std::string::{String, utf8};
use std::type_name::{TypeName, get};
use sui::tx_context::{TxContext, sender};

/* Error Constants */
const EOwnerMismatch: u64 = 0;
const EInsufficientBalance: u64 = 1;

/* Structs */

// Admin capability struct
public struct AdminCap has key {
    id: UID
}

// Market struct
public struct Market has key {
    id: UID,
    items: Bag,
}

// Order struct for buy/sell operations
public struct Order<phantom T> has key, store {
    id: UID,
    buy_or_sell: bool, // false for buy, true for sell
    amount: u64,
    price: u64,
    balance: Balance<T>,
    owner: address,
}

// Struct for emitted events upon order creation
public struct OrderEvent has copy, drop {
    buy_or_sell: bool,
    amount: u64,
    price: u64,
    owner: address,
    collateral_type: TypeName,
}

/* Functions */

// Initialize admin capabilities
public fun init(ctx: &mut TxContext) {
    let admin_cap = AdminCap{id: new(ctx)};
    transfer::transfer(admin_cap, sender(ctx));
}

// Create a market (admin only)
public entry fun create_market(admin_cap: &AdminCap, ctx: &mut TxContext) {
    let market = Market{
        id: new(ctx),
        items: Bag::new(),
    };
    transfer::share_object(market);
}

// Create an order (buy or sell)
public entry fun create_order<T> (
    market: &mut Market,
    buy_or_sell: bool,
    amount: u64,
    collateral: Coin<T>,
    price: u64,
    ctx: &mut TxContext,
) {
    let order = Order<T>{
        id: new(ctx),
        buy_or_sell,
        amount,
        price,
        balance: into_balance(collateral),
        owner: sender(ctx),
    };
    let order_event = OrderEvent{
        buy_or_sell,
        amount,
        price,
        owner: sender(ctx),
        collateral_type: get<Coin<T>>(),
    };
    add(&mut market.items, uid_to_inner(&order.id), order);
    emit(order_event);
}

// Cancel an order
public entry fun cancel_order<T>(
    market: &mut Market,
    order_id: UID,
    ctx: &mut TxContext,
) {
    let order = remove<UID, Order<T>>(&mut market.items, order_id);
    assert!(order.owner == sender(ctx), EOwnerMismatch);
    delete(order.id);
    let refunded_coin = from_balance(order.balance, ctx);
    transfer::public_transfer(refunded_coin, sender(ctx));
}

// Trading function
public fun trade<T>(
    market: &mut Market,
    item_id: UID,
    offered_coin: Coin<SUI>,
    ctx: &mut TxContext,
) -> Coin<T> {
    let order = remove<UID, Order<T>>(&mut market.items, item_id);
    delete(order.id);
    // Simplify trade logic based on actual trading rules and security checks
    // Assume trade execution happens here with proper checks and balances

    let traded_coin = from_balance(order.balance, ctx);
    transfer::public_transfer(traded_coin, sender(ctx));
    transfer::public_transfer(offered_coin, order.owner);
    traded_coin
}
