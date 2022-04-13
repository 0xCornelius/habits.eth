const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

describe("Habit", () => {
  let habit;
  let habitManager;
  let erc20Mock;

  let habitNFT;
  let NFTSVG;
  let habitStructs;

  const now = (new Date).getTime();
  const hour = 60 * 60;

  let exampleHabitData;

  let ethToken = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";


  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  beforeEach(async () => {
    const [owner, ad1] = await ethers.getSigners();

    exampleHabitData = {
      name: "habitName",
      description: "habitDescription",
      timeframe: 24 * hour,
      chainCommitment: 2,
      beneficiary: ad1.address,
      startTime: now,
      timesPerTimeframe: 2,
    }

    await hre.network.provider.send("hardhat_reset")

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    erc20Mock = await ERC20Mock.deploy();
    erc20Mock.mint(ethers.utils.parseEther("10000"));

    const HabitStructsContract = await ethers.getContractFactory("HabitStructs");
    habitStructs = await HabitStructsContract.deploy();

    const NFTSVGContract = await ethers.getContractFactory("NFTSVG");
    NFTSVG = await NFTSVGContract.deploy();

    const HabitNFTContract = await ethers.getContractFactory("HabitNFT", {
      libraries: {
        NFTSVG: NFTSVG.address,
      },
    });
    habitNFT = await HabitNFTContract.deploy();

    const HabitContract = await ethers.getContractFactory("Habit", {
      libraries: {
        HabitNFT: habitNFT.address,
      },
    });
    const HabitManagerContract = await ethers.getContractFactory("HabitManager", {
      libraries: {
        HabitNFT: habitNFT.address,
      },
    });

    habit = await HabitContract.deploy();
    habitManager = await HabitManagerContract.deploy(habit.address);

    await habit.transferOwnership(habitManager.address);
  })

  describe("Mint", () => {


    it("Should mint habit with commitETH", async () => {
      await network.provider.send("evm_setNextBlockTimestamp", [now])
      await habitManager.commitETH(...Object.values(exampleHabitData), { value: ethers.utils.parseEther("1") })
      const createdHabit = await habit.getHabitData(0);

      expect(createdHabit.name).to.equal(exampleHabitData.name);
      expect(createdHabit.description).to.equal(exampleHabitData.description);
      expect(createdHabit.commitment.timeframe.toNumber()).to.equal(exampleHabitData.timeframe);
      expect(createdHabit.commitment.timesPerTimeframe.toNumber()).to.equal(exampleHabitData.timesPerTimeframe);
      expect(createdHabit.commitment.chainCommitment.toNumber()).to.equal(exampleHabitData.chainCommitment);
      expect(createdHabit.accomplishment.chain.toNumber()).to.equal(0);
      expect(createdHabit.accomplishment.periodStart.toNumber()).to.equal(now);
      expect(createdHabit.accomplishment.periodEnd.toNumber()).to.equal(now + exampleHabitData.timeframe);
      expect(createdHabit.accomplishment.periodTimesAccomplished.toNumber()).to.equal(0);
      expect(createdHabit.beneficiary).to.equal(exampleHabitData.beneficiary);
      expect(createdHabit.commitment.stakeAmount).to.equal(ethers.utils.parseEther("1"));
      expect(createdHabit.commitment.tokenStaked).to.equal(ethToken);
    });

    it("Should mint habit with commit", async () => {
      await network.provider.send("evm_setNextBlockTimestamp", [now])
      await erc20Mock.increaseAllowance(habitManager.address, ethers.utils.parseEther("10"));
      await habitManager.commit(...Object.values(exampleHabitData), erc20Mock.address, ethers.utils.parseEther("10"))
      const createdHabit = await habit.getHabitData(0);

      expect(createdHabit.name).to.equal(exampleHabitData.name);
      expect(createdHabit.description).to.equal(exampleHabitData.description);
      expect(createdHabit.commitment.timeframe.toNumber()).to.equal(exampleHabitData.timeframe);
      expect(createdHabit.commitment.timesPerTimeframe.toNumber()).to.equal(exampleHabitData.timesPerTimeframe);
      expect(createdHabit.commitment.chainCommitment.toNumber()).to.equal(exampleHabitData.chainCommitment);
      expect(createdHabit.accomplishment.chain.toNumber()).to.equal(0);
      expect(createdHabit.accomplishment.periodStart.toNumber()).to.equal(now);
      expect(createdHabit.accomplishment.periodEnd.toNumber()).to.equal(now + exampleHabitData.timeframe);
      expect(createdHabit.accomplishment.periodTimesAccomplished.toNumber()).to.equal(0);
      expect(createdHabit.beneficiary).to.equal(exampleHabitData.beneficiary);
      expect(createdHabit.commitment.stakeAmount).to.equal(ethers.utils.parseEther("10"));
      expect(createdHabit.commitment.tokenStaked).to.equal(erc20Mock.address);
    });
  });

  describe("Done method", () => {
    it("Should increse the chain when calling done and there are times to accomplish in the period",
      async () => {
        await network.provider.send("evm_setNextBlockTimestamp", [now])
        await habitManager.commitETH(...Object.values(exampleHabitData), { value: ethers.utils.parseEther("1") })
        await network.provider.send("evm_setNextBlockTimestamp", [now + hour])
        await habitManager.done(0, "proof1");

        console.log(await habit.tokenURI(0))

        const createdHabit = await habit.getHabitData(0);
        expect(createdHabit.accomplishment.periodTimesAccomplished.toNumber()).to.equal(1);
        expect(createdHabit.accomplishment.chain.toNumber()).to.equal(1);
        expect(createdHabit.accomplishment.periodEnd.toNumber()).to.equal(exampleHabitData.startTime + exampleHabitData.timeframe)
        expect(createdHabit.accomplishment.proofs[0]).to.equal("proof1")
      })

    it("Should increse the chain, change the period start and end time and reset the period count when calling done and accomplishing all the period times",
      async () => {
        await network.provider.send("evm_setNextBlockTimestamp", [now])
        await habitManager.commitETH(...Object.values(exampleHabitData), { value: ethers.utils.parseEther("1") })
        await network.provider.send("evm_setNextBlockTimestamp", [now + hour])
        await habitManager.done(0, "proof1");
        await network.provider.send("evm_setNextBlockTimestamp", [now + hour * 2])
        await habitManager.done(0, "proof2");

        const createdHabit = await habit.getHabitData(0);
        expect(createdHabit.accomplishment.periodTimesAccomplished.toNumber()).to.equal(0);
        expect(createdHabit.accomplishment.chain.toNumber()).to.equal(2);
        expect(createdHabit.accomplishment.periodStart.toNumber()).to.equal(exampleHabitData.startTime + exampleHabitData.timeframe)
        expect(createdHabit.accomplishment.periodEnd.toNumber()).to.equal(exampleHabitData.startTime + (exampleHabitData.timeframe * 2))
      })

    it("Should revert when you call done as not owner", async () => {
      const [_, ad1] = await ethers.getSigners();
      await habitManager.commitETH(...Object.values(exampleHabitData), { value: ethers.utils.parseEther("1") })
      await expect(habitManager.connect(ad1).done(0, "proof1")).to.be.revertedWith("Only the owner can interact with the habit");
    })

    it("Should revert when you call done and period has not started", async () => {
      exampleHabitData.startTime = now + hour * 2;
      await network.provider.send("evm_setNextBlockTimestamp", [now])
      await habitManager.commitETH(...Object.values(exampleHabitData), { value: ethers.utils.parseEther("1") })
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour])
      await expect(habitManager.done(0, "proof1")).to.be.revertedWith("Habit period did not start yet.");
    })

    it("Should revert when you call done and habit has expired", async () => {
      await network.provider.send("evm_setNextBlockTimestamp", [now])
      await habitManager.commitETH(...Object.values(exampleHabitData), { value: ethers.utils.parseEther("1") })
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour * 24 * 30])
      await expect(habitManager.done(0, "proof1")).to.be.revertedWith("HabitNotInValidState(0, true)");
    })
  })

  describe("ClaimStake", async () => {
    it("Should return stake and mark it as claimed when calling claimStake and habit done with ETH", async () => {
      const [owner] = await ethers.getSigners();
      const stakeAmount = ethers.utils.parseEther("1");
      await network.provider.send("evm_setNextBlockTimestamp", [now])
      await habitManager.commitETH(...Object.values(exampleHabitData), { value: stakeAmount })
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour])
      await habitManager.done(0, "proof1");
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour * 2])
      await habitManager.done(0, "proof1");
      const balanceBeforeClaim = await ethers.provider.getBalance(owner.address);
      const tx = await (await habitManager.claimStake(0)).wait();
      const gasSpent = tx.effectiveGasPrice.mul(tx.cumulativeGasUsed);
      const balanceAfterClaim = await ethers.provider.getBalance(owner.address);
      expect(balanceAfterClaim.add(gasSpent).sub(stakeAmount)).to.equal(balanceBeforeClaim);
      const createdHabit = await habit.getHabitData(0);
      expect(createdHabit.stakeClaimed).to.be.true;
    })

    it("Should return stake and mark it as claimed when calling claimStake and habit done with ERC20", async () => {
      const [owner] = await ethers.getSigners();
      const stakeAmount = ethers.utils.parseEther("10");
      await network.provider.send("evm_setNextBlockTimestamp", [now])
      await erc20Mock.increaseAllowance(habitManager.address, ethers.utils.parseEther("10"));
      await habitManager.commit(...Object.values(exampleHabitData), erc20Mock.address, ethers.utils.parseEther("10"))
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour])
      await habitManager.done(0, "proof1");
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour * 2])
      await habitManager.done(0, "proof1");
      const balanceBeforeClaim = await erc20Mock.balanceOf(owner.address);
      const ethBalanceBeforeClaim = await ethers.provider.getBalance(owner.address);
      const tx = await (await habitManager.claimStake(0)).wait();
      const gasSpent = tx.effectiveGasPrice.mul(tx.cumulativeGasUsed);
      const ethBalanceAfterClaim = await ethers.provider.getBalance(owner.address);
      const balanceAfterClaim = await erc20Mock.balanceOf(owner.address);
      expect(balanceAfterClaim.sub(stakeAmount)).to.equal(balanceBeforeClaim);
      expect(ethBalanceAfterClaim.add(gasSpent)).to.equal(ethBalanceBeforeClaim);
      const createdHabit = await habit.getHabitData(0);
      expect(createdHabit.stakeClaimed).to.be.true;
    })

    it("Should revert when not habit owner", async () => {
      const [owner, ad1] = await ethers.getSigners();
      const stakeAmount = ethers.utils.parseEther("1");
      await network.provider.send("evm_setNextBlockTimestamp", [now])
      await habitManager.commitETH(...Object.values(exampleHabitData), { value: stakeAmount })
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour])
      await habitManager.done(0, "proof1");
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour * 2])
      await habitManager.done(0, "proof1");
      await expect(habitManager.connect(ad1).claimStake(0)).to.be.revertedWith("Only the owner can interact with the habit");
    })

    it("Should revert when chain commitment not done yet", async () => {
      const stakeAmount = ethers.utils.parseEther("1");
      await network.provider.send("evm_setNextBlockTimestamp", [now])
      await habitManager.commitETH(...Object.values(exampleHabitData), { value: stakeAmount })
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour])
      await habitManager.done(0, "proof1");
      await expect(habitManager.claimStake(0)).to.be.revertedWith("ChainCommitmentAccomplished(0, false)");
    })

    it("Should revert when stake already claimed", async () => {
      const stakeAmount = ethers.utils.parseEther("1");
      await network.provider.send("evm_setNextBlockTimestamp", [now])
      await habitManager.commitETH(...Object.values(exampleHabitData), { value: stakeAmount })
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour])
      await habitManager.done(0, "proof1");
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour * 2])
      await habitManager.done(0, "proof1");
      await habitManager.claimStake(0);
      await expect(habitManager.claimStake(0)).to.be.revertedWith("Stake already claimed.");
    })
  })

  it("Should send stake to beneficiary if the commitment is broken and someone calls claimBrokenCommitment",
    async () => {
      const [owner, ad1] = await ethers.getSigners();
      const stakeAmount = ethers.utils.parseEther("1");
      await network.provider.send("evm_setNextBlockTimestamp", [now])
      await habitManager.commitETH(...Object.values(exampleHabitData), { value: stakeAmount })
      await network.provider.send("evm_setNextBlockTimestamp", [now + hour])
      await habitManager.done(0, "proof1");
      await network.provider.send("evm_setNextBlockTimestamp", [now + exampleHabitData.timeframe * 2])
      const balanceBeforeClaim = await ethers.provider.getBalance(ad1.address);
      await habitManager.claimBrokenCommitment(0);
      const balanceAfterClaim = await ethers.provider.getBalance(ad1.address);
      expect(balanceAfterClaim.sub(stakeAmount)).to.equal(balanceBeforeClaim);
      const createdHabit = await habit.getHabitData(0);
      expect(createdHabit.stakeClaimed).to.be.true;
    })

});
