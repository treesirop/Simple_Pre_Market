export ADMIN=0x08fac7bc5b6c4402613dab4fcfb62934c3eef96c6b45480a3849cd2c3f0c73f7
export USER1=0x272c8f82d121fc366d022c9f58ba50239c5d6bf6003d5264b3d4172f406273a9
export USER2=0xbfa750442aa4041ac562b77b90dacf2e0aa146a1c73702c789343aa1192c56aa

#ADMIN:
sui client switch --address $ADMIN

#publish 
sui client publish --gas-budget 100000000

export PACKAGE_ID=0x3362a7cd914a3bbe0f6a62f923f2c40c38afd96beec0e0848c137bfab3e22a09
export ADMINCAP=0xb49b536195d70b21ff19dba99b0c3e84a382d179bf17ca291d6d9cb33e462ee3
export TREASURY_CAP_BTD=0x7d5cdb55b002ae954226a7b005e3671f025f837aed73d5b44d108237f625dbeb
export TREASURY_CAP_USDT=0x17cb3ece50fff72beabdf1c3c01baecaf6c1f0f934063bafb1ffbcdbebd3619c

#create market
sui client call --package $PACKAGE_ID \
--module simple_pre_market \
--function create_market \
--args $ADMINCAP \
--gas-budget 100000000

#get market id
export MARKET_ID=0xaf3d2467d25c6d2d54c4591eaccacd4bc826f537eefa645bc59c08ceec916c04

#Admin mint Coin<BTD> to USER1
sui client call --package $PACKAGE_ID \
--module btd \
--function mint \
--args $TREASURY_CAP_BTD 13 $USER1 \
--gas-budget 100000000

export BTD_TYPE=$PACKAGE_ID::btd::BTD
export USER1_COIN=0x6eed38cd9ad41bc9163ef67502768390f5bec5a28408ea5f8d441738c127a483

#Admin mint Coin<USDT> to USER2
sui client call --package $PACKAGE_ID \
--module usdt \
--function mint \
--args $TREASURY_CAP_USDT 13 $USER2 \
--gas-budget 100000000

export USDT_TYPE=$PACKAGE_ID::usdt::USDT
export USER2_COIN=0x106ca67293c9e1f8dc195a97c6751f6ea08a2d9b66d36f70312e686bd6d6225c

#switch USER1
sui client switch --address $USER1

#user1 create a sell order 
#sell 13 BTD,value of per BTD equals 1 USDT
sui client call --package $PACKAGE_ID \
--module simple_pre_market \
--function create_order \
--type-args $BTD_TYPE \
--args $MARKET_ID true 13 $USER1_COIN 1 "Coin<USDT>" \
--gas-budget 100000000

#user1 cancel order
sui client call --package $PACKAGE_ID \
--module simple_pre_market \
--function cancel_order \
--type-args $BTD_TYPE \
--args $MARKET_ID $USER1_COIN \
--gas-budget 100000000


#switch USER2
sui client switch --address $USER2

# trade and take
# USER2 buy BTD using USDT
sui client call --package $PACKAGE_ID \
--module simple_pre_market \
--function trade_and_take \
--type-args $BTD_TYPE $USDT_TYPE \
--args $MARKET_ID $USER1_COIN $USER2_COIN \
--gas-budget 100000000

