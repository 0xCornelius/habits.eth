// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./Habit.sol";
import "./libraries/HabitStructs.sol";

error HabitAlreadyExpired(uint256 habitId);
error HabitNotExpiredYet(uint256 habitId);
error HabitNotInValidState(uint256 habitId, bool expired);
error ChainCommitmentAccomplished(uint256 habitId, bool accomplished);

contract HabitManager {
    Habit public immutable habitContract;

    constructor(Habit _habit) {
        habitContract = _habit;
    }

    function commit(
        string memory habitName,
        string memory description,
        uint256 timeframe,
        uint256 chainCommitment,
        address beneficiary,
        uint256 startTime,
        uint256 timesPerTimeframe
    ) public payable returns (uint256) {
        HabitNFT.timeframeToDescription(timeframe);
        uint256 habitId = habitContract.getCurrentHabitId();
        HabitStructs.Commitment memory commitment = HabitStructs.Commitment(
            timesPerTimeframe,
            timeframe,
            chainCommitment
        );
        string[] memory proofs;
        HabitStructs.Accomplishment memory accomplishment = HabitStructs
            .Accomplishment(0, startTime, startTime + timeframe, 0, proofs);
        HabitStructs.HabitData memory habitData = HabitStructs.HabitData(
            habitId,
            habitName,
            description,
            msg.value,
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

        habitContract.done(habitId, newProof, newPeriodStart, newPeriodEnd, newPeriodTimesAccomplished);
    }

    function claimStake(uint256 habitId)
        public
        onlyHabitOwner(habitId)
        chainCommitmentDone(habitId, true)
        stakeNotClaimed(habitId)
    {
        (bool sent, ) = msg.sender.call{
            value: habitContract.getHabitData(habitId).stake
        }("");
        require(sent, "Failed to send Ether");
        habitContract.stakeClaimed(habitId);
    }

    function claimBrokenCommitment(uint256 habitId)
        public
        habitExpired(habitId, true)
        chainCommitmentDone(habitId, false)
        stakeNotClaimed(habitId)
    {
        HabitStructs.HabitData memory habit = habitContract.getHabitData(habitId);
        (bool sent, ) = habit.beneficiary.call{value: habit.stake}("");
        require(sent, "Failed to send Ether");
        habitContract.stakeClaimed(habitId);
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
