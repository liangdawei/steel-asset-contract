// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./lib/Ownable.sol";

/**
 * @title Steel Asset Register Centre
 * @dev For create profile information such as raw steel, steel products and steel product processing
 */
contract SteelArchiveManager is Ownable {

    // Raw steel Profile
    struct SteelRawArchive {
        // Raw Steel Profile String
        bytes32 id;
        // Public Key
        address key;
        // Code
        bytes32 code;
        // Spec Name
        string specs;
        // element ingredients
        string ingredients;
    }

    // Steel Product Profile
    struct SteelProductArchive {
        // Steel Product Profile String
        bytes32 id;
        // Public Key
        address key;
        // Code
        bytes32 code;
        // Product Name
        string name;
        // Unit Weight
        uint weight;
        // Yield Rate
        uint yieldRate;
    }

    // Steel Product Process Profile
    struct SteelProcessArchive {
        // Steel Product Process Profile String
        bytes32 id;
        // Public Key
        address key;
        // Code
        bytes32 code;
        // Processing Name
        string name;
        // Steel Product Profile String
        bytes32 productArvId;
        // Raw Steel Profile Input String List
        bytes32[] rawArvIdList;
        // Raw Steel Profile Input Amount List
        uint[] rawArvNumList;
        // Steel Product Input String List
        bytes32[] productArvIdList;
        // Steel Product Input Amount List
        uint[] productArvNumList;
        // Output Amount
        uint outputNum;
    }

    // Raw Steel Profile List
    mapping (bytes32 => SteelRawArchive) rawArvList;
    // Steel Product Profile List
    mapping (bytes32 => SteelProductArchive) productArvList;
    // Steel Product Process Profile List
    mapping (bytes32 => SteelProcessArchive) processArvList;

    // event for EVM logging
    event SteelRawArchiveCreated(address indexed key, bytes32 indexed code, bytes32 indexed id, string specs, string ingredients, uint timestamp);
    event SteelProductArchiveCreated(address indexed key, bytes32 indexed code, bytes32 indexed id, string name, uint weight, uint yieldRate, uint timestamp);
    event SteelProcessArchiveCreated(address indexed key, bytes32 indexed code, bytes32 indexed id, string name, bytes32 productArvId, 
        bytes32[] rawArvIdList, uint[] rawArvNumList, bytes32[] productArvIdList, uint[] productArvNumList, uint outputNum, uint timestamp);

    /**
     * @dev Create Raw Steel Profile
     * @param key Public Key
     * @param code Code
     * @param specs Spec Name
     * @param ingredients element ingredients
     * @return id Raw Steel Profile String
     */
    function createSteelRawArchive(address key, bytes32 code, string memory specs, string memory ingredients) public onlyOwner returns (bytes32) {
        require(key != address(0), "The key can not be zero address");
        bytes32 id = keccak256(abi.encode(key, code, bytes(specs), bytes(ingredients)));
        rawArvList[id].id = id;
        rawArvList[id].key = key;
        rawArvList[id].code = code;
        rawArvList[id].specs = specs;
        rawArvList[id].ingredients = ingredients;
        emit SteelRawArchiveCreated(key, code, id, specs, ingredients, block.timestamp);
        return id;
    }

    /**
     * @dev Create Steel Product Profile
     * @param key Public Key
     * @param code Code
     * @param name Product Name
     * @param weight Unit Weight
     * @param yieldRate Yield Rate
     * @return id Steel Product Profile String
     */
    function createSteelProductArchive(address key, bytes32 code, string memory name, uint weight, uint yieldRate) public onlyOwner returns (bytes32) {
        require(key != address(0), "The key can not be zero address");
        bytes32 id = keccak256(abi.encode(key, code, bytes(name), weight, yieldRate));
        productArvList[id].id = id;
        productArvList[id].key = key;
        productArvList[id].code = code;
        productArvList[id].name = name;
        productArvList[id].weight = weight;
        productArvList[id].yieldRate = yieldRate;
        emit SteelProductArchiveCreated(key, code, id, name, weight, yieldRate, block.timestamp);
        return id;
    }

    /**
     * @dev Create Steel Product Process Profile
     * @param key Public Key
     * @param code Code
     * @param name Processing Name
     * @param productArvId Steel Product Profile String
     * @param rawArvIdList Raw Steel Profile Input String List
     * @param rawArvNumList Raw Steel Profile Input Amount List
     * @param productArvIdList Steel Product Input String List
     * @param productArvNumList Steel Product Input Amount List
     * @param outputNum Output Amount
     * @return id Steel Product Process Profile String
     */
    function createSteelProcessArchive(address key, bytes32 code, string memory name, bytes32 productArvId, bytes32[] memory rawArvIdList, 
    uint[] memory rawArvNumList, bytes32[] memory productArvIdList, uint[] memory productArvNumList, uint outputNum) public onlyOwner returns (bytes32) {
        require(key != address(0), "The key can not be zero address");
        require(rawArvIdList.length == rawArvNumList.length, " Input raw archive id list must match the num list");
        require(productArvIdList.length == productArvNumList.length, "Input product archive id list must match the num list");
        // It is not decided whether  productArvNumList include productArvId 
        bytes32 id = keccak256(abi.encode(key, code, bytes(name), productArvId, rawArvIdList, rawArvNumList, productArvIdList, productArvNumList, outputNum));
        processArvList[id].id = id;
        processArvList[id].key = key;
        processArvList[id].code = code;
        processArvList[id].name = name;
        processArvList[id].productArvId = productArvId;
        processArvList[id].rawArvIdList = rawArvIdList;
        processArvList[id].rawArvNumList = rawArvNumList;
        processArvList[id].productArvIdList = productArvIdList;
        processArvList[id].productArvNumList = productArvNumList;
        processArvList[id].outputNum = outputNum;
        emit SteelProcessArchiveCreated(key, code, id, name, productArvId, rawArvIdList, rawArvNumList, productArvIdList, productArvNumList, outputNum, block.timestamp);
        return id;
    }

    /**
     * @dev Get Raw Steel Profile
     * @param id Raw Steel Profile String
     * @return id Raw Steel Profile String
     * @return key Public Key
     * @return code Code
     * @return specs Spec Name
     * @return ingredients element ingredients
     */
    function getSteelRawArchive(bytes32 id) public view returns (bytes32, address, bytes32, string memory, string memory) {
        SteelRawArchive memory archive = rawArvList[id];
        return(archive.id, archive.key, archive.code, archive.specs, archive.ingredients);
    }

    /**
     * @dev Get Steel Product Profile
     * @param id Steel Product Profile String
     * @return id Steel Product Profile String
     * @return key Public Key
     * @return code Code
     * @return name Product Name
     * @return weight Unit Weight
     * @return yieldRate Yield Rate
     */
    function getSteelProductArchive(bytes32 id) public view returns (bytes32, address, bytes32, string memory, uint, uint) {
        SteelProductArchive memory archive = productArvList[id];
        return(archive.id, archive.key, archive.code, archive.name, archive.weight, archive.yieldRate);
    }

    /**
     * @dev Get Steel Product Process Profile
     * @param id Steel Product Process Profile String
     * @return id Steel Product Process Profile String
     * @return key Public Key
     * @return code 加⼯Code
     * @return name Processing Name
     * @return productArvId Steel Product Profile String
     * @return rawArvIdList Raw Steel Profile Input String List
     * @return rawArvNumList Raw Steel Profile Input Amount List
     * @return productArvIdList Steel Product Input String List
     * @return productArvNumList Steel Product Input Amount List
     * @return outputNum Output Amount
     */
    function getSteelProcessArchive(bytes32 id) public view returns (bytes32, address, bytes32, string memory, bytes32, 
    bytes32[] memory, uint[] memory, bytes32[] memory, uint[] memory, uint) {
        SteelProcessArchive memory archive = processArvList[id];
        return(archive.id, archive.key, archive.code, archive.name, archive.productArvId, archive.rawArvIdList, 
        archive.rawArvNumList, archive.productArvIdList, archive.productArvNumList, archive.outputNum);
    }
}