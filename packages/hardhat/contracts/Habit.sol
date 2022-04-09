// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./libraries/HabitNFT.sol";
import "./libraries/HabitStructs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Habit is ERC721, Ownable {
    using Counters for Counters.Counter;

    using Counters for Counters.Counter;
    Counters.Counter internal _habitIds;

    mapping(uint256 => HabitStructs.HabitData) habits;

    constructor() ERC721("Habit", "HABIT") {}

    function tokenURI(uint256 habitId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        HabitStructs.HabitData memory habit = habits[habitId];
        HabitNFT.HabitNFTData memory habitNFTData = HabitNFT.HabitNFTData({
            name: habit.name,
            description: habit.description,
            id: habit.id,
            chain: habit.accomplishment.chain,
            chainCommitment: habit.commitment.chainCommitment,
            timeframeString: HabitNFT.timeframeToDescription(
                habit.commitment.timeframe
            ),
            timesPerTimeframe: habit.commitment.timesPerTimeframe,
            stake: habit.stake,
            beneficiary: habit.beneficiary
        });
        return HabitNFT.generateTokenURI(habitNFTData);
    }

    function getAllHabits()
        public
        view
        returns (HabitStructs.HabitDataWithOwner[] memory)
    {
        HabitStructs.HabitDataWithOwner[]
            memory allHabits = new HabitStructs.HabitDataWithOwner[](
                _habitIds.current()
            );
        for (uint256 i; i < _habitIds.current(); ++i) {
            allHabits[i] = HabitStructs.HabitDataWithOwner(
                habits[i],
                ownerOf(i)
            );
        }
        return allHabits;
    }

    function getHabitData(uint256 habitId)
        public
        view
        returns (HabitStructs.HabitData memory)
    {
        return habits[habitId];
    }

    function mint(HabitStructs.HabitData memory _habitData, address minter)
        public
        onlyOwner
    {
        uint256 habitId = _habitData.id;
        habits[habitId] = _habitData;
        _mint(minter, habitId);
        _habitIds.increment();
    }

    function done(
        uint256 habitId,
        string memory newProof,
        uint256 newPeriodStart,
        uint256 newPeriodEnd,
        uint256 newPeriodTimesAccomplished
    ) public onlyOwner {
        HabitStructs.HabitData storage habit = habits[habitId];
        HabitStructs.Accomplishment storage accomplishment = habit
            .accomplishment;
        ++(accomplishment.chain);
        accomplishment.proofs.push(newProof);
        accomplishment.periodStart = newPeriodStart;
        accomplishment.periodEnd = newPeriodEnd;
        accomplishment.periodTimesAccomplished = newPeriodTimesAccomplished;
    }

    function stakeClaimed(uint256 habitId) public onlyOwner {
        habits[habitId].stakeClaimed = true;
    }

    function getCurrentHabitId() public view returns (uint256) {
        return _habitIds.current();
    }
}
