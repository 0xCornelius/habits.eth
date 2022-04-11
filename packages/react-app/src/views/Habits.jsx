import { Button, Card, Checkbox, DatePicker, Divider, Form, Input, InputNumber, Progress, Select, Slider, Spin, Switch } from "antd";
import React, { useState } from "react";
import { utils } from "ethers";
import { SyncOutlined } from "@ant-design/icons";
import { ethers } from "ethers";

import { Address, Balance, Events } from "../components";
import { useContractReader } from "eth-hooks";
import HabitVisualizer from "./HabitVisualizer/HabitVisualizer";

const cleanHabit = (contractHabit) => {
    const cAccomplishment = contractHabit.accomplishment;
    const cCommitment = contractHabit.commitment;
    return {
        id: contractHabit.id.toNumber(),
        name: contractHabit.name,
        description: contractHabit.description,
        beneficiary: contractHabit.beneficiary,
        stakeClaimed: contractHabit.stakeClaimed,
        stake: ethers.utils.formatEther(contractHabit.stake),
        accomplishment: {
            chain: cAccomplishment.chain.toNumber(),
            periodEnd: cAccomplishment.periodEnd.toNumber(),
            periodStart: cAccomplishment.periodStart.toNumber(),
            periodTimesAccomplished: cAccomplishment.periodTimesAccomplished.toNumber(),
            proofs: cAccomplishment.proofs,
        },
        commitment: {
            chainCommitment: cCommitment.chainCommitment.toNumber(),
            timeframe: cCommitment.timeframe.toNumber(),
            timesPerTimeframe: cCommitment.timesPerTimeframe.toNumber(),
        },
    }
}

export default function Habits({
    address,
    mainnetProvider,
    localProvider,
    yourLocalBalance,
    price,
    tx,
    readContracts,
    writeContracts,
}) {
    const allHabits = useContractReader(readContracts, "Habit", "getAllHabits") || [];
    const userHabits = allHabits.filter((h) => h.owner == address).map(h => cleanHabit(h.habitData));

    const onDoneClicked = async (habitId) => {
        const result = tx(writeContracts.HabitManager.done(habitId, "proof"), update => { });
    }

    return (
        <div style={{ marginBottom: "80px" }}>
            <div style={{ width: 1200, margin: "auto", marginTop: "20px", }}>
                {userHabits.map((h) =>
                    <div style={{marginBottom: "30px"}}>
                        <HabitVisualizer {...h} onDoneClicked={onDoneClicked} />
                    </div>
                )}
            </div>
        </div>
    );
}
