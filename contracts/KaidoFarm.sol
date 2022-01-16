// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KaidoToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface DaiToken {
    function transfer(address beneficiary, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address user) external view returns(uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
}

contract KaidoFarm is Ownable {

    string public name = 'KaidoFarm';

    KaidoToken public kaidoToken;  //ERC20 contract object
    DaiToken public daiToken;       //Dai contract object
    
    address[] public stakers;

    mapping(address => uint256) public startTime;
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public kaidoTokenBalance;
    mapping(address => bool) public isStaking;

    /**
    @dev DaiToken address must be inserted in migrations
    when this contract deploys. */


    constructor(KaidoToken _kaidoToken, DaiToken _daiToken) public {
        kaidoToken = _kaidoToken;
        daiToken = _daiToken;
    }

    /**
    *@notice A function that stakes stablecoin Dai to the contract.

    *@dev After Dai transfers to the contract, the mapped staking balance updates. 
    *     This is necessary because the contract only pays out when the user withdraws 
    *     their earnings. The mapping keeps track of said yield.

    *@param _amount The amount to be staked to the contract.
     */

    function stake(uint256 _amount) public {
        require(_amount > 0, 'You cannot stake zero tokens');
        daiToken.transferFrom(msg.sender, address(this), _amount);
        stakingBalance[msg.sender] += _amount;
        isStaking[msg.sender] = true;
        startTime[msg.sender] = block.timestamp;
    } 

    function calculateYieldTime(address _user) public view returns(uint256) {
        uint end = block.timestamp;
        uint totalTime = end - startTime[_user];
        uint inMinutes = totalTime / 60;
        return inMinutes;        
    }

    /**@notice A method for withdrawing the hodlToken yield.
    *@dev The timeStaked uint takes the result of the calculateYield function. 
    *     This contract gives the user 1% of their Dai balance in HodlToken every 60 
    *     seconds. After fetching the the calculated balance, the contract checks for 
    *     an existing balance mapped to hodlBalance. This mapping is only relevant if 
    *     the user staked Dai multiple times without unstaking/withdrawing. Further, the
    *     staking balance of the user is first multiplied by the time staked before
    *     divided by 100 to equate 1% of the user's stake (per minute as seen in the
    *     calculateYield function).
     */
    function withdrawYield() public {
        require(kaidoTokenBalance[msg.sender] > 0 || startTime[msg.sender] != block.timestamp);
        uint256 timeStaked = calculateYieldTime(msg.sender);
        uint256 bal = (stakingBalance[msg.sender] * timeStaked)/100;
        if(kaidoTokenBalance[msg.sender] != 0) {
            uint256 oldBal = kaidoTokenBalance[msg.sender];
            kaidoTokenBalance[msg.sender] = 0;
            bal += oldBal;
        }

        startTime[msg.sender] = block.timestamp;
        kaidoToken.transfer(msg.sender, bal);
    }

    /**@notice A method for users to take back their tokens from the contract.
    *@dev The timeStaked uint gathers the yield time. The staked time(in minutes) is 
    *     mulitplied by the staking balance and divided by 100 (ergo, 1% every minute). The 
    *     contract resets the timestamp to prevent reentry. Thereafter, the previously saved 
    *     yield balance (if applicable) is added to the current yield figure. Finally, the actual 
    *     transfer of Dai back to the user occurs.
    *
     */

     function unstake() public {
         require(isStaking[msg.sender] = true, 'You are not staking tokens');
         uint256 timeStaked = calculateYieldTime(msg.sender);
         uint256 yield = (stakingBalance[msg.sender] * timeStaked)/100;
         startTime[msg.sender] = block.timestamp;
         kaidoTokenBalance[msg.sender] += yield;


         uint256 balance = stakingBalance[msg.sender];
         require(balance > 0, 'You do not have enough funds to withdraw');
         stakingBalance[msg.sender] = 0;
         daiToken.transfer(msg.sender, balance);
         isStaking[msg.sender] = false;
     }


}