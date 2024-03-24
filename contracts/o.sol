// //SPDX-License-Identifier: Unlicense
// pragma solidity ^0.8.20;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// struct Token {
//     address token;
//     uint48 settleTime;
//     uint48 settleDuration;
//     uint152 settleRate; // number of token per point
//     uint8 status; //
// }

// struct Offer {
//     uint8 offerType;
//     bytes32 tokenId;
//     address exToken;
//     uint256 amount;
//     uint256 value;
//     uint256 collateral;
//     uint256 filledAmount;
//     uint8 status;
//     address offeredBy;
//     bool fullMatch;
// }

// struct Order {
//     uint256 offerId;
//     uint256 amount;
//     address seller;
//     address buyer;
//     uint8 status;
// }

// struct Config {
//     uint256 pledgeRate;
//     uint256 feeRefund;
//     uint256 feeSettle;
//     address feeWallet;
// }

// contract PreMarket is
//     Initializable,
//     OwnableUpgradeable,
//     AccessControlUpgradeable,
//     ReentrancyGuardUpgradeable
// {
//     using SafeERC20 for IERC20;

//     uint256 constant WEI6 = 10 ** 6;
//     uint8 constant OFFER_BUY = 1;
//     uint8 constant OFFER_SELL = 2;

//     // Status
//     // Offer status
//     uint8 constant STATUS_OFFER_OPEN = 1;
//     uint8 constant STATUS_OFFER_FILLED = 2;
//     uint8 constant STATUS_OFFER_CANCELLED = 3;

//     // Order Status
//     uint8 constant STATUS_ORDER_OPEN = 1;
//     uint8 constant STATUS_ORDER_SETTLE_FILLED = 2;
//     uint8 constant STATUS_ORDER_SETTLE_CANCELLED = 3;
//     uint8 constant STATUS_ORDER_CANCELLED = 3;

//     // token status
//     uint8 constant STATUS_TOKEN_ACTIVE = 1;
//     uint8 constant STATUS_TOKEN_INACTIVE = 2;
//     uint8 constant STATUS_TOKEN_SETTLE = 3;

//     bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

//     struct PreMarketStorage {
//         mapping(address => bool) acceptedTokens;
//         mapping(bytes32 => Token) tokens;
//         mapping(uint256 => Offer) offers;
//         uint256 lastOfferId;
//         mapping(uint256 => Order) orders;
//         uint256 lastOrderId;
//         Config config;
//     }

//     // keccak256(abi.encode(uint256(keccak256("loot.storage.PreMarket")) - 1)) & ~bytes32(uint256(0xff))
//     bytes32 private constant PreMarketStorageLocation =
//         0xe0eb0c6bc05973c9317c77fe5b658559f9e21630d35f19f70b8603a4f231f900;

//     function _getOwnStorage()
//         private
//         pure
//         returns (PreMarketStorage storage $)
//     {
//         assembly {
//             $.slot := PreMarketStorageLocation
//         }
//     }

//     // event

//     event NewOffer(
//         uint256 id,
//         uint8 offerType,
//         bytes32 tokenId,
//         address exToken,
//         uint256 amount,
//         uint256 value,
//         uint256 collateral,
//         bool fullMatch,
//         address doer
//     );
//     event NewToken(bytes32 tokenId, uint256 settleDuration);
//     event NewOrder(
//         uint256 id,
//         uint256 offerId,
//         uint256 amount,
//         address seller,
//         address buyer
//     );

//     event SettleFilled(
//         uint256 orderId,
//         uint256 value,
//         uint256 fee,
//         address doer
//     );
//     event SettleCancelled(
//         uint256 orderId,
//         uint256 value,
//         uint256 fee,
//         address doer
//     );

//     event CancelOrder(uint256 orderId, address doer);
//     event CancelOffer(
//         uint256 offerId,
//         uint256 refundValue,
//         uint256 refundFee,
//         address doer
//     );

//     event UpdateAcceptedTokens(address[] tokens, bool isAccepted);

//     event CloseOffer(uint256 offerId, uint256 refundAmount);

