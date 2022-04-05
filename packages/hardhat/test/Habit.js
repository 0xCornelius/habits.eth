const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

describe("Habit", function () {
  let habit;

  const exampleHabitData = {
    name: "habitName",
    description: "habitDescription",
    timeframe: 24 * 60 * 60,
    chainCommitment: 10,
    beneficiary: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
  }

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  beforeEach(async () => {
    const HabitContract = await ethers.getContractFactory("Habit");

    habit = await HabitContract.deploy();
  })

  it("Should mint habit", async function () {
    const now = (new Date).getTime();
    await network.provider.send("evm_setNextBlockTimestamp", [now])
    await habit.commit(...Object.values(exampleHabitData), { value: ethers.utils.parseEther("1") })
    const createdHabit = await habit.getHabitData(0);

    expect(createdHabit.name).to.equal(exampleHabitData.name);
    expect(createdHabit.description).to.equal(exampleHabitData.description);
    expect(createdHabit.timeframe.toNumber()).to.equal(exampleHabitData.timeframe);
    expect(createdHabit.chainCommitment.toNumber()).to.equal(exampleHabitData.chainCommitment);
    expect(createdHabit.chain.toNumber()).to.equal(0);
    expect(createdHabit.beneficiary).to.equal(exampleHabitData.beneficiary);
    expect(createdHabit.bidAmount).to.equal(ethers.utils.parseEther("1"));
    const habitCreationTime = (createdHabit.expirationTime.toNumber() - exampleHabitData.timeframe);
    expect(habitCreationTime).to.equal(now);
  });

  it("Should increse the chain and expiration date when calling done", async function () {
    const now = (new Date).getTime();
    await network.provider.send("evm_setNextBlockTimestamp", [now])
    await habit.commit(...Object.values(exampleHabitData), { value: ethers.utils.parseEther("1") })
    await network.provider.send("evm_setNextBlockTimestamp", [now + exampleHabitData.timeframe])
    await habit.done(0);

    const createdHabit = await habit.getHabitData(0);
    expect(createdHabit.chain.toNumber()).to.equal(1);
    expect(createdHabit.expirationTime.toNumber()).to.equal(now + (exampleHabitData.timeframe)*2)
  })

});
