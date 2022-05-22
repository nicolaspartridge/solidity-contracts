// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    // You can only send ETH to payable addresses
    address payable[] public players;
    // Declare a manager who controls the lottery
    address public manager;

    constructor() {
        // Setting the manager to the address that deployed the contract
        manager = msg.sender;
    }

    // Special receive function -- does not require 'function' keyword
    // This runs automatically when the contract reveives ETH
    receive() external payable {
        // If the value sent is not == 0.1 ether -> transaction will fail
        // Gas will be consumed regardless
        require(msg.value == 0.1 ether);
        // Do not allow the manager to participate in the lottery
        require(msg.sender != manager);
        players.push(payable(msg.sender));
    }

    // Function to get the balance of the lottery
    function getBalance() public view returns(uint) {
        // Only allow the manager to see the contract balance
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public view returns(uint) {
        // Create a "semi" random variable
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public {
        require(msg.sender == manager);
        require(players.length >= 3);
        // calls funciton to create "semi" random variable
        uint r = random();
        address payable winner;
        // Choses random index
        uint index = r % players.length;
        // Picks winner based on random index
        winner = players[index];
        // Transfers lottery balance to winner
        address payable fee = payable(manager);
        // Pay 20% to the manager
        fee.transfer(getBalance() / 5);
        // Pay the remaining ETH to the winner
        winner.transfer(getBalance());
        // Resets the lottery
        players = new address payable[](0);
    }

}