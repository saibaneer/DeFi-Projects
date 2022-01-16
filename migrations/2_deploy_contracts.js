const KaidoToken = artifacts.require("KaidoToken");
const KaidoFarm = artifacts.require('KaidoFarm');

const daiAddress = "0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658";

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(KaidoToken, '311000');
  const kaidoToken = await KaidoToken.deployed();

  await deployer.deploy(KaidoFarm, kaidoToken.address, daiAddress);
  const kaidoFarm = await KaidoFarm.deployed();

  await kaidoToken.transfer(kaidoFarm.address, '11000');
};
