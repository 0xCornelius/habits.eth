import { Button, Card, Checkbox, DatePicker, Divider, Form, Input, InputNumber, Progress, Select, Slider, Spin, Switch } from "antd";
import { ethers } from "ethers";
import React, { useState } from "react";
import moment from 'moment';
import { useHistory } from "react-router-dom";

export default function CreateHabit({ tx, writeContracts }) {

    const { Option } = Select;

    const [createNewHabitForm] = Form.useForm();

    const history = useHistory();

    const day = 24 * 60 * 60;
    const week = 7 * day;
    const month = 30 * day;
    const year = 365 * day;
    const formDefaults = {
        timeframe: week, timesPerTimeframe: 1, chainCommitmentInTimeframes: 15, startDate: moment(new Date().setUTCHours(0, 0, 0, 0))
    }

    const [timeframe, setTimeframe] = useState(formDefaults.timeframe);
    const [timesPerTimeframe, setTimesPerTimeframe] = useState(formDefaults.timesPerTimeframe);
    const [chainCommitmentInTimeframes, setChainCommitmentInTimeframes] = useState(formDefaults.chainCommitmentInTimeframes);

    const timeframeToName = {
        [day]: "day",
        [week]: "week",
        [month]: "month",
        [year]: "year",
    }

    const getHabitCreationData = () => {
        const formValues = createNewHabitForm.getFieldsValue();
        return {
            habitName: formValues.habitName,
            description: formValues.habitDescription,
            timeframe: formValues.timeframe,
            chainCommitment: formValues.chainCommitmentInTimeframes * formValues.timesPerTimeframe,
            beneficiary: formValues.beneficiary,
            startTime: (formValues.startDate.valueOf()) / 1000,
            timesPerTimeframe: formValues.timesPerTimeframe
        }
    }

    const createNewHabit = async () => {
        const stake = createNewHabitForm.getFieldsValue().stake;
        const txValue = ethers.utils.parseEther(stake);
        const result = tx(writeContracts.HabitManager.commit(...Object.values(getHabitCreationData()), { value: txValue }), update => {
            if (update && (update.status === "confirmed" || update.status === 1)) {
                history.push("/");
            }
        });
    }


    return (
        <div style={{ border: "1px solid #cccccc", width: 1200, margin: "auto", marginTop: 64, borderRadius: "6px" }}>
            <div className="header">Create new habit</div>
            <Form
                form={createNewHabitForm}
                name="basic"
                labelCol={{ span: 8 }}
                wrapperCol={{ span: 24 }}
                initialValues={formDefaults}
                onFinish={createNewHabit}
                autoComplete="off"
                layout="vertical"
                style={{ textAlign: "left", padding: "20px" }}
            >
                <Form.Item
                    label="Habit Name"
                    name="habitName"
                    rules={[{ required: true, message: 'Input your habit name' }]}>
                    <Input />
                </Form.Item>

                <Form.Item
                    label="Description"
                    name="habitDescription"
                    rules={[{ required: true, message: 'Input your habit description' }]}>
                    <Input />
                </Form.Item>

                <Form.Item
                    label="Beneficiary"
                    name="beneficiary"
                    rules={[{ required: true, message: 'Input a valid address as beneficiary' }]}>
                    <Input />
                </Form.Item>

                <Form.Item
                    label="Stake"
                    name="stake"
                    rules={[{ required: true, message: 'Input how much you want to stake' }]}>
                    <Input />
                </Form.Item>

                <div style={{ display: "flex", alignItems: "center" }}>
                    <span style={{ marginRight: "10px" }}>
                        I will repeat my habit
                    </span>
                    <Form.Item
                        style={{ marginBottom: 0 }}
                        name="timesPerTimeframe">
                        <InputNumber size="small" min={1} onChange={setTimesPerTimeframe} />
                    </Form.Item>
                    <span style={{ marginRight: "10px", marginLeft: "10px" }}>
                        times per
                    </span>
                    <Form.Item
                        style={{ marginBottom: 0 }}
                        name="timeframe">
                        <Select size="small" style={{ width: "120px" }} onChange={setTimeframe}>
                            <Option value={day}>Day</Option>
                            <Option value={week}>Week</Option>
                            <Option value={month}>Month</Option>
                            <Option value={year}>Year</Option>
                        </Select>
                    </Form.Item>
                    <span style={{ marginRight: "10px", marginLeft: "10px" }}>
                        for
                    </span>
                    <Form.Item
                        style={{ marginBottom: 0 }}
                        name="chainCommitmentInTimeframes">
                        <InputNumber default={100} size="small" min={1} onChange={setChainCommitmentInTimeframes} />
                    </Form.Item>
                    <span style={{ marginLeft: "10px" }}>
                        {timeframeToName[timeframe]}s
                    </span>
                </div>
                <div style={{ fontSize: "12px", color: "gray" }}>
                    This means that you will have to repeat your habit {timesPerTimeframe * chainCommitmentInTimeframes} times to recover your money.
                </div>

                <Form.Item label="Habit start date" name="startDate"
                    rules={[{ required: true }]}>
                    <DatePicker style={{ marginRight: "auto", marginLeft: 0 }}
                        defaultValue={formDefaults.startDate} />
                </Form.Item>

                <Form.Item>
                    <Button type="primary" htmlType="submit">
                        Submit
                    </Button>
                </Form.Item>
            </Form>
        </div>
    )
}