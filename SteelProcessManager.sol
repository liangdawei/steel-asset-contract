// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./lib/math/SafeMath.sol";
import "./SteelArchiveManager.sol";
import "./SteelAssetManager.sol";

/**
 * @title Steel Asset Process Centre
 * @dev For Process Steel Product Asset
 */
contract SteelProcessManager {
    
    //library
    using SafeMath for uint256;
    
    // Steel Product Asset Process Information
    struct SteelProductProcess {
        // Steel Product Asset Process String
        bytes32 id;
        // Public Key
        address Key;
        // Process Profile String
        bytes32 processArvId;
        // Raw Steel Asset Input String List
        bytes32[] rawAssetIdList;
        // Steel Product Asset Input String List
        bytes32[] productAssetIdList;
        // Output Amount
        uint num;
        // Process Date
        uint date;
    }

    // Steel Product Asset Process List
    mapping (bytes32 => SteelProductProcess) productProcessList;

    // Rely On Steel Asset Registration Centre
    SteelAssetManager public steelAssetManager;
    // Rely On Steel Asset Registration Centre
    SteelArchiveManager public steelArchiveManager;

    // Init Function
    constructor(address _steelAssetManager) {
        steelAssetManager = SteelAssetManager(_steelAssetManager);
        steelArchiveManager = steelAssetManager.steelArchiveManager();
    }

    // event for EVM logging
    event SteelProductAssetProcess(address indexed key, bytes32 indexed processArvId, bytes32 indexed productAssetId, bytes32[] rawAssetIdList
        , bytes32[] productAssetIdList,uint num, uint date, bytes32 processId, bytes32[] newRawAssetIdList, bytes32[] newProductAssetIdList);

    /**
     * @dev Process Steel Product Asset 
     * @param processArvId Steel Product Process Profile String
     * @param rawAssetIdList Raw Steel Asset Input String List
     * @param productAssetIdList Steel Product Asset Input String List
     * @param num ProcessOutput Amount
     * @return processId Process String
     * @return newAssetId ProcessSteel Asset String（Process）
     * @return newRawAssetIdList Raw Steel Asset String List（Charge）
     * @return newProductAssetIdList Steel Asset String List（Charge）
     */
    function processSteelProductAsset(bytes32 processArvId, bytes32[] memory rawAssetIdList, bytes32[] memory productAssetIdList, uint num) public returns (bytes32, bytes32, bytes32[] memory, bytes32[] memory) {
        require(num > 0, "The num must be greater than 0");
        // Create Steel Product Process Information
        bytes32 processId = _createSteelProductProcesse(msg.sender, processArvId, rawAssetIdList, productAssetIdList, num, block.timestamp);

        // Process Process Material
        bytes32[] memory newRawAssetIdList = _processRawAssetList(processArvId, rawAssetIdList, num, processId);
        bytes32[] memory newProductAssetIdList = _processProductAssetList(processArvId, productAssetIdList, num, processId);

        // Create New Asset Registration Information
        bytes32 newAssetId = _createProductAsset(processArvId, num, processId);

        emit SteelProductAssetProcess(msg.sender, processArvId, newAssetId, rawAssetIdList, productAssetIdList, num, block.timestamp, processId, newRawAssetIdList, newProductAssetIdList);
        return(processId, newAssetId, newRawAssetIdList, newProductAssetIdList);
    }
    
    /**
     * @dev Get Steel Product Asset Process Information
     * @param id Process String
     * @return id Process String
     * @return Key Public Key
     * @return processArvId Steel Product Process Profile String 
     * @return rawAssetIdList Raw Steel Asset Input String List
     * @return productAssetIdList Steel Product Asset Input String List
     * @return num ProcessOutput Amount
     * @return date Process Date
     */
    function getSteelProductProcess(bytes32 id) public view returns (bytes32, address, bytes32, bytes32[] memory, bytes32[] memory, uint, uint) {
        SteelProductProcess memory process = productProcessList[id];
        return(process.id, process.Key, process.processArvId, process.rawAssetIdList, process.productAssetIdList, process.num, process.date);
    }

    /**
     * @dev Create Steel Product Process Information（Internal Call）
     * @param key Public Key
     * @param processArvId Steel Product Process Profile String
     * @param rawAssetIdList Raw Steel Asset Input String List
     * @param productAssetIdList Steel Product Asset Input String List
     * @param num ProcessOutput Amount
     * @param date Process Date
     * @return id Steel Product Process String
     */
    function _createSteelProductProcesse(address key, bytes32 processArvId, bytes32[] memory rawAssetIdList, bytes32[] memory productAssetIdList, uint num, uint date) internal returns (bytes32) {
        bytes32 id = keccak256(abi.encode(key, processArvId, rawAssetIdList, productAssetIdList, num, block.timestamp));
        productProcessList[id].id = id;
        productProcessList[id].Key = key;
        productProcessList[id].processArvId = processArvId;
        productProcessList[id].rawAssetIdList = rawAssetIdList;
        productProcessList[id].productAssetIdList = productAssetIdList;
        productProcessList[id].num = num;
        productProcessList[id].date = date;
        return id;
    }
    
    /**
     * @dev Process Create Steel Product Asset（Internal Call）
     * @param processArvId Steel Product Process Profile String
     * @param num ProcessOutput Amount
     * @param processId Process String
     * @return id ProcessSteel Asset String
     */
    function _createProductAsset(bytes32 processArvId, uint num, bytes32 processId) internal returns (bytes32) {
        // Get Process Profile Info from Process Profile String
        (,,,,bytes32 productArvId,,,,,) = steelArchiveManager.getSteelProcessArchive(processArvId);
        // Create New Asset Registration Information
        return steelAssetManager.createSteelProductAsset(msg.sender, productArvId, processArvId, num, block.timestamp, 2, processId);
    }

    /**
     * @dev ProcessChargeRaw Steel Asset List（Internal Call）
     * @param processArvId Steel Product Process Profile String
     * @param rawAssetIdList Raw Steel Asset Input String List
     * @param num ProcessOutput Amount
     * @param processId Process String
     * @return ids Raw Steel Asset String List（Charge）
     */
    function _processRawAssetList(bytes32 processArvId, bytes32[] memory rawAssetIdList, uint num, bytes32 processId) internal returns (bytes32[] memory) {
        (,,,,,bytes32[] memory rawArvIdList,uint[] memory rawArvNumList,,,uint outputNum) = steelArchiveManager.getSteelProcessArchive(processArvId);
        require(rawAssetIdList.length == rawArvIdList.length, "Input raw asset id list must match archive list");
        bytes32[] memory ids = new bytes32[](rawAssetIdList.length);
        for(uint i = 0; i < rawAssetIdList.length; i ++) {
            ids[i] = _processRawAsset(rawAssetIdList[i], num, rawArvIdList[i], rawArvNumList[i], outputNum, processId);
        }
        return ids;
    }
    
    /**
     * @dev ProcessCharge Steel Asset List（Internal Call）
     * @param processArvId Steel Product Process Profile String
     * @param productAssetIdList Steel Product Asset Input String List
     * @param num ProcessOutput Amount
     * @param processId Process String
     * @return ids Steel Asset String List（Charge）
     */
    function _processProductAssetList(bytes32 processArvId, bytes32[] memory productAssetIdList, uint num, bytes32 processId) internal returns (bytes32[] memory) {
        (,,,,,,,bytes32[] memory productArvIdList,uint[] memory productArvNumList,uint outputNum) = steelArchiveManager.getSteelProcessArchive(processArvId);
        require(productAssetIdList.length == productArvIdList.length, "Input product asset id list must be match archive list");
        bytes32[] memory ids = new bytes32[](productAssetIdList.length);
        for(uint i = 0; i < productAssetIdList.length; i ++) {
            ids[i] = _processProductAsset(productAssetIdList[i], num, productArvIdList[i], productArvNumList[i], outputNum, processId);
        }
        return ids;
    }
    
    /**
     * @dev Process Charge Raw Steel（Internal Call）
     * @param rawAssetId Raw Steel Input String
     * @param num ProcessOutput Amount
     * @param processRawArvId Process Profile Raw Steel Input String
     * @param processRawArvNum Process Profile Raw Steel Input Amount
     * @param processOutputNum Process Profile Output Amount
     * @param processId Process String
     * @return id Raw Steel Asset String（Charge）
     */
    function _processRawAsset(bytes32 rawAssetId, uint num, bytes32 processRawArvId, uint processRawArvNum, uint processOutputNum, bytes32 processId) internal returns (bytes32) {
        (,address key,bytes32 rawArvId,,,,uint balance,,,,bool isDel,) = steelAssetManager.getSteelRawAsset(rawAssetId);
        require(key == msg.sender, "The sender has no ownership");
        require(!isDel, "Input raw asset has been deleted");
        require(rawArvId == processRawArvId, "Input raw asset must match archive id");
        // Burn Process Material Information
        steelAssetManager.deleteSteelRawAsset(rawAssetId, block.timestamp);
        // Create Process Material Charge Information
        balance = balance.sub(num.mul(processRawArvNum).div(processOutputNum));
        bytes32 id = bytes32(0);
        if(balance > 0) {
            id = steelAssetManager.createSteelRawAssetByManager(rawAssetId, msg.sender, balance, block.timestamp, 2, processId);
        }
        return id;
    }

    /**
     * @dev Process Charge Steel Product Asset（Internal Call）
     * @param productAssetId Steel Product Asset Input String
     * @param num ProcessOutput Amount
     * @param processProductArvId Process Profile Steel Product Input String
     * @param processProductArvNum Process Profile Steel Product Input Amount
     * @param processOutputNum Process Profile Output Amount
     * @param processId Process String
     * @return id Steel Asset String（Charge）
     */
    function _processProductAsset(bytes32 productAssetId, uint num, bytes32 processProductArvId, uint processProductArvNum, uint processOutputNum, bytes32 processId) internal returns (bytes32) {
        (,address key,bytes32 productArvId,,uint balance,,,,bool isDel,) = steelAssetManager.getSteelProductAsset(productAssetId);
        require(key == msg.sender, "The sender has no ownership");
        require(!isDel, "Input product asset has been deleted");
        require(productArvId == processProductArvId, "Input product asset must match archive id");
        // Burn Process Material Information
        steelAssetManager.deleteSteelProductAsset(productAssetId, block.timestamp);
        // Create Process Material Charge Information
        balance = balance.sub(num.mul(processProductArvNum).div(processOutputNum));
        bytes32 id = bytes32(0);
        if(balance > 0) {
            id = steelAssetManager.createSteelProductAssetByManager(productAssetId, msg.sender, balance, block.timestamp, 2, processId);
        }
        return id;
    }

}