//     event UpdateConfig(
//         address oldFeeWallet,
//         uint256 oldFeeSettle,
//         uint256 oldFeeRefund,
//         uint256 oldPledgeRate,
//         address newFeeWallet,
//         uint256 newFeeSettle,
//         uint256 newFeeRefund,
//         uint256 newPledgeRate
//     );

//     event TokenToSettlePhase(
//         bytes32 tokenId,
//         address token,
//         uint256 settleRate,
//         uint256 settleTime
//     );
//     event UpdateTokenStatus(bytes32 tokenId, uint8 oldValue, uint8 newValue);
//     event TokenForceCancelSettlePhase(bytes32 tokenId);

//     event Settle2Steps(uint256 orderId, bytes32 hash, address doer);

//     event UpdateTokenSettleDuration(
//         bytes32 tokenId,
//         uint48 oldValue,
//         uint48 newValue
//     );

//     function initialize() public initializer {
//         __Ownable_init(msg.sender);
//         __AccessControl_init_unchained();
//         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         // init value
//         PreMarketStorage storage $ = _getOwnStorage();
//         $.config.pledgeRate = WEI6; // 1:1
//         $.config.feeWallet = owner();
//         $.config.feeSettle = WEI6 / 40; // 2.5%
//         $.config.feeRefund = WEI6 / 200; // 0.5%
//     }

//     ///////////////////////////
//     ////// SYSTEM ACTION //////
//     ///////////////////////////

//     function createToken(
//         bytes32 tokenId,
//         uint48 settleDuration
//     ) external onlyRole(OPERATOR_ROLE) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         require(settleDuration >= 24 * 60 * 60, "Minimum 24h for settling");
//         Token storage _token = $.tokens[tokenId];

//         _token.settleDuration = settleDuration;
//         _token.status = STATUS_TOKEN_ACTIVE;
//         emit NewToken(tokenId, settleDuration);
//     }

//     function tokenToSettlePhase(
//         bytes32 tokenId,
//         address tokenAddress,
//         uint152 settleRate // how many token for 1M points
//     ) external onlyRole(OPERATOR_ROLE) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Token storage _token = $.tokens[tokenId];
//         require(tokenAddress != address(0), "Invalid Token Address");
//         require(settleRate > 0, "Invalid Settle Rate");
//         require(
//             _token.status == STATUS_TOKEN_ACTIVE ||
//                 _token.status == STATUS_TOKEN_INACTIVE,
//             "Invalid Token Status"
//         );
//         _token.token = tokenAddress;
//         _token.settleRate = settleRate;
//         // update token settle status & time
//         _token.status = STATUS_TOKEN_SETTLE;
//         _token.settleTime = uint48(block.timestamp);

//         emit TokenToSettlePhase(
//             tokenId,
//             tokenAddress,
//             settleRate,
//             block.timestamp
//         );
//     }

//     function tokenToggleActivation(
//         bytes32 tokenId
//     ) external onlyRole(OPERATOR_ROLE) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Token storage _token = $.tokens[tokenId];
//         uint8 fromStatus = _token.status;
//         uint8 toStatus = fromStatus == STATUS_TOKEN_ACTIVE
//             ? STATUS_TOKEN_INACTIVE
//             : STATUS_TOKEN_ACTIVE;

//         require(
//             fromStatus == STATUS_TOKEN_ACTIVE ||
//                 fromStatus == STATUS_TOKEN_INACTIVE,
//             "Cannot Change Token Status"
//         );

//         _token.status = toStatus;
//         emit UpdateTokenStatus(tokenId, fromStatus, toStatus);
//     }

//     // in case wrong setting for settle
//     function tokenForceCancelSettlePhase(bytes32 tokenId) external onlyOwner {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Token storage _token = $.tokens[tokenId];
//         require(_token.status == STATUS_TOKEN_SETTLE, "Invalid Token Status");
//         _token.status = STATUS_TOKEN_INACTIVE;
//         emit TokenForceCancelSettlePhase(tokenId);
//     }

//     function updateSettleDuration(
//         bytes32 tokenId,
//         uint48 newValue
//     ) external onlyOwner {
//         PreMarketStorage storage $ = _getOwnStorage();
//         require(newValue >= 24 * 60 * 60, "Minimum 24h for settling");
//         Token storage _token = $.tokens[tokenId];
//         uint48 oldValue = _token.settleDuration;
//         _token.settleDuration = newValue;
//         emit UpdateTokenSettleDuration(tokenId, oldValue, newValue);
//     }

