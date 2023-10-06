// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "openzeppelin/interfaces/IERC721.sol";
import "./libs/SignUtils.sol";

struct Order {
    address creator;
    address tokenAddress;
    uint256 tokenID;
    uint256 price;
    uint256 deadline;
    bytes sig;
    bool isActive;
}

contract MarketPlace {
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

    error Invalid_Signature();
    error Invalid_Order_Id();
    error Order_Expired();
    error Order_Not_Active();
    error Incorrect_Ether_Value();

    uint256 public orderCount;
    mapping(uint256 => Order) orders;

    function createOrder(
        address tokenAddress,
        uint256 tokenID,
        uint256 price,
        uint256 deadline,
        bytes calldata _signature
    ) external {
        require(tokenAddress != address(0), "Address can not be zero");
        require(price > 0, "Price can not be zero");
        require(deadline > 3600, "Deadline too short");
        IERC721 nft = IERC721(tokenAddress);
        require(nft.ownerOf(tokenID) == msg.sender, "You do not own this nft");
        require(
            nft.isApprovedForAll(msg.sender, address(this)),
            "Permission not granted to spent this token"
        );

        orders[orderCount] = Order(
            msg.sender,
            tokenAddress,
            tokenID,
            price,
            block.timestamp + deadline,
            _signature,
            true
        );
        orderCount++;

        emit OrderListed(msg.sender, orderCount, price);
    }

    function executeOrder(uint256 _orderId) external payable {
        if (_orderId >= orderCount) revert Invalid_Order_Id();

        Order storage _order = orders[_orderId];

        if (_order.deadline < block.timestamp) revert Order_Expired();
        if (!_order.isActive) revert Order_Not_Active();
        if (_order.price != msg.value) revert Incorrect_Ether_Value();

        bytes32 message = SignUtils.constructMessageHash(
            _order.tokenAddress,
            _order.tokenID,
            _order.price,
            _order.deadline,
            _order.creator
        );

        bool _isValid = SignUtils.isValid(message, _order.sig, _order.creator);

        // if (!_isValid) revert Invalid_Signature();

        _order.isActive = false;
        IERC721(_order.tokenAddress).safeTransferFrom(
            _order.creator,
            msg.sender,
            _order.tokenID
        );
        payable(_order.creator).transfer(msg.value);

        emit OrderExecuted(_orderId, _order.price, msg.sender);
    }

    function getOrder(
        uint256 _orderID
    ) external view returns (Order memory _order) {
        _order = orders[_orderID];
    }
}
