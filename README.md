# PostgreSQL Web3 Demo

This is a demo of a PostgreSQL implementation to track token balances by address. It's configured to track ERC-20 and NFT balances.

## Setup

1. Setup a PostgreSQL database.
2. Run all of the queries in the 3 folders here to create and initialize the database tables and functions.
3. Setup event listeners to listen to the contracts that you'd like to track. [EVM Listeners Example](https://github.com/XDapps/ethers-event-listeners-lib)
4. When an event is detected:
   1. If it is an ERC-20 event, save the event data in the event_queue_erc20 table.
   2. If it is an NFT event, save the event data in the event_queue_nfts table.

That's it! The functions will update all of the values and move the event data to the archive tables. You can feed the same event multiple times and it will be ignored if it already exists in the archive table.

This allows you to go back and re-process events that you may have missed if you had an issue with your RPC connection etc... You can always re-process events with no worry of the counts being duplicated.

>[!NOTE]
>Any tokens that you choose to listen to you should start from when they were initially minted and go back and process all of the events from inception in >order to ensure that your balances are in sync with the chain