//     // force cancel order - by Operator
//     // refund for both seller & buyer
//     function forceCancelOrder(
//         uint256 orderId
//     ) public nonReentrant onlyRole(OPERATOR_ROLE) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Order storage order = $.orders[orderId];
//         Offer storage offer = $.offers[order.offerId];

//         require(order.status == STATUS_OFFER_OPEN, "Invalid Order Status");

//         // calculate refund
//         uint256 buyerRefundValue = (order.amount * offer.value) / offer.amount; // value
//         uint256 sellerRefundValue = (order.amount * offer.collateral) /
//             offer.amount; // collateral
//         address buyer = order.buyer;
//         address seller = order.seller;

//         // refund
//         if (offer.exToken == address(0)) {
//             // refund ETH
//             if (buyerRefundValue > 0 && buyer != address(0)) {
//                 (bool success, ) = buyer.call{value: buyerRefundValue}("");
//                 require(success, "Transfer Funds to Seller Fail");
//             }
//             if (sellerRefundValue > 0 && seller != address(0)) {
//                 (bool success, ) = seller.call{value: sellerRefundValue}("");
//                 require(success, "Transfer Funds to Seller Fail");
//             }
//         } else {
//             IERC20 iexToken = IERC20(offer.exToken);
//             if (buyerRefundValue > 0 && buyer != address(0)) {
//                 iexToken.safeTransfer(buyer, buyerRefundValue);
//             }
//             if (sellerRefundValue > 0 && seller != address(0)) {
//                 iexToken.safeTransfer(seller, sellerRefundValue);
//             }
//         }

//         order.status = STATUS_ORDER_CANCELLED;
//         emit CancelOrder(orderId, msg.sender);
//     }

//     // 2 steps settle:
//     // Tx1: Seller sending token to system vault/buyer
//     // Tx2: then Operator verify and settle to pay seller money+collateral
//     function settle2Steps(
//         uint256 orderId,
//         bytes32 hash
//     ) public nonReentrant onlyRole(OPERATOR_ROLE) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Order storage order = $.orders[orderId];
//         Offer storage offer = $.offers[order.offerId];
//         Token storage token = $.tokens[offer.tokenId];

//         // check condition
//         require(token.status == STATUS_TOKEN_SETTLE, "Invalid Status");
//         require(
//             token.token != address(0) && token.settleRate > 0,
//             "Token Not Set"
//         );
//         require(
//             block.timestamp > token.settleTime,
//             "Settling Time Not Started"
//         );
//         require(order.status == STATUS_ORDER_OPEN, "Invalid Order Status");

//         uint256 collateral = (order.amount * offer.collateral) / offer.amount;
//         uint256 value = (order.amount * offer.value) / offer.amount;

//         // transfer liquid to seller
//         uint256 settleFee = (value * $.config.feeSettle) / WEI6;
//         uint256 totalValue = value + collateral - settleFee;
//         if (offer.exToken == address(0)) {
//             // by ETH
//             (bool success1, ) = order.seller.call{value: totalValue}("");
//             (bool success2, ) = $.config.feeWallet.call{value: settleFee}("");
//             require(success1 && success2, "Transfer Funds Fail");
//         } else {
//             // by exToken
//             IERC20 iexToken = IERC20(offer.exToken);
//             iexToken.safeTransfer(order.seller, totalValue);
//             iexToken.safeTransfer($.config.feeWallet, settleFee);
//         }

//         order.status = STATUS_ORDER_SETTLE_FILLED;

//         emit Settle2Steps(orderId, hash, msg.sender);
//         emit SettleFilled(orderId, totalValue, settleFee, msg.sender);
//     }

//     function settle2StepsBatch(
//         uint256[] memory orderIds,
//         bytes32[] memory hashes
//     ) external {
//         require(orderIds.length == hashes.length, "Invalid Input");
//         for (uint256 i = 0; i < orderIds.length; i++) {
//             settle2Steps(orderIds[i], hashes[i]);
//         }
//     }

//     /////////////////////////
//     ////// USER ACTION //////
//     /////////////////////////

