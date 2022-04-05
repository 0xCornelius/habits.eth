pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error HabitAlreadyExpired(uint256 habitId);
error HabitNotExpiredYet(uint256 habitId);
error HabitNotInValidState(uint256 habitId, bool expired);

contract Habit is ERC721 {
    constructor() ERC721("Habit", "HBT") {}

    using Counters for Counters.Counter;
    Counters.Counter private _habitIds;

    struct HabitData {
        uint256 id;
        string name;
        string description;
        //Habit should be done every X time
        uint256 timeframe;
        //Amount of times the habit has been accomplished
        uint256 chain;
        //Max time to acomplish the habit
        uint256 expirationTime;
        uint256 bidAmount;
        //Amount of times the habit has to be done to allow the bid amount to be withdrawn
        uint256 chainCommitment;
        address beneficiary;
    }

    mapping(uint256 => HabitData) habits;

    function commit(
        string memory habitName,
        string memory description,
        uint256 timeframe,
        uint256 chainCommitment,
        address beneficiary
    ) public payable returns (uint256) {
        uint256 habitId = _habitIds.current();
        habits[habitId] = HabitData(
            habitId,
            habitName,
            description,
            timeframe,
            0,
            block.timestamp + timeframe,
            msg.value,
            chainCommitment,
            beneficiary
        );
        _mint(msg.sender, habitId);
        _habitIds.increment();
        return habitId;
    }

    function done(uint256 habitId) public ifHabitInState(habitId, false) {
        require(
            msg.sender == ownerOf(habitId),
            "Only the owner can increment the chain"
        );
        ++(habits[habitId].chain);
        habits[habitId].expirationTime =
            block.timestamp +
            habits[habitId].timeframe;
    }

    function getHabitData(uint256 habitId)
        public
        view
        returns (HabitData memory)
    {
        return habits[habitId];
    }

    modifier ifHabitInState(uint256 habitId, bool expired) {
        bool habitExpired = block.timestamp < habits[habitId].expirationTime;
        if (habitExpired != expired) {
            revert HabitNotInValidState({
                habitId: habitId,
                expired: habitExpired
            });
        }
        _;
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("Can't transfer");
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert("Can't transfer");
    }
}
