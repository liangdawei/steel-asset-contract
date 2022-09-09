// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./lib/Ownable.sol";
import "./lib/math/SafeMath.sol";
import "./lib/utils/AddressUtils.sol";
import "./SteelArchiveManager.sol";

/**
 * @title Steel Asset Registration Centre
 * @dev Used to register asset information such as raw steel and steel products
 */
contract SteelAssetManager is Ownable {

    // library
    using SafeMath for uint256;
    using AddressUtils for address;

    // Raw Steel Asset Information
    struct SteelRawAsset {
        // Raw Steel Asset String
        bytes32 id;
        // Public Key
        address key;
        // Raw Steel Profile String
        bytes32 rawArvId;
        // Heat No
        bytes32 furnace;
        // Batch No
        bytes32 batch;
        // Fundamental organization
        string structure;
        // Amount/Weight
        uint num;
        // Registration Date
        uint regDate;
        // Asset Source 0 : Registration；1 : Trade；2 : Process
        uint8 origin;
        // Source String Trade/Process
        bytes32 originId;
        // Burn or Not
        bool isDel;
        // Burn Date
        uint delDate;
    }

    // Steel Asset Information
    struct SteelProductAsset {
        // Steel Asset String
        bytes32 id;
        // Public Key
        address key;
        // Steel Product Profile String
        bytes32 productArvId;
        // Steel Product Process Profile String
        bytes32 processArvId;
        // Amount
        uint num;
        // Registration Date
        uint regDate;
        // Asset Source 0 : Registration；1 : Trade；2 : Process
        uint8 origin;
        // Source String Trade/Process
        bytes32 originId;
        // Burn or Not
        bool isDel;
        // Burn Date
        uint delDate;
    }

    // Raw Steel Asset List
    mapping (bytes32 => SteelRawAsset) rawAssetList;
    // Steel Asset List
    mapping (bytes32 => SteelProductAsset) productAssetList;

    // Rely on Steel Asset  Registration Contract
    SteelArchiveManager public steelArchiveManager;

    // Constructor
    constructor(address _steelArchiveManager) {
        steelArchiveManager = SteelArchiveManager(_steelArchiveManager);
    }
    
    // Steel Asset Operate Contract List，Be able to operate steel asset
    mapping (address => bool) steelManagerList; 
    
    // event for EVM logging
    event SteelManagerCreate(address indexed steelManager);
    event SteelManagerDelete(address indexed steelManager);

    /**
     * @dev Create Steel Asset Operate Contract
     * @param steelManager Steel Asset Operate Contract Address
     * @return Succeed or Not
     */
    function createSteelManager(address steelManager) public onlyOwner returns (bool) {
        require(steelManager.isContract());
        steelManagerList[steelManager] = true;
        emit SteelManagerCreate(steelManager);
        return true;
    }

    /**
     * @dev Delete Steel Asset Operate Contract
     * @param steelManager Steel Asset Operate Contract Address
     * @return Succeed or Not
     */
    function deleteSteelManager(address steelManager) public onlyOwner returns (bool) {
        require(steelManager.isContract());
        delete steelManagerList[steelManager];
        emit SteelManagerDelete(steelManager);
        return true;
    }

    /**
     * @dev Query if Steel Asset Operate Contract
     * @param steelManager Steel Asset Operate Contract Address
     * @return Yes or No
     */
    function isSteelManager(address steelManager) public view returns (bool) {
        return steelManagerList[steelManager];
    }

    // event for EVM logging
    event SteelRawAssetCreate(address indexed key, bytes32 indexed rawArvId, bytes32 indexed id, bytes32 furnace, bytes32 batch, string structure, uint num, uint date, uint8 origin, bytes32 originId);
    event SteelProductAssetCreate(address indexed key, bytes32 indexed productArvId, bytes32 indexed id, bytes32 processArvId, uint num, uint date, uint8 origin, bytes32 originId);
    event SteelRawAssetDelete(bytes32 rawAssetId, uint date);
    event SteelProductAssetDelete(bytes32 productAssetId, uint date);

    /**
     * @dev RegistrationRaw Steel Asset Information
     * @param rawArvId Raw Steel Profile String
     * @param furnace Heat No
     * @param batch Batch No
     * @param structure Fundamental organization
     * @param num Amount/Weight
     * @return id Raw Steel Asset String
     */
    function createSteelRawAsset(bytes32 rawArvId, bytes32 furnace, bytes32 batch, string memory structure, uint num) public returns (bytes32) {
        (,address key,,,) = steelArchiveManager.getSteelRawArchive(rawArvId);
        require(msg.sender == key, "Permission denied");
        return _createSteelRawAsset(msg.sender, rawArvId, furnace, batch, structure, num, block.timestamp, 0, bytes32(0));
    }

    /**
     * @dev RegistrationRaw Steel Asset Information（For Call from Trade/Process Contract）
     * @param rawAssetId Raw Steel Asset String
     * @param key Public Key
     * @param num Amount/Weight
     * @param regDate Registration Date
     * @param origin Asset Source 0 : Registration；1 : Trade；2 : Process
     * @param originId Source String Trade/Process
     * @return id Raw Steel Asset String
     */
    function createSteelRawAssetByManager(bytes32 rawAssetId, address key, uint num, uint regDate, uint8 origin, bytes32 originId) public returns (bytes32) {
        require(isSteelManager(msg.sender));
        return _createSteelRawAsset(key, rawAssetList[rawAssetId].rawArvId, rawAssetList[rawAssetId].furnace
            , rawAssetList[rawAssetId].batch, rawAssetList[rawAssetId].structure, num, regDate, origin, originId);
    }

    /**
     * @dev RegistrationSteel Asset Information（Create New Asset for Process Contract）
     * @param key Public Key
     * @param productArvId Steel Product Profile String
     * @param processArvId Steel Product Process Profile String
     * @param num Amount
     * @param regDate Registration Date
     * @param origin Asset Source 0 : Registration；1 : Trade；2 : Process
     * @param originId Source String Trade/Process
     * @return id Steel Asset String
     */
    function createSteelProductAsset(address key, bytes32 productArvId, bytes32 processArvId, uint num, uint regDate, uint8 origin, bytes32 originId) public returns (bytes32) {
        require(isSteelManager(msg.sender));
        return _createSteelProductAsset(key, productArvId, processArvId, num, regDate, origin, originId);
    }

    /**
     * @dev RegistrationSteel Asset Information（For Call from Trade/Process Contract）
     * @param productAssetId Steel Asset String
     * @param key Public Key
     * @param num Amount
     * @param regDate Registration Date
     * @param origin Asset Source 0 : Registration；1 : Trade；2 : Process
     * @param originId Source String Trade/Process
     * @return id Steel Asset String
     */
    function createSteelProductAssetByManager(bytes32 productAssetId, address key, uint num, uint regDate, uint8 origin, bytes32 originId) public returns (bytes32) {
        require(isSteelManager(msg.sender));
        return _createSteelProductAsset(key, productAssetList[productAssetId].productArvId, productAssetList[productAssetId].processArvId, num, regDate, origin, originId);
    }

    /**
     * @dev Burn Raw Steel Registration Information（For Call from Trade/Process Contract）
     * @param rawAssetId Raw Steel Asset String
     * @param date Burn Date
     * @return Succeed or Not
     */
    function deleteSteelRawAsset(bytes32 rawAssetId, uint date) public returns(bool) {
        require(isSteelManager(msg.sender));
        return _deleteSteelRawAsset(rawAssetId, date);
    }

    /**
     * @dev Burn Steel Product Asset Registration Information（For Call from Trade/Process Contract）
     * @param productAssetId Steel Asset String
     * @param date Burn Date
     * @return Succeed or Not
     */
    function deleteSteelProductAsset(bytes32 productAssetId, uint date) public returns(bool) {
        require(isSteelManager(msg.sender));
        return _deleteSteelProductAsset(productAssetId, date);
    }
    
    /**
     * @dev Get Raw Steel Asset Information
     * @param id Raw Steel Asset String
     * @return id Raw Steel Asset String
     * @return key Public Key
     * @return rawArvId Raw Steel Profile String
     * @return furnace Heat No
     * @return batch Batch No
     * @return structure Fundamental organization
     * @return num Amount/Weight
     * @return regDate Registration Date
     * @return origin Asset Source 0 : Registration；1 : Trade；2 : Process
     * @return originId Source String Trade/Process
     * @return isDel Burn or Not
     * @return delDate Burn Date
     */
    function getSteelRawAsset(bytes32 id) public view returns (bytes32, address, bytes32, bytes32, bytes32, string memory, uint, uint, uint8, bytes32, bool, uint) {
        SteelRawAsset memory asset = rawAssetList[id];
        return(asset.id, asset.key, asset.rawArvId, asset.furnace, asset.batch, asset.structure, asset.num, asset.regDate, asset.origin, asset.originId, asset.isDel, asset.delDate);
    }

    /**
     * @dev Get Steel Asset Information
     * @param id Steel Asset String
     * @return id Steel Asset String
     * @return key Public Key
     * @return productArvId Steel Product Profile String
     * @return processArvId Steel Product Process Profile String
     * @return num Amount/Weight
     * @return regDate Registration Date
     * @return origin Asset Source 0 : Registration；1 : Trade；2 : Process
     * @return originId Source String Trade/Process 
     * @return isDel Burn or Not
     * @return delDate Burn Date
     */
    function getSteelProductAsset(bytes32 id) public view returns (bytes32, address, bytes32, bytes32, uint, uint, uint8, bytes32, bool, uint) {
        SteelProductAsset memory asset = productAssetList[id];
        return(asset.id, asset.key, asset.productArvId, asset.processArvId, asset.num, asset.regDate, asset.origin, asset.originId, asset.isDel, asset.delDate);
    }

    /**
     * @dev Registration Raw Steel Asset Information（Internal Call）
     * @param key Public Key
     * @param rawArvId Raw Steel Profile String
     * @param furnace Heat No
     * @param batch Batch No
     * @param structure Fundamental organization
     * @param num Amount/Weight
     * @param regDate Registration Date
     * @param origin Asset Source 0 : Registration；1 : Trade；2 : Process
     * @param originId Source String Trade/Process
     * @return id Raw Steel Asset String
     */
    function _createSteelRawAsset(address key, bytes32 rawArvId, bytes32 furnace, bytes32 batch, string memory structure, uint num, uint regDate, uint8 origin, bytes32 originId) internal returns (bytes32) {
        require(num > 0, "Num must be greater than 0");
        bytes32 id = keccak256(abi.encode(key, rawArvId, furnace, batch, bytes(structure), num, regDate));
        require(rawAssetList[id].id == bytes32(0), "The raw asset id already exists");
        rawAssetList[id].id = id;
        rawAssetList[id].key = key;
        rawAssetList[id].rawArvId = rawArvId;
        rawAssetList[id].furnace = furnace;
        rawAssetList[id].batch = batch;
        rawAssetList[id].structure = structure;
        rawAssetList[id].num = num;
        rawAssetList[id].regDate = regDate;
        rawAssetList[id].origin = origin;
        rawAssetList[id].originId = originId;
        emit SteelRawAssetCreate(key, rawArvId, id, furnace, batch, structure, num, regDate, origin, originId);
        return id;
    }

    /**
     * @dev RegistrationSteel Asset Information（Internal Call）
     * @param key Public Key
     * @param productArvId Steel Product Profile String
     * @param processArvId Steel Product Process Profile String
     * @param num Amount
     * @param regDate Registration Date
     * @param origin Asset Source 0 : Registration；1 : Trade；2 : Process
     * @param originId Source String Trade/Process
     * @return id Steel Asset String
     */
    function _createSteelProductAsset(address key, bytes32 productArvId, bytes32 processArvId, uint num, uint regDate, uint8 origin, bytes32 originId) internal returns (bytes32) {
        require(num > 0, "Num must be greater than 0");
        bytes32 id = keccak256(abi.encode(key, productArvId, processArvId, num, regDate));
        require(rawAssetList[id].id == bytes32(0), "The product asset id already exists");
        productAssetList[id].id = id;
        productAssetList[id].key = key;
        productAssetList[id].productArvId = productArvId;
        productAssetList[id].processArvId = processArvId;
        productAssetList[id].num = num;
        productAssetList[id].regDate = regDate;
        productAssetList[id].origin = origin;
        productAssetList[id].originId = originId;
        emit SteelProductAssetCreate(key, productArvId, id, processArvId, num, regDate, origin, originId);
        return id;
    }
    
    /**
     * @dev Burn Raw Steel Asset Registration Information（Internal Call）
     * @param rawAssetId Raw Steel Asset String
     * @param date Burn Date
     * @return Succeed or Not
     */
    function _deleteSteelRawAsset(bytes32 rawAssetId, uint date) internal returns(bool) {
        rawAssetList[rawAssetId].isDel = true;
        rawAssetList[rawAssetId].delDate = date;
        emit SteelRawAssetDelete(rawAssetId, date);
        return true;
    }

    /**
     * @dev Burn Steel Product Asset Registration Information（Internal Call）
     * @param productAssetId Steel Asset String
     * @param date Burn Date
     * @return Succeed or Not
     */
    function _deleteSteelProductAsset(bytes32 productAssetId, uint date) internal returns(bool) {
        productAssetList[productAssetId].isDel = true;
        productAssetList[productAssetId].delDate = date;
        emit SteelProductAssetDelete(productAssetId, date);
        return true;
    }
}