//     // make a offer request
//     function newOffer(
//         uint8 offerType,
//         bytes32 tokenId,
//         uint256 amount,
//         uint256 value,
//         address exToken,
//         bool fullMatch
//     ) external nonReentrant {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Token storage token = $.tokens[tokenId];
//         require(token.status == STATUS_TOKEN_ACTIVE, "Invalid Token");
//         require(
//             exToken != address(0) && $.acceptedTokens[exToken],
//             "Invalid Offer Token"
//         );
//         require(amount > 0 && value > 0, "Invalid Amount or Value");
//         IERC20 iexToken = IERC20(exToken);
//         // collateral
//         uint256 collateral = (value * $.config.pledgeRate) / WEI6;

//         // transfer offer value (offer buy) or collateral (offer sell)
//         uint256 _transferAmount = offerType == OFFER_BUY ? value : collateral;
//         iexToken.safeTransferFrom(msg.sender, address(this), _transferAmount);

//         // create new offer
//         _newOffer(
//             offerType,
//             tokenId,
//             exToken,
//             amount,
//             value,
//             collateral,
//             fullMatch
//         );
//     }

//     // New offer in ETH
//     function newOfferETH(
//         uint8 offerType,
//         bytes32 tokenId,
//         uint256 amount,
//         uint256 value,
//         bool fullMatch
//     ) external payable nonReentrant {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Token storage token = $.tokens[tokenId];
//         require(token.status == STATUS_TOKEN_ACTIVE, "Invalid Token");
//         require(amount > 0 && value > 0, "Invalid Amount or Value");
//         // collateral
//         uint256 collateral = (value * $.config.pledgeRate) / WEI6;

//         uint256 _ethAmount = offerType == OFFER_BUY ? value : collateral;
//         require(_ethAmount <= msg.value, "Insufficient Funds");
//         // create new offer
//         _newOffer(
//             offerType,
//             tokenId,
//             address(0),
//             amount,
//             value,
//             collateral,
//             fullMatch
//         );
//     }

//     // take a buy request
//     function fillOffer(uint256 offerId, uint256 amount) external nonReentrant {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Offer storage offer = $.offers[offerId];
//         Token storage token = $.tokens[offer.tokenId];

//         require(offer.status == STATUS_OFFER_OPEN, "Invalid Offer Status");
//         require(token.status == STATUS_TOKEN_ACTIVE, "Invalid token Status");
//         require(amount > 0, "Invalid Amount");
//         require(
//             offer.amount - offer.filledAmount >= amount,
//             "Insufficient Allocations"
//         );
//         require(
//             offer.fullMatch == false || offer.amount == amount,
//             "FullMatch required"
//         );
//         require(offer.exToken != address(0), "Invalid Offer Token");

//         // transfer value or collecteral
//         IERC20 iexToken = IERC20(offer.exToken);
//         uint256 _transferAmount;
//         address buyer;
//         address seller;
//         if (offer.offerType == OFFER_BUY) {
//             _transferAmount = (offer.collateral * amount) / offer.amount;
//             buyer = offer.offeredBy;
//             seller = msg.sender;
//         } else {
//             _transferAmount = (offer.value * amount) / offer.amount;
//             buyer = msg.sender;
//             seller = offer.offeredBy;
//         }
//         iexToken.safeTransferFrom(msg.sender, address(this), _transferAmount);

//         // new order
//         _fillOffer(offerId, amount, buyer, seller);
//     }

//     function fillOfferETH(
//         uint256 offerId,
//         uint256 amount
//     ) external payable nonReentrant {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Offer storage offer = $.offers[offerId];
//         Token storage token = $.tokens[offer.tokenId];

//         require(offer.status == STATUS_OFFER_OPEN, "Invalid Offer Status");
//         require(token.status == STATUS_TOKEN_ACTIVE, "Invalid token Status");
//         require(amount > 0, "Invalid Amount");
//         require(
//             offer.amount - offer.filledAmount >= amount,
//             "Insufficient Allocations"
//         );
//         require(
//             offer.fullMatch == false || offer.amount == amount,
//             "FullMatch required"
//         );
//         require(offer.exToken == address(0), "Invalid Offer Token");

