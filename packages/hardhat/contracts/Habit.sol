pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error HabitAlreadyExpired(uint256 habitId);
error HabitNotExpiredYet(uint256 habitId);
error HabitNotInValidState(uint256 habitId, bool expired);
error ChainCommitmentAccomplished(uint256 habitId, bool accomplished);

contract Habit is ERC721 {
    constructor() ERC721("Habit", "HBT") {}

    using Counters for Counters.Counter;
    Counters.Counter private _habitIds;

    struct Commitment {
        uint256 timesPerTimeframe;
        //Habit should be done every X time
        uint256 timeframe;
        //Amount of times the habit has to be done to allow the bid amount to be withdrawn
        uint256 chainCommitment;
    }

    struct Accomplishment {
        //Amount of times the habit has been accomplished
        uint256 chain;
        uint256 periodStart;
        uint256 periodEnd;
        uint256 periodTimesAccomplished;
        string[] proofs;
    }

    struct HabitData {
        uint256 id;
        string name;
        string description;
        uint256 stake;
        bool stakeClaimed;
        address beneficiary;
        Commitment commitment;
        Accomplishment accomplishment;
    }

    mapping(uint256 => HabitData) habits;

    function commit(
        string memory habitName,
        string memory description,
        uint256 timeframe,
        uint256 chainCommitment,
        address beneficiary,
        uint256 startTime,
        uint256 timesPerTimeframe
    ) public payable returns (uint256) {
        uint256 habitId = _habitIds.current();
        Commitment memory commitment = Commitment(
            timesPerTimeframe,
            timeframe,
            chainCommitment
        );
        string[] memory proofs;
        Accomplishment memory accomplishment = Accomplishment(
            0,
            startTime,
            startTime + timeframe,
            0,
            proofs
        );
        habits[habitId] = HabitData(
            habitId,
            habitName,
            description,
            msg.value,
            false,
            beneficiary,
            commitment,
            accomplishment
        );
        _mint(msg.sender, habitId);
        _habitIds.increment();
        return habitId;
    }

    function done(uint256 habitId, string memory proof)
        public
        onlyHabitOwner(habitId)
        habitPeriodStarted(habitId)
        habitExpired(habitId, false)
    {
        HabitData storage habit = habits[habitId];
        Accomplishment storage accomplishment = habit.accomplishment;
        ++(accomplishment.chain);
        accomplishment.proofs.push(proof);
        Commitment storage commitment = habit.commitment;
        if (
            accomplishment.periodTimesAccomplished + 1 ==
            commitment.timesPerTimeframe
        ) {
            accomplishment.periodTimesAccomplished = 0;
            uint256 newPeriodStart = accomplishment.periodEnd;
            accomplishment.periodStart = newPeriodStart;
            accomplishment.periodEnd = newPeriodStart + commitment.timeframe;
        } else {
            ++(accomplishment.periodTimesAccomplished);
        }
    }

    function claimStake(uint256 habitId)
        public
        onlyHabitOwner(habitId)
        chainCommitmentDone(habitId, true)
        stakeNotClaimed(habitId)
    {
        HabitData storage habit = habits[habitId];
        (bool sent, ) = msg.sender.call{value: habit.stake}("");
        require(sent, "Failed to send Ether");
        habit.stakeClaimed = true;
    }

    function claimBrokenCommitment(uint256 habitId)
        public
        habitExpired(habitId, true)
        chainCommitmentDone(habitId, false)
        stakeNotClaimed(habitId)
    {
        HabitData storage habit = habits[habitId];
        (bool sent, ) = habit.beneficiary.call{value: habit.stake}("");
        require(sent, "Failed to send Ether");
        habit.stakeClaimed = true;
    }

    function getHabitData(uint256 habitId)
        public
        view
        returns (HabitData memory)
    {
        return habits[habitId];
    }

    modifier stakeNotClaimed(uint256 habitId) {
        require(!habits[habitId].stakeClaimed, "Stake already claimed.");
        _;
    }

    modifier onlyHabitOwner(uint256 habitId) {
        require(
            msg.sender == ownerOf(habitId),
            "Only the owner can interact with the habit"
        );
        _;
    }

    modifier chainCommitmentDone(uint256 habitId, bool commitmentDone) {
        HabitData storage habit = habits[habitId];
        bool isAccomplished = habit.accomplishment.chain >=
            habit.commitment.chainCommitment;
        if (commitmentDone != isAccomplished) {
            revert ChainCommitmentAccomplished(habitId, isAccomplished);
        }
        _;
    }

    modifier habitPeriodStarted(uint256 habitId) {
        require(
            block.timestamp >= habits[habitId].accomplishment.periodStart,
            "Habit period did not start yet."
        );
        _;
    }

    modifier habitExpired(uint256 habitId, bool expired) {
        bool habitIsExpired = block.timestamp >
            habits[habitId].accomplishment.periodEnd;
        if (habitIsExpired != expired) {
            revert HabitNotInValidState({
                habitId: habitId,
                expired: habitIsExpired
            });
        }
        _;
    }
}
