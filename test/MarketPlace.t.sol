// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MarketPlace, Order} from "../src/MarketPlace.sol";
import "openzeppelin/interfaces/IERC721.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";

interface IMockNft is IERC721 {
    function safeMint(address to, uint256 tokenId) external;
}

contract MarketPlaceTest is Test {
    using ECDSA for bytes32;

    MarketPlace public marketPlace;
    uint256 internal creatorPriv;
    uint256 internal spenderPriv;
    address creator;
    address tokenAddress;
    uint256 tokenID;
    uint256 price;
    uint256 deadline;
    bytes signature;

    function setUp() public {
        marketPlace = new MarketPlace();

        creatorPriv = 67890;
        spenderPriv = 23423;
        creator = vm.addr(creatorPriv);
        tokenAddress = 0xAc4D78798804e2463E7785698d51239CfA768DAd;
        tokenID = 2972;
        price = 2 ether;
        deadline = 2 days;

        IMockNft(tokenAddress).safeMint(creator, tokenID);
        vm.startPrank(creator);
        bytes32 hashMsg = marketPlace.genHash(tokenAddress, tokenID, price, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(creatorPriv, hashMsg.toEthSignedMessageHash());
        signature = abi.encodePacked(r, s, v);
    }

    function testSig() public {
        bytes32 hashMsg = marketPlace.genHash(tokenAddress, tokenID, price, deadline);
        bytes32 _ethSignedMsg = hashMsg.toEthSignedMessageHash();
        address owner = _ethSignedMsg.recover(signature);
        assertEq(owner, creator);
    }

    function testApproval() public {
        vm.expectRevert(bytes("Permission not granted to spent this token"));
        _create();
    }

    function testCRPriceNotZero() public {
        _preloadOrder();
        vm.expectRevert(bytes("Empty Price not allowed"));
        marketPlace.createOrder(tokenAddress, tokenID, 0, deadline, signature);
    }

    function testCRNotZero() public {
        _preloadOrder();
        vm.expectRevert(bytes("Address can not be zero"));
        marketPlace.createOrder(address(0), tokenID, price, deadline, signature);
    }

    function testNotTokenOwner() public {
        _preloadOrder();
        vm.expectRevert(bytes("ERC721: invalid token ID"));
        marketPlace.createOrder(tokenAddress, 200, price, deadline, signature);

        vm.expectRevert(bytes("You do not own this nft"));
        marketPlace.createOrder(0xbF9399725B4ef6B872a13C87257b99a77caf34e8, 1, price, deadline, signature);
    }

    function testCreateOrder() public {
        _preloadOrder();

        _create();

        Order memory _order = marketPlace.getOrder(0);

        assertEq(_order.tokenAddress, tokenAddress);
        assertEq(_order.tokenID, tokenID);
        assertEq(_order.price, price);
        assertEq(_order.deadline, block.timestamp + deadline);
        assertEq(_order.sig, signature);
        assertEq(_order.creator, creator);
        assertTrue(_order.isActive);
        assertEq(marketPlace.orderCount(), 1);
    }

    // function testEventOrderListed() public {
    //     _preloadOrder();
    //     vm.expectEmit(creator, marketPlace.orderCount(), price );
    //      marketPlace.createOrder(tokenAddress, tokenID, price, deadline, signature);

    // }

    // function testExecuteOrder() public {
    //     _preloadOrder();
    //     _create();

    //     address spender = vm.addr(spenderPriv);
    //     deal(spender, 100 ether);
    //     vm.stopPrank();
    //     vm.startPrank(spender);

    //     marketPlace.executeOrder{value: price}(0);
    // }

    function _preloadOrder() internal {
        IMockNft _nft = IMockNft(tokenAddress);
        _nft.setApprovalForAll(address(marketPlace), true);

        assertTrue(_nft.isApprovedForAll(creator, address(marketPlace)));
    }

    function _create() internal {
        marketPlace.createOrder(tokenAddress, tokenID, price, deadline, signature);
    }
}