//         // transfer value or collecteral
//         uint256 _ethAmount;
//         address buyer;
//         address seller;
//         if (offer.offerType == OFFER_BUY) {
//             _ethAmount = (offer.collateral * amount) / offer.amount;
//             buyer = offer.offeredBy;
//             seller = msg.sender;
//         } else {
//             _ethAmount = (offer.value * amount) / offer.amount;
//             buyer = msg.sender;
//             seller = offer.offeredBy;
//         }
//         require(msg.value >= _ethAmount, "Insufficient Funds");

//         // new order
//         _fillOffer(offerId, amount, buyer, seller);
//     }

//     // close unfullfilled offer - by Offer owner
//     function cancelOffer(uint256 offerId) public nonReentrant {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Offer storage offer = $.offers[offerId];

//         require(offer.offeredBy == msg.sender, "Offer Owner Only");
//         require(offer.status == STATUS_OFFER_OPEN, "Invalid Offer Status");

//         uint256 refundAmount = offer.amount - offer.filledAmount;
//         require(refundAmount > 0, "Insufficient Allocations");

//         // calculate refund
//         uint256 refundValue;
//         if (offer.offerType == OFFER_BUY) {
//             refundValue = (refundAmount * offer.value) / offer.amount;
//         } else {
//             refundValue = (refundAmount * offer.collateral) / offer.amount;
//         }
//         uint256 refundFee = (refundValue * $.config.feeRefund) / WEI6;
//         refundValue -= refundFee;

//         // refund
//         if (offer.exToken == address(0)) {
//             // refund ETH
//             (bool success1, ) = offer.offeredBy.call{value: refundValue}("");
//             (bool success2, ) = $.config.feeWallet.call{value: refundFee}("");
//             require(success1 && success2, "Transfer Funds Fail");
//         } else {
//             IERC20 iexToken = IERC20(offer.exToken);
//             iexToken.safeTransfer(offer.offeredBy, refundValue);
//             iexToken.safeTransfer($.config.feeWallet, refundFee);
//         }

//         offer.status = STATUS_OFFER_CANCELLED;
//         emit CancelOffer(offerId, refundValue, refundFee, msg.sender);
//     }

//     // settle order - deliver token to finillize the order
//     function settleFilled(uint256 orderId) public nonReentrant {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Order storage order = $.orders[orderId];
//         Offer storage offer = $.offers[order.offerId];
//         Token storage token = $.tokens[offer.tokenId];

//         // check condition
//         require(token.status == STATUS_TOKEN_SETTLE, "Invalid Status");
//         require(
//             token.token != address(0) && token.settleRate > 0,
//             "Token Not Set"
//         );
//         require(
//             block.timestamp > token.settleTime,
//             "Settling Time Not Started"
//         );
//         require(order.seller == msg.sender, "Seller Only");
//         require(order.status == STATUS_ORDER_OPEN, "Invalid Order Status");

//         uint256 collateral = (order.amount * offer.collateral) / offer.amount;
//         uint256 value = (order.amount * offer.value) / offer.amount;

//         // transfer token to buyer
//         IERC20 iToken = IERC20(token.token);
//         // calculate token amount base on it's decimals
//         uint256 tokenAmount = (order.amount * token.settleRate) / WEI6;
//         uint256 tokenAmountFee = (tokenAmount * $.config.feeSettle) / WEI6;
//         // transfer order fee in token to fee wallet
//         iToken.safeTransferFrom(
//             order.seller,
//             $.config.feeWallet,
//             tokenAmountFee
//         );
//         // transfer token after fee to buyer
//         iToken.safeTransferFrom(
//             order.seller,
//             order.buyer,
//             tokenAmount - tokenAmountFee
//         );

//         // transfer liquid to seller
//         uint256 settleFee = (value * $.config.feeSettle) / WEI6;
//         uint256 totalValue = value + collateral - settleFee;
//         if (offer.exToken == address(0)) {
//             // by ETH
//             (bool success1, ) = order.seller.call{value: totalValue}("");
//             (bool success2, ) = $.config.feeWallet.call{value: settleFee}("");
//             require(success1 && success2, "Transfer Funds Fail");
//         } else {
//             // by exToken
//             IERC20 iexToken = IERC20(offer.exToken);
//             iexToken.safeTransfer(order.seller, totalValue);
//             iexToken.safeTransfer($.config.feeWallet, settleFee);
//         }

