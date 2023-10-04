// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "openzeppelin/interfaces/IERC721.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";

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
    using ECDSA for bytes32;

    event OrderListed(address indexed _owner, uint256 indexed _orderID, uint256 indexed price);
    event OrderExecuted(uint256 indexed _orderID, uint256 indexed price, address indexed _buyer);

    uint256 public orderCount;
    mapping(uint256 => Order) orders;

    function genHash(address tokenAddress, uint256 tokenID, uint256 price, uint256 deadline)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenAddress, tokenID, price, deadline, msg.sender));
    }

    function createOrder(
        address tokenAddress,
        uint256 tokenID,
        uint256 price,
        uint256 deadline,
        bytes calldata _signature
    ) external {
        require(tokenAddress != address(0), "Address can not be zero");
        require(price > 0, "Empty Price not allowed");
        IERC721 nft = IERC721(tokenAddress);
        require(nft.ownerOf(tokenID) == msg.sender, "You do not own this nft");
        require(nft.isApprovedForAll(msg.sender, address(this)), "Permission not granted to spent this token");

        orders[orderCount] =
            Order(msg.sender, tokenAddress, tokenID, price, block.timestamp + deadline, _signature, true);
        orderCount++;

        emit OrderListed(msg.sender, orderCount, price);
    }

    function executeOrder(uint256 _orderId) external payable {
        require(_orderId < orderCount, "Invalid order Id");

        Order storage _order = orders[_orderId];

        require(_order.deadline > block.timestamp, "Order expired");
        require(_order.isActive, "Order is no longer active");
        require(_order.price == msg.value, "Incorrect ether value");

        bytes32 message = genHash(_order.tokenAddress, _order.tokenID, _order.price, _order.deadline);
        bytes32 _ethSignedMsg = message.toEthSignedMessageHash();
        address owner = _ethSignedMsg.recover(_order.sig);

        require(owner == _order.creator, "Invalid Owner");

        _order.isActive = false;
        IERC721(_order.tokenAddress).safeTransferFrom(owner, msg.sender, _order.tokenID);
        payable(owner).transfer(msg.value);

        emit OrderExecuted(_orderId, _order.price, msg.sender);
    }

    function getOrder(uint256 _orderID) external view returns (Order memory _order) {
        _order = orders[_orderID];
    }
}
