module dacade_pre_market::oracle {
  // === Imports ===

  use switchboard::aggregator::{Self, Aggregator};
  use switchboard::math;

  use sui::math as sui_math;
  use sui::clock:: {Clock, timestamp_ms};
  use sui::object:: {Self, UID};
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};

  use std::vector;

  // === Errors ===

  const EPriceIsNegative: u64 = 0;
  const EValueIsNegative: u64 = 1;
  const EInvalidTimeStamp: u64 = 2;
  const EFeedNotWhitelisted:u64 = 3;

  // === Structs ===

  public struct Price {
    latest_result: u128,
    scaling_factor: u128,
    latest_timestamp: u64,
  }

  public struct Aggregators has key {
    id: UID,
    whitelist: vector<address>
  }

  fun init(ctx: &mut TxContext) {
    transfer::share_object(
      Aggregators{
         id:object::new(ctx),
        whitelist: vector::empty(),
      },
    );
  }

  // === Public-Mutative Functions ===

  public fun new(feed: &Aggregator, aggregator: &mut Aggregators, clock: &Clock): Price {
    let (latest_result, latest_timestamp) = aggregator::latest_value(feed);
    let (value, scaling_factor, neg) = math::unpack(latest_result);
    let current_timestamp = timestamp_ms(clock);
    let is_whitelisted = vector::contains(&aggregator.whitelist, &aggregator::aggregator_address(feed));

    assert!(is_whitelisted, EFeedNotWhitelisted); 
    assert!(value > 0, EValueIsNegative);
    assert!(!neg, EPriceIsNegative);

    Price {
      latest_result: value,
      scaling_factor: (sui_math::pow(10, scaling_factor) as u128),
      latest_timestamp
    }
  }

  public fun destroy(self: Price): (u128, u128, u64) {
    let Price { latest_result, scaling_factor, latest_timestamp } = self;
    (latest_result, scaling_factor, latest_timestamp)
  }

  public fun add_to_whitelist(feed: &Aggregator, aggregatorself: &mut Aggregators) {
     vector::push_back(&mut aggregatorself.whitelist, aggregator::aggregator_address(feed));
  }

  // === Test Functions ===

  #[test_only]
  
  public fun new_for_testing(latest_result: u128, scaling_factor: u128, latest_timestamp: u64): Price {
    Price {
      latest_result,
      scaling_factor,
      latest_timestamp
    }
  }
}
