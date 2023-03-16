// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract Todo {

    struct Task {
        string work;
        bool status;
    }

    address public owner;
    uint public revenue;

    mapping(address => Task[]) public taskList;
    mapping(address => uint256) public rewardList;

    event TaskCreated(uint id, string work, bool status);
    event TaskToggled(uint id, string work, bool status);
    event TaskCompleted(address addr);
    event Withdraw(uint value);

    error TaskNotExist(uint id);
    error TaskNotComplete(uint id);
    error TransactionFailed(uint value);
    error NotAnOwner(address _addr);

    constructor() {
        owner = msg.sender;
    }

    modifier taskExist(uint _id) {
        if (_id >= taskList[msg.sender].length) {
            revert TaskNotExist(_id);
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotAnOwner(msg.sender);
        }
        _;
    }

    function createTask(string calldata _work) external payable {
        require(msg.value == 0.1 ether, "pay 0.1 eth");
        taskList[msg.sender].push(Task(_work, false));
        rewardList[msg.sender] += msg.value;
        emit TaskCreated(taskList[msg.sender].length - 1, _work, false);
    }

    function toggleTask(uint _id) external taskExist(_id) {
        taskList[msg.sender][_id].status = !taskList[msg.sender][_id].status;
        emit TaskToggled(_id, taskList[msg.sender][_id].work, taskList[msg.sender][_id].status);
    }

    function completeTask() external payable {
        for (uint i = 0; i < taskList[msg.sender].length; i++) {
            if (!taskList[msg.sender][i].status) {
                revert TaskNotComplete(i);
            }
        }

        uint reward = rewardList[msg.sender];
        uint charges = reward * 1 / 100;

        (bool sent, bytes memory data) = payable(msg.sender).call{value: reward - charges}("");

        if (!sent) {
            revert TransactionFailed(reward - charges);
        }

        revenue += charges;
        delete taskList[msg.sender];
        rewardList[msg.sender] = 0;
        emit TaskCompleted(msg.sender);
    }

    function getTask() external view returns (Task[] memory) {
        return taskList[msg.sender];
    }

    function getReward() external view returns (uint256) {
        return rewardList[msg.sender];
    }

    function getRevenue() external view onlyOwner returns (uint256) {
        return revenue;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function withdraw() external payable onlyOwner {
        (bool sent, bytes memory data) = payable(owner).call{value: revenue}("");
        revenue = 0;
        emit Withdraw(revenue);
    }

}