//         order.status = STATUS_ORDER_SETTLE_FILLED;

//         emit SettleFilled(orderId, totalValue, settleFee, msg.sender);
//     }

//     // cancel unfilled order by token buyer after fullfill time frame
//     // token seller lose collateral to token buyer
//     function settleCancelled(uint256 orderId) public nonReentrant {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Order storage order = $.orders[orderId];
//         Offer storage offer = $.offers[order.offerId];
//         Token storage token = $.tokens[offer.tokenId];

//         // check condition
//         require(token.status == STATUS_TOKEN_SETTLE, "Invalid Status");
//         require(
//             block.timestamp > token.settleTime + token.settleDuration,
//             "Settling Time Not Ended Yet"
//         );
//         require(order.status == STATUS_ORDER_OPEN, "Invalid Order Status");
//         require(
//             order.buyer == msg.sender || hasRole(OPERATOR_ROLE, msg.sender),
//             "Buyer or Operator Only"
//         );

//         uint256 collateral = (order.amount * offer.collateral) / offer.amount;
//         uint256 value = (order.amount * offer.value) / offer.amount;

//         // transfer liquid to buyer
//         uint256 settleFee = (collateral * $.config.feeSettle * 2) / WEI6;
//         uint256 totalValue = value + collateral - settleFee;
//         if (offer.exToken == address(0)) {
//             // by ETH
//             (bool success1, ) = order.buyer.call{value: totalValue}("");
//             (bool success2, ) = $.config.feeWallet.call{value: settleFee}("");
//             require(success1 && success2, "Transfer Funds Fail");
//         } else {
//             // by exToken
//             IERC20 iexToken = IERC20(offer.exToken);
//             iexToken.safeTransfer(order.buyer, totalValue);
//             iexToken.safeTransfer($.config.feeWallet, settleFee);
//         }

//         order.status = STATUS_ORDER_SETTLE_CANCELLED;

//         emit SettleCancelled(orderId, totalValue, settleFee, msg.sender);
//     }

//     // Batch actions
//     function forceCancelOrders(uint256[] memory orderIds) external {
//         for (uint256 i = 0; i < orderIds.length; i++) {
//             forceCancelOrder(orderIds[i]);
//         }
//     }

//     function cancelOffers(uint256[] memory offerIds) external {
//         for (uint256 i = 0; i < offerIds.length; i++) {
//             cancelOffer(offerIds[i]);
//         }
//     }

//     function settleFilleds(uint256[] memory orderIds) external {
//         for (uint256 i = 0; i < orderIds.length; i++) {
//             settleFilled(orderIds[i]);
//         }
//     }

//     function settleCancelleds(uint256[] memory orderIds) external {
//         for (uint256 i = 0; i < orderIds.length; i++) {
//             settleCancelled(orderIds[i]);
//         }
//     }

//     ///////////////////////////
//     ///////// SETTER //////////
//     ///////////////////////////

//     function updateConfig(
//         address feeWallet_,
//         uint256 feeSettle_,
//         uint256 feeRefund_,
//         uint256 pledgeRate_
//     ) external onlyRole(OPERATOR_ROLE) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         require(feeWallet_ != address(0), "Invalid Address");
//         require(feeSettle_ <= WEI6 / 100, "Settle Fee <= 10%");
//         require(feeRefund_ <= WEI6 / 100, "Cancel Fee <= 10%");

//         emit UpdateConfig(
//             $.config.feeWallet,
//             $.config.feeSettle,
//             $.config.feeRefund,
//             $.config.pledgeRate,
//             feeWallet_,
//             feeSettle_,
//             feeRefund_,
//             pledgeRate_
//         );
//         // update
//         $.config.feeWallet = feeWallet_;
//         $.config.feeSettle = feeSettle_;
//         $.config.feeRefund = feeRefund_;
//         $.config.pledgeRate = pledgeRate_;
//     }

//     function setAcceptedTokens(
//         address[] memory tokenAddresses,
//         bool isAccepted
//     ) external onlyRole(OPERATOR_ROLE) {
//         PreMarketStorage storage $ = _getOwnStorage();

