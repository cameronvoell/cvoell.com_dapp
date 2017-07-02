var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
var ClaimableToken = artifacts.require("./ClaimableToken.sol");
var ProofOfReadToken = artifacts.require("./ProofOfReadToken.sol");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
  deployer.deploy(ClaimableToken);
  deployer.deploy(ProofOfReadToken);
};
