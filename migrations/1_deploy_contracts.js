// const ConvertLib = artifacts.require("ConvertLib");
// const MetaCoin = artifacts.require("MetaCoin");

// module.exports = function(deployer) {
//   deployer.deploy(ConvertLib);
//   deployer.link(ConvertLib, MetaCoin);
//   deployer.deploy(MetaCoin);
// };


// const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

// const MyToken = artifacts.require('MyToken');

// module.exports = async function (deployer) {
//   const instance = await deployProxy(MyToken, [], { deployer, kind: "uups" });
// }


const MyToken = artifacts.require('MyToken');
const MyTokenProxy = artifacts.require('MyTokenProxy');
module.exports = async function (deployer) {
  const logic = await deployer.deploy(MyToken)
  console.log("MyToken address=", MyToken.address)
  const proxy = await deployer.deploy(MyTokenProxy, MyToken.address, 0x8129fc1c)
  console.log("proxy address=", MyTokenProxy.address)
}
