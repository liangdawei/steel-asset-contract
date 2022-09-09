
const SteelArchiveManager = artifacts.require("SteelArchiveManager");

module.exports = function (deployer) {
  deployer.deploy(SteelArchiveManager)
    .then((contract) => {
      console.log(`SteelArchiveManager is deployed at ${contract.address}`);
    });
};
