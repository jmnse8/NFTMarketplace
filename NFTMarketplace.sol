// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace {
    struct MarketOffer  {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => MarketOffer )) public offers;

    modifier isNFTOwner(address nftAddress, uint256 tokenId) {
        require(
            IERC721(nftAddress).ownerOf(tokenId) == msg.sender,
            "No eres el owner");
        _;
    }

    modifier validPrice(uint256 _price) {
        require(_price > 0, "El precio debe ser mayor a cero");
        _;
    }

    modifier isNotOffered(address nftAddress, uint256 tokenId) {
        require(
            offers[nftAddress][tokenId].price == 0,
            "Ya esta ofertado");
        _;
    }

    modifier isOffered(address nftAddress, uint256 tokenId) {
        require(offers[nftAddress][tokenId].price > 0, "No esta ofertado");
        _;
    }

    event OfferCreated(address nftAddress, uint256 tokenId, uint256 price, address seller);

    event OfferDeleted(address nftAddress, uint256 tokenId, address seller);

    event OfferEdited(address nftAddress, uint256 tokenId, uint256 newPrice, address seller);

    event OfferPurchased(address nftAddress, uint256 tokenId, address seller, address buyer);

    function createOffer(address nftAddress, uint256 tokenId, uint256 price) external
        isNotOffered(nftAddress, tokenId) isNFTOwner(nftAddress, tokenId) validPrice(price) {

        IERC721 nftContract = IERC721(nftAddress);
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)) ||
                nftContract.getApproved(tokenId) == address(this),
            "No hay aprovacion para operar con el NFT"
        );
        offers[nftAddress][tokenId] = MarketOffer({
            price: price,
            seller: msg.sender
        });

        emit OfferCreated(nftAddress, tokenId, price, msg.sender);
    }

    function deleteOffer(address nftAddress, uint256 tokenId) external
        isOffered(nftAddress, tokenId) isNFTOwner(nftAddress, tokenId) {
        delete offers[nftAddress][tokenId];

        emit OfferDeleted(nftAddress, tokenId, msg.sender);
    }

    function editOffer( address nftAddress, uint256 tokenId, uint256 newPrice ) external
        isOffered(nftAddress, tokenId) isNFTOwner(nftAddress, tokenId)  validPrice(newPrice) {
        
        offers[nftAddress][tokenId].price = newPrice;
        emit OfferEdited(nftAddress, tokenId, newPrice, msg.sender);
    }

    function purchaseOffer(address nftAddress, uint256 tokenId) external payable 
        isOffered(nftAddress, tokenId) {

        MarketOffer memory offer = offers[nftAddress][tokenId];

        require(msg.value >= offer.price, "Has pagado un precio incorrecto");

		delete offers[nftAddress][tokenId];

        IERC721(nftAddress).safeTransferFrom(offer.seller, msg.sender, tokenId);

        (bool sent, ) = payable(offer.seller).call{value: msg.value}("");
        require(sent, "Failed to transfer eth");

        emit OfferPurchased(nftAddress, tokenId, offer.seller, msg.sender);
    }
}