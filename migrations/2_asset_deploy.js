const SteelArchiveManager = artifacts.require("SteelArchiveManager");
const SteelAssetManager = artifacts.require("SteelAssetManager");

module.exports = function (deployer) {
  deployer.deploy(SteelAssetManager, SteelArchiveManager.address)
    .then((contract) => {
      console.log(`SteelAssetManager is deployed at ${contract.address}`);
    });
};
