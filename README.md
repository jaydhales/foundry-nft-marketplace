# Project Requirement Document (PRD) - NFT Marketplace Smart Contract

## Project Overview

- **Project Name:** NFT Marketplace Smart Contract

### Function: createOrder

**Description:** This function allows users to create a new listing for an NFT in the marketplace.

- **Set order creator to msg.sender**
- **Token Address:** The address of the NFT.
- **Token ID:** The unique identifier of the NFT.
- **Price:**
- **Signature (Sign):** The digital signature for verifying the authenticity of the order(the hash of the token address,tokenId,price,owner etc).
- **Deadline:**

**Preconditions:**

- **Owner Check:**
  - Verify that the message sender is the owner of the NFT using `ownerOf()`.
  - Verify that the message sender has approved `address(this)` to spend the NFT using `isApprovedForAll()`.
- **Token Address Check:**

  - Ensure that the token address is not equal to `address(0)`.

- **Price Check:**

  - Confirm that the price is greater than 0.

- **Deadline Check:**
  - Ensure the block.timestamp + deadline (Current time + duration) is greater than `block.timestamp`.

**Logic:**

- Store the order data in storage.
- Increment the order ID for listings.
- Emit an event to notify users of the new listing `OrderListed()`.

### Function: executeOrder (payable)

**Description:** This function allows users to execute a listing by purchasing an NFT from the marketplace.

- **Listing ID:** The unique identifier of the listing.

**Preconditions:**

- **Listing ID Check:**

  - Verify that the listing ID is less than the public counter.

- **Value Check:**

  - Confirm that `msg.value` (the amount of ether sent) is equal to the listing price.

- **Deadline Check:**

  - Verify that `block.timestamp` is less than or equal to the listing's deadline.

  - Verify that order is still active i.e `isActive = true`.

- **Signature Check:** Decode the address of the signer from the signature using `recover()` from ECDSA library.
- Verify that signer retrieved is creator of Order.

**Logic:**

- Retrieve the order data from storage.
- Disable the order(order.isActive = false)
- Transfer the ether from the buyer to the seller.
- Transfer the NFT from the seller to the buyer.
- Emit an event to notify users of the executed order.

## 4. Architecture

The smart contract architecture consists of two main components:

- **Order Struct:** Defines the structure of an order, including its creator, token details, price, deadline, signature, and status.

- **Marketplace Contract:** Contains the functions for creating and executing orders, order verification, and various event logs.

## 5. Testing

Ensure that all the logic are properly tested.
