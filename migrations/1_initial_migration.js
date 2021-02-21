const Migrations = artifacts.require("Migrations");
const Agent = artifacts.require("Agent");
const Agent_ = artifacts.require("Agent_");

module.exports = function (deployer, network) {
  if (network == "rinkeby") {
    deployer.deploy(Migrations);
    deployer.deploy(Agent, [
      "0xc7ad46e0b8a400bb3c915120d284aafba8fc4735", // DAI
      "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984", // UNI
      "0x8b22f85d0c844cf793690f6d9dfe9f11ddb35449" // UNI DAI-ETH LP
    ]);
  } else {
    deployer.deploy(Migrations);
    deployer.deploy(Agent_, []);
  }
};
