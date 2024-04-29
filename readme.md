## Deployment
export ADMIN=0x08fac7bc5b6c4402613dab4fcfb62934c3eef96c6b45480a3849cd2c3f0c73f7
export USER1=0x272c8f82d121fc366d022c9f58ba50239c5d6bf6003d5264b3d4172f406273a9
export USER2=0xbfa750442aa4041ac562b77b90dacf2e0aa146a1c73702c789343aa1192c56aa

### ADMIN:
sui client switch --address $ADMIN

### publish 
sui client publish --gas-budget 100000000

│ Published Objects:                                                                                                      
│  ┌──                                                                                                                    
│  │ PackageID: 0x80705f814d1eae76ff7a326db4256e8cf287dafbb50ea84d1a7a8faae87e7097                                        
│  │ Version: 1                                                                                                           
│  │ Digest: qYgL9yBd2h5bmJRbKEFVevTd2MMtZrwghoGUTrFvJWF                                                                  
│  │ Modules: btd, simple_pre_market, usdt    

export PACKAGE_ID=0x80705f814d1eae76ff7a326db4256e8cf287dafbb50ea84d1a7a8faae87e7097
export ADMINCAP=0xf0f51f32f09cb5fbe88b28d36ccc439e7bc0674c83ee02bd5eb34734522d33d7
export TREASURY_CAP_BTD=0x197439858e6cad56d8794581e1e84ac6f687489195cb15136ad6e18d13652f83
export TREASURY_CAP_USDT=0x9606bb68ec847d24679415dc80c897f890a4e34b755ff405c6955e533b96fec1

### create market
sui client call --package $PACKAGE_ID \
--module simple_pre_market \
--function create_market \
--args $ADMINCAP \
--gas-budget 100000000

┌──                                                                                                            │
│  │ ObjectID: 0x088d157fa437074b2f02dbb1d5be5bf88187765f20910370f804bf534b5e343d                                 │
│  │ Sender: 0x08fac7bc5b6c4402613dab4fcfb62934c3eef96c6b45480a3849cd2c3f0c73f7                                   │
│  │ Owner: Shared                                                                                                │
│  │ ObjectType: 0x80705f814d1eae76ff7a326db4256e8cf287dafbb50ea84d1a7a8faae87e7097::simple_pre_market::Market    │
│  │ Version: 29171621                                                                                            │
│  │ Digest: Bu1341r4Kg5EYFZ3ttoe9L7qyRjVBrzXhaXsGyuoEfEG                                                         │
│  └──    

### get market id
export MARKET_ID=0x088d157fa437074b2f02dbb1d5be5bf88187765f20910370f804bf534b5e343d

### Admin mint Coin<BTD> to USER1
sui client call --package $PACKAGE_ID \
--module btd \
--function mint \
--args $TREASURY_CAP_BTD 13 $USER1 \
--gas-budget 100000000

export BTD_TYPE=$PACKAGE_ID::btd::BTD
export USER1_COIN=0xf9460bbf73ce0ba5a7c393bccd7bfbad4ab4f70371a98fd1b1e15532071a99f7

### Admin mint Coin<USDT> to USER2
sui client call --package $PACKAGE_ID \
--module usdt \
--function mint \
--args $TREASURY_CAP_USDT 13 $USER2 \
--gas-budget 100000000

export USDT_TYPE=$PACKAGE_ID::usdt::USDT
export USER2_COIN=0x81d7442c676ff31cf073f4cde3d6b9d25731acd85e023e9ef4f122679def5eee

### switch USER1
sui client switch --address $USER1

### user1 create a sell order 
### sell 13 BTD,value of per BTD equals 1 USDT
sui client call --package $PACKAGE_ID \
--module simple_pre_market \
--function create_order \
--type-args $BTD_TYPE \
--args $MARKET_ID true 13 $USER1_COIN 1 "Coin<USDT>" \
--gas-budget 100000000


### user1 cancel order
sui client call --package $PACKAGE_ID \
--module simple_pre_market \
--function cancel_order \
--type-args $BTD_TYPE \
--args $MARKET_ID $USER1_COIN \
--gas-budget 100000000


### switch USER2
sui client switch --address $USER2

### trade and take
### USER2 buy BTD using USDT
sui client call --package $PACKAGE_ID \
--module simple_pre_market \
--function trade_and_take \
--type-args $BTD_TYPE $USDT_TYPE \
--args $MARKET_ID $USER1_COIN $USER2_COIN \
--gas-budget 100000000


