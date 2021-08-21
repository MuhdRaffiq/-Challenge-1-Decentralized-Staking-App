pragma solidity >=0.6.0 <0.9.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = now + 60 seconds;
    bool openForWithdraw = false;

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    event Stake(address, uint256);

    mapping(address => uint256) public balances;

    modifier thresholdreached() {
        require(address(this).balance >= threshold, "need to reach certain");
        _;
    }

    modifier withdrawStatus(bool openForWithdraw) {
        if (openForWithdraw) {
            require(
                address(this).balance <= threshold,
                "must be below threshold to withdraw"
            );
        } else {
            require(
                address(this).balance >= threshold,
                "must be more than thershold"
            );
        }
        _;
    }

    modifier deadlineReached() {
        require(
            now > deadline,
            "cannot perform function, deadline has not been reached"
        );
        _;
    }

    modifier notCompleted() {
        require(
            !exampleExternalContract.completed(),
            "calling of external contract must not in process"
        );
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    function stake() external payable {
        balances[msg.sender] += msg.value;

        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

    function execute()
        external
        payable
        thresholdreached
        deadlineReached
        notCompleted
    {
        // must be over threshold
        // must meet the deadline (30 seconds from now)

        exampleExternalContract.complete{value: address(this).balance}();
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function

    function withdraw(address payable wallet)
        external
        withdrawStatus(true)
        notCompleted
    {
        uint256 withdrawBalance = balances[wallet];
        balances[wallet] = 0;
        // address payable send = wallet;
        wallet.transfer(withdrawBalance);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

    function timeLeft() public view returns (uint256) {
        if (now >= deadline) {
            return 0;
        } else {
            uint256 timeLeft = deadline - now;
            return timeLeft;
        }
    }
}
