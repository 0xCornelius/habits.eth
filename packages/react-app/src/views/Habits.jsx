import { Button, Card, Checkbox, DatePicker, Divider, Form, Input, InputNumber, Progress, Select, Slider, Spin, Switch } from "antd";
import React, { useState } from "react";
import { utils } from "ethers";
import { SyncOutlined } from "@ant-design/icons";
import { ethers } from "ethers";

import { Address, Balance, Events } from "../components";
import { useContractReader } from "eth-hooks";
import HabitVisualizer from "./HabitVisualizer/HabitVisualizer";
import { LoadingOutlined } from '@ant-design/icons';
import { Link, Redirect } from "react-router-dom";

export default function Habits({
    address,
    mainnetProvider,
    localProvider,
    yourLocalBalance,
    price,
    tx,
    readContracts,
    writeContracts,
    userHabits,
    allHabits
}) {

    const onDoneClicked = async (habitId) => {
        const result = tx(writeContracts.HabitManager.done(habitId, "proof"), update => { });
    }

    const antIcon = <LoadingOutlined style={{ fontSize: 60 }} spin />;

    return (
        <div style={{ marginBottom: "80px" }}>
            {allHabits ?
                userHabits && userHabits.length > 0 ?

                    <div style={{ width: 800, margin: "auto", marginTop: "20px", }}>
                        {userHabits.map((h) =>
                            <div style={{ marginBottom: "30px" }}>
                                <HabitVisualizer {...h} onDoneClicked={onDoneClicked} />
                            </div>
                        )}
                    </div>
                    :
                    <div style={{ padding: 20 }}>
                        <h2>You haven't created any habit yet. </h2>
                        <h2><Link to="/create">Click here to create your first habit.</Link></h2>
                    </div>
                :
                <Spin style={{ padding: 20 }} indicator={antIcon} />
            }


        </div>
    );
}
