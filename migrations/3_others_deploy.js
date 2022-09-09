const SteelAssetManager = artifacts.require("SteelAssetManager");
const SteelTradeManager = artifacts.require("SteelTradeManager");
const SteelProcessManager = artifacts.require("SteelProcessManager");

module.exports = function(deployer) {
  deployer.deploy(SteelTradeManager, SteelAssetManager.address)
    .then((contract) => {
      console.log(`SteelTradeManager is deployed at ${contract.address}`);
    });

    deployer.deploy(SteelProcessManager, SteelAssetManager.address)
    .then((contract) => {
      console.log(`SteelProcessManager is deployed at ${contract.address}`);
    });
};
