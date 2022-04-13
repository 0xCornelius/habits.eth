// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./Habit.sol";
import "./libraries/HabitStructs.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error HabitAlreadyExpired(uint256 habitId);
error HabitNotExpiredYet(uint256 habitId);
error HabitNotInValidState(uint256 habitId, bool expired);
error ChainCommitmentAccomplished(uint256 habitId, bool accomplished);

contract HabitManager {
    Habit public immutable habitContract;

    address constant ethToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    string constant ethSymbol = "ETH";

    constructor(Habit _habit) {
        habitContract = _habit;
    }

    function commitETH(
        string memory habitName,
        string memory description,
        uint256 timeframe,
        uint256 chainCommitment,
        address beneficiary,
        uint256 startTime,
        uint256 timesPerTimeframe
    ) public payable returns (uint256) {
        HabitStructs.Commitment memory commitment = HabitStructs.Commitment(
            timesPerTimeframe,
            timeframe,
            chainCommitment,
            msg.value,
            ethToken
        );
        return
            _saveCommit(
                habitName,
                description,
                beneficiary,
                startTime,
                commitment
            );
    }

    function commit(
        string memory habitName,
        string memory description,
        uint256 timeframe,
        uint256 chainCommitment,
        address beneficiary,
        uint256 startTime,
        uint256 timesPerTimeframe,
        ERC20 stakeToken,
        uint256 stakeAmount
    ) public returns (uint256) {
        stakeToken.transferFrom(msg.sender, address(this), stakeAmount);
        HabitStructs.Commitment memory commitment = HabitStructs.Commitment(
            timesPerTimeframe,
            timeframe,
            chainCommitment,
            stakeAmount,
            address(stakeToken)
        );
        return
            _saveCommit(
                habitName,
                description,
                beneficiary,
                startTime,
                commitment
            );
    }

    function _saveCommit(
        string memory habitName,
        string memory description,
        address beneficiary,
        uint256 startTime,
        HabitStructs.Commitment memory commitment
    ) internal returns (uint256) {
        HabitNFT.timeframeToDescription(commitment.timeframe);
        uint256 habitId = habitContract.getCurrentHabitId();
        string[] memory proofs;
        HabitStructs.Accomplishment memory accomplishment = HabitStructs
            .Accomplishment(
                0,
                startTime,
                startTime + commitment.timeframe,
                0,
                proofs
            );
        HabitStructs.HabitData memory habitData = HabitStructs.HabitData(
            habitId,
            habitName,
            description,
            false,
            beneficiary,
            commitment,
            accomplishment
        );
        habitContract.mint(habitData, msg.sender);
        return habitId;
    }

    function done(uint256 habitId, string memory newProof)
        public
        onlyHabitOwner(habitId)
        habitPeriodStarted(habitId)
        habitExpired(habitId, false)
    {
        HabitStructs.HabitData memory habit = habitContract.getHabitData(
            habitId
        );
        HabitStructs.Accomplishment memory accomplishment = habit
            .accomplishment;

        uint256 newPeriodTimesAccomplished = accomplishment
            .periodTimesAccomplished + 1;
        uint256 newPeriodStart = accomplishment.periodStart;
        uint256 newPeriodEnd = accomplishment.periodEnd;

        if (
            accomplishment.periodTimesAccomplished + 1 ==
            habit.commitment.timesPerTimeframe
        ) {
            newPeriodTimesAccomplished = 0;
            newPeriodStart = accomplishment.periodEnd;
            newPeriodEnd = newPeriodStart + habit.commitment.timeframe;
        }

        habitContract.done(
            habitId,
            newProof,
            newPeriodStart,
            newPeriodEnd,
            newPeriodTimesAccomplished
        );
    }

    function claimStake(uint256 habitId)
        public
        onlyHabitOwner(habitId)
        chainCommitmentDone(habitId, true)
        stakeNotClaimed(habitId)
    {
        habitContract.stakeClaimed(habitId);
        HabitStructs.Commitment memory commitment = habitContract
            .getHabitData(habitId)
            .commitment;
        if (commitment.tokenStaked == ethToken) {
            (bool sent, ) = msg.sender.call{value: commitment.stakeAmount}("");
            require(sent, "Failed to send Ether");
        } else {
            ERC20 tokenERC20 = ERC20(commitment.tokenStaked);
            tokenERC20.transfer(msg.sender, commitment.stakeAmount);
        }
    }

    function claimBrokenCommitment(uint256 habitId)
        public
        habitExpired(habitId, true)
        chainCommitmentDone(habitId, false)
        stakeNotClaimed(habitId)
    {
        habitContract.stakeClaimed(habitId);
        HabitStructs.HabitData memory habit = habitContract.getHabitData(
            habitId
        );

        if (habit.commitment.tokenStaked == ethToken) {
            (bool sent, ) = msg.sender.call{
                value: habit.commitment.stakeAmount
            }("");
            require(sent, "Failed to send Ether");
        } else {
            ERC20 tokenERC20 = ERC20(habit.commitment.tokenStaked);
            tokenERC20.transfer(msg.sender, habit.commitment.stakeAmount);
        }
    }

    modifier stakeNotClaimed(uint256 habitId) {
        require(
            !habitContract.getHabitData(habitId).stakeClaimed,
            "Stake already claimed."
        );
        _;
    }

    modifier onlyHabitOwner(uint256 habitId) {
        require(
            msg.sender == habitContract.ownerOf(habitId),
            "Only the owner can interact with the habit"
        );
        _;
    }

    modifier chainCommitmentDone(uint256 habitId, bool commitmentDone) {
        HabitStructs.HabitData memory habit = habitContract.getHabitData(
            habitId
        );
        bool isAccomplished = habit.accomplishment.chain >=
            habit.commitment.chainCommitment;
        if (commitmentDone != isAccomplished) {
            revert ChainCommitmentAccomplished(habitId, isAccomplished);
        }
        _;
    }

    modifier habitPeriodStarted(uint256 habitId) {
        require(
            block.timestamp >=
                habitContract.getHabitData(habitId).accomplishment.periodStart,
            "Habit period did not start yet."
        );
        _;
    }

    modifier habitExpired(uint256 habitId, bool expired) {
        bool habitIsExpired = block.timestamp >
            habitContract.getHabitData(habitId).accomplishment.periodEnd;
        if (habitIsExpired != expired) {
            revert HabitNotInValidState({
                habitId: habitId,
                expired: habitIsExpired
            });
        }
        _;
    }
}
