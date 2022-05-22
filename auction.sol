// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AuctionCreator {
    Auction[] public auctions;

    function createAuction() public {
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction {
    // Declare the owner of the auction
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids;

    uint bidIncrement;

    constructor(address eoa) {
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320;
        ipfsHash = "";
        bidIncrement = 100;
    }

    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= startBlock);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function min(uint a, uint b) pure internal returns(uint) {
        if(a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running);
        require(msg.value >= 100);

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled) {
            // Auction was canceled
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            // Auction ended (not canceled)
            if(msg.sender == owner) {
                recipient = owner;
                value = highestBindingBid;
            } else {
                // Bidder requesting funds back
                if(msg.sender == highestBidder) {
                    // Highest bidder requesting funds difference back
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    // A regular bidder requesting bid funds back
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            } 
        }

        // Reset the bid value of the recipient to 0
        // This ensures you can only widthdraw your money once
        bids[recipient] = 0;

        // Send funds to recipient
        recipient.transfer(value); 
    }
}