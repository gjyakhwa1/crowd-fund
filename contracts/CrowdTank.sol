//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./InterfaceCommissionStore.sol";

contract CrowdTank {
    struct Project {
        address creator;
        string name;
        string description;
        uint fundingGoal;
        uint deadline;
        uint amountRaised;
        bool funded;
        address highestFunder; // Hard Task 3(a)
        uint highestFundAmount; //Hard Task 3(b)
    }

    //Easy Task 5
    uint public totalFudingRaised;

    //Moderate Task 1
    uint public totalProjectsCreated;

    //Hard Task 4
    uint public totalFundedProjects;
    uint public totalFailedProjects;

    //Hard Task 5
    ICommissionStore public commissionStore;

    //Hard task 1(a)
    address public admin;
    constructor(address payable _commissionStore) {
        admin = msg.sender;
        commissionStore = ICommissionStore(_commissionStore);
    }

    //mapping for key value pairs
    mapping(uint => Project) public projects;

    mapping(uint => mapping(address => uint)) public contributions;

    mapping(uint => bool) public isIdUsed;

    //Moderate Task 1
    mapping(address => uint) public projectCreatedBy;

    //Hard task 1(b)
    mapping(address => bool) public creators;

    //events
    event ProjectCreated(
        uint indexed projectId,
        address indexed creator,
        string name,
        string description,
        uint fundingGoal,
        uint deadline
    );
    event ProjectFunded(
        uint indexed projectId,
        address indexed contributor,
        uint amount
    );
    event FundsWithdrawn(
        uint indexed projectId,
        address indexed withdrawer,
        uint amount,
        string withdrawerType
    );

    //Easy Task 1
    event UserWithdrawFund(
        uint indexed projectId,
        address indexed withdrawer,
        uint amount
    );
    //Easy Task 1
    event AdminWithdrawFund(
        uint indexed projectId,
        address indexed withdrawer,
        uint amount
    );

    event CreatorAdded(address creator);
    event CreatorRemoved(address creator);
    event ProjectStatusUpdated(uint projectId, bool funded);

    modifier onlyCreator(uint _projectId) {
        require(
            projects[_projectId].creator == msg.sender,
            "Only project creator can perform this action"
        );
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "Only admin can perform this action");
        _;
    }

    //Create Project by a creator
    //using calldata instead of memory or storage because it is readonly memory type of storage
    function createProject(
        string calldata _name,
        string calldata _description,
        uint _fundingGoal,
        uint _durationSeconds,
        uint _projectId
    ) external {
        require(!isIdUsed[_projectId], "Project Id is already used");

        //Hard Task 1(d)
        require(
            creators[msg.sender],
            "You are not provided permission to create project by the admin."
        );

        isIdUsed[_projectId] = true;
        projects[_projectId] = Project({
            creator: msg.sender,
            name: _name,
            description: _description,
            fundingGoal: _fundingGoal,
            deadline: block.timestamp + _durationSeconds,
            amountRaised: 0,
            funded: false,
            highestFunder: address(0), //Hard Task 3(a)
            highestFundAmount: 0 //Hard Task 3(b)
        });
        totalProjectsCreated++; //Moderate Task 1
        projectCreatedBy[msg.sender]++; //Moderate Task 1

        emit ProjectCreated(
            _projectId,
            msg.sender,
            _name,
            _description,
            _fundingGoal,
            block.timestamp + _durationSeconds
        );
    }

    function fundProject(uint _projectId) external payable {
        Project storage project = projects[_projectId];
        require(
            block.timestamp <= project.deadline,
            "Project deadline is already passed"
        );
        require(!project.funded, "Project is already funded");
        require(msg.value > 0, "You must send some ether");

        //Hard Task 5
        uint amountFunded = msg.value;
        uint commissionAmount = (5 * amountFunded) / 100;

        uint amountToFund = amountFunded - commissionAmount;

        uint refundAmount = 0; //Moderate Task 4

        if (project.amountRaised + amountToFund > project.fundingGoal) {
            refundAmount =
                project.amountRaised +
                amountToFund -
                project.fundingGoal;
            amountToFund -= refundAmount;
        }

        if (amountToFund > project.highestFundAmount) {
            project.highestFundAmount = amountToFund;
            project.highestFunder = msg.sender;
        }

        project.amountRaised += amountToFund;
        contributions[_projectId][msg.sender] = amountToFund;

        totalFudingRaised += amountToFund; //Easy Task 5

        (bool success, ) = address(commissionStore).call{value: commissionAmount}(abi.encodeWithSignature("receiveCommission()"));
        require(success, "Failed to send ether to CommissionStore");

        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }

        if (project.amountRaised >= project.fundingGoal) {
            project.funded = true;
            totalFundedProjects++;
            emit ProjectStatusUpdated(_projectId, true);
        }
        emit ProjectFunded(_projectId, msg.sender, amountToFund);
    }

    function userWithdrawFunds(uint _projectId) external payable {
        Project storage project = projects[_projectId];
        require(
            project.amountRaised < project.fundingGoal,
            "Funding goal is reached, user cannot withdraw"
        );
        uint fundContributed = contributions[_projectId][msg.sender];
        payable(msg.sender).transfer(fundContributed);
        contributions[_projectId][msg.sender] = 0;
        totalFudingRaised -= contributions[_projectId][msg.sender];
        emit UserWithdrawFund(_projectId, msg.sender, fundContributed);
    }

    function adminWithdrawFunds(
        uint _projectId
    ) external payable onlyCreator(_projectId) {
        Project storage project = projects[_projectId];
        uint totalFunding = project.amountRaised;
        require(project.funded, "Funding is not sufficient");
        require(
            project.deadline <= block.timestamp,
            "Deadline for project is not reached"
        );
        payable(msg.sender).transfer(totalFunding);
        emit AdminWithdrawFund(_projectId, msg.sender, totalFunding);
    }

    //Easy Task 2
    function remainingFund(uint _projectId) external view returns (uint) {
        Project storage project = projects[_projectId];
        if (project.funded) {
            return 0;
        }
        return project.fundingGoal - project.amountRaised;
    }

    //Easy Task 3
    function remainingTimeToFund(uint _projectId) external view returns (uint) {
        Project storage project = projects[_projectId];
        if (block.timestamp >= project.deadline) {
            return 0;
        }
        return project.deadline - block.timestamp;
    }

    //Moderate Task 2
    function extendDeadline(
        uint _projectId,
        uint _secondsToAdd
    ) external onlyCreator(_projectId) {
        Project storage project = projects[_projectId];
        uint newDeadline = block.timestamp + _secondsToAdd;
        require(
            newDeadline > project.deadline,
            "New deadline must be after the current deadline"
        );
        project.deadline = newDeadline;
    }

    //Moderate Task 3
    function increaseFundingAmount(
        uint _projectId,
        uint _newFundingGoal
    ) external onlyCreator(_projectId) {
        Project storage project = projects[_projectId];
        require(
            _newFundingGoal <= (project.fundingGoal * 150) / 100,
            "Cannot increase fund more than 50%"
        );
        project.fundingGoal = _newFundingGoal;
    }

    //Moderate Task 5
    function getFundingPercentage(
        uint _projectId
    ) external view returns (uint) {
        Project storage project = projects[_projectId];
        return (project.amountRaised * 100) / project.fundingGoal;
    }

    //Hard Task 1(b)
    function addCreator(address creator) external onlyAdmin {
        creators[creator] = true;
        emit CreatorAdded(creator);
    }

    //Hard Task 1(c)
    function removeCreator(address creator) external onlyAdmin {
        creators[creator] = false;
        emit CreatorRemoved(creator);
    }

    //Hard Task 2
    function userWithdrawBeforeDeadline(uint _projectId) external payable {
        Project storage project = projects[_projectId];
        uint userFundedAmount = contributions[_projectId][msg.sender];
        require(userFundedAmount > 0, "You have not funded this project");
        require(block.timestamp < project.deadline, "Deadline has passed");
        uint withdrawAmount = (userFundedAmount * 95) / 100;
        payable(msg.sender).transfer(withdrawAmount);
        payable(admin).transfer(userFundedAmount - withdrawAmount);
        contributions[_projectId][msg.sender] = 0;
        totalFudingRaised -= userFundedAmount;
        emit UserWithdrawFund(_projectId, msg.sender, userFundedAmount);
    }

    //Hard Task 4
    function updateProjectStatus(uint _projectId) public {
        Project storage project = projects[_projectId];
        require(
            block.timestamp > project.deadline,
            "Funding deadline for project is not met"
        );
        if (project.amountRaised >= project.fundingGoal) {
            project.funded = true;
            totalFundedProjects++;
        } else {
            totalFailedProjects++;
        }
        emit ProjectStatusUpdated(_projectId, project.funded);
    }
}
