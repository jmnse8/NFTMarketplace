// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string _baseTokenURI;
    uint256 public _price = 0.00001 ether;
    bool public _paused;
    uint256 public maxTokenIds = 10;
    uint256 public tokenIds;

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    constructor (string memory baseURI) Ownable(msg.sender) ERC721("NFT", "NFT") {
        _baseTokenURI = baseURI;
        tokenIds = 0;
    }

    function setEthPrice(uint _etherPrice) public onlyOwner {
        _price = 1 ether * 2 / _etherPrice / 100;
    }

    function mint() public payable onlyWhenNotPaused {
        require(tokenIds < maxTokenIds, "Exceed maximum supply");
        require(msg.value >= _price, "Ether sent is not correct");
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        require(tokenId <= tokenIds, "URI query for nonexistent token");

        string memory baseURI = _baseURI();
        
        return string(abi.encodePacked(baseURI, "/meta.json"));
    }

    function tokenImageURI(uint256 tokenId) public view virtual returns (string memory) {
        require(tokenId<=tokenIds, "URI query for nonexistent token");

        string memory baseURI = _baseURI();
        if(bytes(baseURI).length > 0)
            return string(abi.encodePacked(baseURI, "/ferg.jpg"));
        else
            return "";
    }

    function setPaused(bool pause) public onlyOwner {
        _paused = pause;
    }

    function withdraw() public onlyOwner  {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    fallback() external payable {}
}