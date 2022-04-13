pragma solidity 0.8.4;

library HabitStructs {

    struct Commitment {
        uint256 timesPerTimeframe;
        //Habit should be done every X time
        uint256 timeframe;
        //Amount of times the habit has to be done to allow the bid amount to be withdrawn
        uint256 chainCommitment;
        uint256 stakeAmount;
        //0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH
        address tokenStaked;
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
        bool stakeClaimed;
        address beneficiary;
        Commitment commitment;
        Accomplishment accomplishment;
    }

    struct HabitDataWithOwner {
        HabitData habitData;
        address owner;
    }
    
}