//         for (uint256 i = 0; i < tokenAddresses.length; i++) {
//             $.acceptedTokens[tokenAddresses[i]] = isAccepted;
//         }
//         emit UpdateAcceptedTokens(tokenAddresses, isAccepted);
//     }

//     ///////////////////////////
//     ///////// GETTER //////////
//     ///////////////////////////
//     function offerAmount(uint256 offerId) external view returns (uint256) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.offers[offerId].amount;
//     }

//     function offerAmountAvailable(
//         uint256 offerId
//     ) external view returns (uint256) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.offers[offerId].amount - $.offers[offerId].filledAmount;
//     }

//     function offerValue(uint256 offerId) external view returns (uint256) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.offers[offerId].value;
//     }

//     function offerExToken(uint256 offerId) external view returns (address) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.offers[offerId].exToken;
//     }

//     function isBuyOffer(uint256 offerId) external view returns (bool) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.offers[offerId].offerType == OFFER_BUY;
//     }

//     function isSellOffer(uint256 offerId) external view returns (bool) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.offers[offerId].offerType == OFFER_SELL;
//     }

//     function offerStatus(uint256 offerId) external view returns (uint256) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.offers[offerId].status;
//     }

//     function orderStatus(uint256 orderId) external view returns (uint256) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.orders[orderId].status;
//     }

//     function tokens(bytes32 tokenId) external view returns (Token memory) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.tokens[tokenId];
//     }

//     function offers(uint256 id) external view returns (Offer memory) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.offers[id];
//     }

//     function orders(uint256 id) external view returns (Order memory) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.orders[id];
//     }

//     function config() external view returns (Config memory) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.config;
//     }

//     function isAcceptedToken(address token) external view returns (bool) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.acceptedTokens[token];
//     }

//     function lastOfferId() external view returns (uint256) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.lastOfferId;
//     }

//     function lastOrderId() external view returns (uint256) {
//         PreMarketStorage storage $ = _getOwnStorage();
//         return $.lastOrderId;
//     }

//     ///////////////////////////
//     //////// INTERNAL /////////
//     ///////////////////////////
//     function _newOffer(
//         uint8 offerType,
//         bytes32 tokenId,
//         address exToken,
//         uint256 amount,
//         uint256 value,
//         uint256 collateral,
//         bool fullMatch
//     ) internal {
//         PreMarketStorage storage $ = _getOwnStorage();
//         // create new offer
//         $.offers[++$.lastOfferId] = Offer(
//             offerType,
//             tokenId,
//             exToken,
//             amount,
//             value,
//             collateral,
//             0,
//             STATUS_OFFER_OPEN,
//             msg.sender,
//             fullMatch
//         );

//         emit NewOffer(
//             $.lastOfferId,
//             offerType,
//             tokenId,
//             exToken,
//             amount,
//             value,
//             collateral,
//             fullMatch,
//             msg.sender
//         );
//     }

//     function _fillOffer(
//         uint256 offerId,
//         uint256 amount,
//         address buyer,
//         address seller
//     ) internal {
//         PreMarketStorage storage $ = _getOwnStorage();
//         Offer storage offer = $.offers[offerId];
//         // new order
//         $.orders[++$.lastOrderId] = Order(
//             offerId,
//             amount,
//             seller,
//             buyer,
//             STATUS_ORDER_OPEN
//         );

//         // check if offer is fullfilled
//         offer.filledAmount += amount;
//         if (offer.filledAmount == offer.amount) {
//             offer.status = STATUS_OFFER_FILLED;
//             emit CloseOffer(offerId, 0);
//         }

//         emit NewOrder($.lastOrderId, offerId, amount, seller, buyer);
//     }

//     // get stuck token in contract
//     function withdrawStuckToken(
//         address _token,
//         address _to
//     ) external onlyOwner {
//         PreMarketStorage storage $ = _getOwnStorage();
//         require(
//             _token != address(0) && !$.acceptedTokens[_token],
//             "Invalid Token Address"
//         );
//         uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
//         IERC20(_token).safeTransfer(_to, _contractBalance);
//     }
// }
