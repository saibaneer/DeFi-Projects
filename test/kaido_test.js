const { assert } = require('chai');
const timeMachine = require('ganache-time-traveler');
// const { Contract } = require('ethers');
// const { default: Web3 } = require('web3');

const KaidoToken = artifacts.require("KaidoToken");
const KaidoFarm = artifacts.require("KaidoFarm");
const MockDai = artifacts.require("MockDai");

function tokensToWei(n) {
  return web3.utils.toWei(n, 'ether')
}

function tokensFromWei(n){
  return web3.utils.fromWei(n, 'ether')
}



contract("KaidoFarm", function([alice, bob]){

  let kaidoToken, mockDai, kaidoFarm;

  before(async function (){
    kaidoToken = await KaidoToken.new(tokensToWei('311000'));
    mockDai = await MockDai.new(tokensToWei('10000'));
    kaidoFarm = await KaidoFarm.new(kaidoToken.address, mockDai.address);
  
    await kaidoToken.transfer(kaidoFarm.address, tokensToWei('311000'));
    await mockDai.transfer(bob, tokensToWei('5000'), {from: alice})
  });  
  
  describe("MockDai Tokens", async function(){
    it("should have a name: MockDai", async function(){
      //await contractsDeployed();
      const name = await mockDai.name();
      assert.equal(name, 'MockDai', 'mockDai did not deploy properly')
    });
  
    it("users should have tokens", async function(){
      //await contractsDeployed();
      const aliceBal = await mockDai.balanceOf(alice);
      const bobBal = await mockDai.balanceOf(bob);
      assert.equal(aliceBal.toString(), tokensToWei('5000'), 'alice balance not correct');
      assert.equal(bobBal.toString(), tokensToWei('5000'), 'bob balance not correct');
    })
  })

  describe('farming tokens', async function(){

    it("should have a name: KaidoFarm", async function(){
      //await contractsDeployed();
      const name = await kaidoFarm.name();
      assert.equal(name, 'KaidoFarm', 'KaidoFarm did not deploy properly')
    });

    it("KaidoFarm should have tokens", async function(){
      //await contractsDeployed();
      const balance = await kaidoToken.balanceOf(kaidoFarm.address);
      assert.equal(balance.toString(), tokensToWei('311000'), 'KaidoFarm did not receive tokens!');
    });

    it("should test staking functions", async function (){
      let result;

      //check balance before testing
      result = await mockDai.balanceOf(alice);
      assert.equal(result.toString(), tokensToWei('5000'));

      //check approval and staking
      await mockDai.approve(kaidoFarm.address, tokensToWei("5000"), {from: alice});
      await kaidoFarm.stake(tokensToWei('5000'), {from: alice});

      //check balance of Alice's mDAI
      result = await mockDai.balanceOf(alice);
      assert.equal(result.toString(), tokensToWei('0'));

      //check that staking balance is correct
      result = await kaidoFarm.stakingBalance(alice)
      assert.equal(result.toString(), tokensToWei('5000'), 'staking balance for alice is not correct')

    })

    it("should print value after 1 year", async function(){
      result = await kaidoFarm.stakingBalance(alice);
      console.log(tokensFromWei(result.toString()))
      await timeMachine.advanceTimeAndBlock('31536000');
      result = await kaidoFarm.stakingBalance(alice);
      console.log(tokensFromWei(result.toString()))
    })
  })

})