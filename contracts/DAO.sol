//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "hardhat/console.sol";
import "./Token.sol";

contract DAO {
    address owner;
    Token public token;
    uint256 public quorum;

    modifier onlyInvestor() {
        require(
            token.balanceOf(msg.sender) > 0,
            "Must be token holder..."
        );
        _;
    }

    struct Proposal {
        uint256 id;
        string name;
        uint256 amount;
        address payable recipient;
        uint256 votes;
        bool finalized;
    }
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals; 
    mapping(address => mapping (uint256 => bool)) votes;
    event Propose(
        uint256 id,
        uint256 amount,
        address recipient,
        address creator
    );
    event Vote(
        uint256 id,
        address investor
    );
    event Finalize(
        uint256 id
    );

    constructor(Token _token, uint256 _quorum) {
        owner = msg.sender;
        token = _token;
        quorum = _quorum;
        proposalCount = 0;
    }

    receive() external payable {}

    function createProposal(
        string memory _name,
        uint256 _amount,
        address payable _recipient
    ) external onlyInvestor {
        require(address(this).balance >= _amount);
        proposalCount++;
        proposals[proposalCount] = Proposal(
            proposalCount,
            _name,
            _amount,
            _recipient,
            0,
            false
        );
        emit Propose(
            proposalCount,
            _amount,
            _recipient,
            msg.sender
        );
    }

    function vote(uint256 _id) external onlyInvestor {
        require(!votes[msg.sender][_id], "Already voted...");
        proposals[_id].votes =
            proposals[_id].votes
            + token.balanceOf(msg.sender);
        votes[msg.sender][_id] = true;
        emit Vote(_id, msg.sender);
    }

    function finalizeProposal(uint256 _id) external onlyInvestor {
        Proposal storage proposal = proposals[_id];
        require(proposal.finalized == false, "Proposal already finalized...")
;        require(proposal.votes >= quorum, "Quorum not reached...");
        (bool sent, ) = proposal.recipient.call{value: proposal.amount}("");
        require(sent);
        proposal.finalized = true;
        emit Finalize(proposal.id);
    }

}
