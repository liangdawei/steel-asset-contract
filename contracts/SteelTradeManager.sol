// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./lib/math/SafeMath.sol";
import "./SteelAssetManager.sol";

/**
 * @title Steel Asset Trade Centre
 * @dev For Trade of Raw Steel, Steel Product Asset
 */
contract SteelTradeManager {
    
    // library
    using SafeMath for uint256;
    
    // Raw Steel Asset Trade Information
    struct SteelRawTrade {
        // Trade String
        bytes32 id;
        // From Public Key
        address fromKey;
        // To Public Key
        address toKey;
        // Raw Steel Asset String
        bytes32 rawAssetId;
        // TradeAmount/Weight
        uint num;
        // Trade Date
        uint date; 
    }
    
    // Steel Product Asset Trade Information
    struct SteelProductTrade {
        // Trade String
        bytes32 id;
        // From Public Key
        address fromKey;
        // To Public Key
        address toKey;
        // Steel Asset String
        bytes32 productAssetId;
        // TradeAmount/Weight
        uint num;
        // Trade Date
        uint date;
    }

    // Raw Steel Asset Trade List
    mapping (bytes32 => SteelRawTrade) rawTradeList;
    // Steel Product Asset  Trade List
    mapping (bytes32 => SteelProductTrade) productTradeList;

    // Rely on Steel Asset Registration Centre
    SteelAssetManager public steelAssetManager;

    // Constructor 
    constructor(address _steelAssetManager) {
        steelAssetManager = SteelAssetManager(_steelAssetManager);
    }

    // event for EVM logging
    event SteelRawAssetTrade(address indexed fromKey, address indexed toKey, bytes32 indexed rawAssetId, uint num, uint date, bytes32 tradeId, bytes32 fromId, bytes32 toId);
    event SteelProductAssetTrade(address indexed fromKey, address indexed toKey, bytes32 indexed productAssetId, uint num, uint date, bytes32 tradeId, bytes32 fromId, bytes32 toId);
    
    /**
     * @dev Trade Raw Steel Asset
     * @param toKey To Public Key
     * @param rawAssetId Raw Steel Asset String
     * @param num Amount/Weight
     * @return tradeId Trade String
     * @return fromId From Raw Steel Asset String（Charge）
     * @return toId To Raw Steel Asset String（Trade Create）
     */
    function tradeSteelRawAsset(address toKey, bytes32 rawAssetId, uint num) public returns (bytes32, bytes32, bytes32) {
        require(toKey != address(0), "Trade to the zero address");
        require(num > 0, "The num must be greater than 0");
        (,address key,,,,,uint balance,,,,bool isDel,) = steelAssetManager.getSteelRawAsset(rawAssetId);
        require(key == msg.sender, "The sender has no ownership");
        require(!isDel, "The raw asset has been deleted");
        // Create Raw Steel Trade Information
        bytes32 tradeId = _createSteelRawTrade(msg.sender, toKey, rawAssetId, num, block.timestamp);
        // Burn To Raw Steel Registration Information
        steelAssetManager.deleteSteelRawAsset(rawAssetId, block.timestamp);
        // Create From Raw Steel Charge Information
        balance = balance.sub(num);
        bytes32 fromId = bytes32(0);
        if(balance > 0) {
            fromId = steelAssetManager.createSteelRawAssetByManager(rawAssetId, msg.sender, balance, block.timestamp, 1, tradeId);
        }
        // Create To Raw Steel Charge Information
        bytes32 toId = steelAssetManager.createSteelRawAssetByManager(rawAssetId, toKey, num, block.timestamp, 1, tradeId);
        emit SteelRawAssetTrade(msg.sender, toKey, rawAssetId, num, block.timestamp, tradeId, fromId, toId);
        return(tradeId, fromId, toId);
    }

    /**
     * @dev Trade Steel Product Asset
     * @param toKey To Public Key
     * @param productAssetId Steel Asset String
     * @param num Amount
     * @return tradeId Trade String
     * @return fromId From Steel Asset String（Charge）
     * @return toId From Steel Asset String（Trade Create）
     */
    function tradeSteelProductAsset(address toKey, bytes32 productAssetId, uint num) public returns (bytes32, bytes32, bytes32) {
        require(toKey != address(0), "Trade to the zero address");
        require(num > 0, "The num must be greater than 0");
        (,address key,,,uint balance,,,,bool isDel,) = steelAssetManager.getSteelProductAsset(productAssetId);
        require(key == msg.sender, "The sender has no ownership");
        require(!isDel, "The product asset has been deleted");
        // Create Steel Product Trade Information
        bytes32 tradeId = _createSteelProductTrade(msg.sender, toKey, productAssetId, num, block.timestamp);
        // Burn From Steel Product Asset Registration Information
        steelAssetManager.deleteSteelProductAsset(productAssetId, block.timestamp);
        // Create From Steel Product Charge Information
        balance = balance.sub(num);
        bytes32 fromId = bytes32(0);
        if(balance > 0) {
            fromId = steelAssetManager.createSteelProductAssetByManager(productAssetId, msg.sender, balance, block.timestamp, 1, tradeId);
        }
        // Create To Steel Product Registration Information
        bytes32 toId = steelAssetManager.createSteelProductAssetByManager(productAssetId, toKey, num, block.timestamp, 1, tradeId);
        emit SteelProductAssetTrade(msg.sender, toKey, productAssetId, num, block.timestamp, tradeId, fromId, toId);
        return(tradeId, fromId, toId);
    }

    /**
     * @dev Get Raw Steel Asset Trade Information
     * @param id Raw Steel Asset Trade String
     * @return id Raw Steel Asset Trade String
     * @return fromKey From Public Key
     * @return toKey To Public Key
     * @return rawAssetId Raw Steel Asset String
     * @return num TradeAmount/Weight
     * @return date Trade Date
     */
    function getSteelRawTrade(bytes32 id) public view returns (bytes32, address, address, bytes32, uint, uint) {
        SteelRawTrade memory trade = rawTradeList[id];
        return(trade.id, trade.fromKey, trade.toKey, trade.rawAssetId, trade.num, trade.date);
    }

    /**
     * @dev Get Steel Product Asset Trade Information
     * @param id Steel Product Asset Trade String
     * @return id Steel Product Asset Trade String
     * @return fromKey From Public Key
     * @return toKey To Public Key
     * @return productAssetId Steel Asset String
     * @return num TradeAmount
     * @return date Trade Date
     */
    function getSteelProductTrade(bytes32 id) public view returns (bytes32, address, address, bytes32, uint, uint) {
        SteelProductTrade memory trade = productTradeList[id];
        return(trade.id, trade.fromKey, trade.toKey, trade.productAssetId, trade.num, trade.date);
    }

    /**
     * @dev Create Raw Steel Asset Trade Information（Internal Call）
     * @param fromKey From Public Key
     * @param toKey To Public Key
     * @param rawAssetId Raw Steel Asset String
     * @param num TradeAmount/Weight
     * @param date Trade Date
     * @return id Raw Steel Asset Trade String
     */
    function _createSteelRawTrade(address fromKey, address toKey, bytes32 rawAssetId, uint num, uint date) internal returns (bytes32) {
        bytes32 id = keccak256(abi.encode(fromKey, toKey, rawAssetId, num, date));
        require(rawTradeList[id].id == bytes32(0), "The raw asset trade id already exists");
        rawTradeList[id].id = id;
        rawTradeList[id].fromKey = fromKey;
        rawTradeList[id].toKey = toKey;
        rawTradeList[id].rawAssetId = rawAssetId;
        rawTradeList[id].num = num;
        rawTradeList[id].date = date;
        return id;
    }

    /**
     * @dev Create Steel Asset Trade Information（Internal Call）
     * @param fromKey From Public Key
     * @param toKey To Public Key
     * @param productAssetId Steel Asset String
     * @param num TradeAmount
     * @param date Trade Date
     * @return id Steel Product Asset Trade String
     */
    function _createSteelProductTrade(address fromKey, address toKey, bytes32 productAssetId, uint num, uint date) internal returns (bytes32) {
        bytes32 id = keccak256(abi.encode(fromKey, toKey, productAssetId, num, date));
        require(productTradeList[id].id == bytes32(0), "The product asset trade id already exists");
        productTradeList[id].id = id;
        productTradeList[id].fromKey = fromKey;
        productTradeList[id].toKey = toKey;
        productTradeList[id].productAssetId = productAssetId;
        productTradeList[id].num = num;
        productTradeList[id].date = date;
        return id;
    }

}