// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // events
  event Stake(address indexed sender, uint256 amount);

  // mapping to store the balances of the stakers
  mapping(address => uint256) public balances;

  // threashold to be met
  uint256 public constant threshold = 1 ether;

  // deadline to be met
  uint256 public deadline = block.timestamp + 72 hours;

  // indicator to check whether able to withdraw or not
  bool public openForWithdraw = false;

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  function stake() public payable {
    require(msg.value > 0, "Stake amount should be greater than 0");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
    console.log("Stake amount: %s", msg.value/1e18);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public {
    // first check if the deadline has passed
    require(block.timestamp >= deadline, "Deadline has not passed yet");
    // check if the threshold is met
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
      openForWithdraw = false;
    } else {
      openForWithdraw = true;
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public {
    require(openForWithdraw, "Not open for withdraw yet");
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success, "Transfer failed.");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }
}
