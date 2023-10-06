// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MarketPlace, Order} from "../src/MarketPlace.sol";
import "../src/MockNft.sol";
import "./Helper.sol";

contract MarketPlaceTest is Helpers {
    MarketPlace marketPlace;
    MockNft mockNft;

    event OrderListed(
        address indexed _owner,
        uint256 indexed _orderID,
        uint256 indexed price
    );
    event OrderExecuted(
        uint256 indexed _orderID,
        uint256 indexed price,
        address indexed _buyer
    );

    uint256 creatorPriv;
    uint256 spenderPriv;

    address creator;
    address spender;

    Order ord;

    function setUp() public {
        marketPlace = new MarketPlace();
        mockNft = new MockNft();

        (creator, creatorPriv) = mkaddr("CREATOR");
        (spender, spenderPriv) = mkaddr("SPENDER");

        switchSigner(creator);
        mockNft.safeMint(creator, 256);
    }

    function testTokenAddrNotZero() public {
        vm.expectRevert("Address can not be zero");
        marketPlace.createOrder(address(0), 256, 1 ether, 0, bytes(""));
    }

    function testPriceNotZero() public {
        vm.expectRevert("Price can not be zero");
        marketPlace.createOrder(address(mockNft), 256, 0, 0, bytes(""));
    }

    function testShortDeadline() public {
        vm.expectRevert("Deadline too short");
        marketPlace.createOrder(address(mockNft), 256, 2 ether, 500, bytes(""));
    }

    function testInvalidTokenID() public {
        vm.expectRevert();
        marketPlace.createOrder(
            address(mockNft),
            246,
            1 ether,
            3700,
            bytes("")
        );
    }

    function testNotOwner() public {
        switchSigner(spender);
        vm.expectRevert("You do not own this nft");
        marketPlace.createOrder(
            address(mockNft),
            256,
            1 ether,
            3700,
            bytes("")
        );
    }

    function testNoApproval() public {
        vm.expectRevert("Permission not granted to spent this token");
        marketPlace.createOrder(
            address(mockNft),
            256,
            1 ether,
            3700,
            bytes("")
        );
    }

    function testCreateOrder() public {
        mockNft.setApprovalForAll(address(marketPlace), true);
        marketPlace.createOrder(
            address(mockNft),
            256,
            1 ether,
            5000,
            bytes("")
        );
        Order memory o = marketPlace.getOrder(0);
        assertEq(o.tokenAddress, address(mockNft));
        assertEq(o.tokenID, 256);
        assertEq(o.price, 1 ether);
        assertEq(o.sig, bytes(""));
        assertEq(o.deadline, block.timestamp + 5000);
        assertEq(o.creator, creator);
    }

    function testInvalidOrderId() public {
        _preOrder();
        vm.expectRevert(MarketPlace.Invalid_Order_Id.selector);
        marketPlace.executeOrder(15);
    }

    function testOrderExpired() public {
        _preOrder();
        vm.warp(6000);
        vm.expectRevert(MarketPlace.Order_Expired.selector);
        marketPlace.executeOrder(0);
    }

    function testIncorrectEther() public {
        _preOrder();
        vm.expectRevert(MarketPlace.Incorrect_Ether_Value.selector);
        marketPlace.executeOrder{value: 2 ether}(0);
    }

    function testExecuteOrder() public {
        _preOrder();
        switchSigner(spender);
        uint balanceBefore = spender.balance;
        marketPlace.executeOrder{value: 1 ether}(0);

        assertEq(mockNft.ownerOf(256), spender);
        assertEq(spender.balance, balanceBefore - 1 ether);
    }

    function testEmitExecuteEvent() public {
        _preOrder();
        vm.expectEmit(true, true, true, false);
        emit OrderExecuted(0, 1 ether, creator);
        marketPlace.executeOrder{value: 1 ether}(0);
    }

    function testEmitOrderEvent() public {
        mockNft.setApprovalForAll(address(marketPlace), true);
        vm.expectEmit(true, true, true, false);
        emit OrderListed(creator, 1, 1 ether);
        marketPlace.createOrder(
            address(mockNft),
            256,
            1 ether,
            5000,
            bytes("")
        );
    }

    function _preOrder() internal {
        mockNft.setApprovalForAll(address(marketPlace), true);
        bytes memory sig = constructSig(
            address(mockNft),
            256,
            1 ether,
            5000,
            creator,
            creatorPriv
        );

        marketPlace.createOrder(address(mockNft), 256, 1 ether, 5000, sig);
    }
}
