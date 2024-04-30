module dacade_pre_market::oracle {
  // === Imports ===
  use switchboard::aggregator::{Aggregator, self};
  use switchboard::math;

  use sui::{math as sui_math, clock::{Clock, timestamp_ms}, object::{self, UID}, transfer, tx_context::TxContext};

  use std::vector;

  // === Errors ===
  const EPriceIsNegative: u64 = 0;
  const EValueIsNegative: u64 = 1;
  const EInvalidTimeStamp: u64 = 2;
  const EFeedNotWhitelisted: u64 = 3;

  // === Structs ===
  public struct Price {
      latest_result: u128,
      scaling_factor: u128,
      latest_timestamp: u64,
  }

  public struct Aggregators has key {
      id: UID,
      whitelist: vector<address>,
  }

  // Initialization of the oracle
  fun init(ctx: &mut TxContext) {
      transfer::share_object(
        Aggregators {
          id: object::new(ctx),
          whitelist: vector::empty(),
        }
      );
  }

  // Creates a new price object from an aggregator feed
  public fun new(feed: &Aggregator, aggregator: &mut Aggregators, clock: &Clock): Price {
      assert!(vector::contains(&aggregator.whitelist, &aggregator::aggregator_address(feed)), EFeedNotWhitelisted);

      let (latest_result, latest_timestamp) = aggregator::latest_value(feed);
      assert!(latest_timestamp <= timestamp_ms(clock), EInvalidTimeStamp);

      let (value, scaling_factor, neg) = math::unpack(latest_result);
      assert!(value > 0, EValueIsNegative);
      assert!(!neg, EPriceIsNegative);

      Price {
          latest_result: value,
          scaling_factor: (sui_math::pow(10, scaling_factor) as u128),
          latest_timestamp
      }
  }

  // Destroys a price object and returns its contents
  public fun destroy(self: Price): (u128, u128, u64) {
      (self.latest_result, self.scaling_factor, self.latest_timestamp)
  }

  // Adds an aggregator address to the whitelist
  public fun add_to_whitelist(feed: &Aggregator, aggregator: &mut Aggregators) {
      vector::push_back(&mut aggregator.whitelist, aggregator::aggregator_address(feed));
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
