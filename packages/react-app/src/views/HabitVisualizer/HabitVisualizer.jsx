import { Button, Card, Checkbox, DatePicker, Divider, Form, Input, InputNumber, Progress, Select, Slider, Spin, Switch } from "antd";
import Countdown from 'react-countdown';
import ReactTooltip from "react-tooltip";

export default function HabitVisualizer({
    id,
    name,
    description,
    beneficiary,
    stakeClaimed,
    stake,
    accomplishment,
    commitment,
    onDoneClicked
}) {
    const {
        chain,
        periodEnd,
        periodStart,
        periodTimesAccomplished,
        proofs
    } = accomplishment;

    const {
        chainCommitment,
        timeframe,
        timesPerTimeframe,
    } = commitment;

    const habitPeriodTimesLeft = timesPerTimeframe - periodTimesAccomplished;

    const periodStartDate = new Date(periodStart * 1000);
    const periodEndDate = new Date(periodEnd * 1000);

    const periodTimeLeft = (<div className="time-left">
        <Countdown className={"period-time-left"} date={periodEndDate}>
        </Countdown>
        <div>
            Times left: {habitPeriodTimesLeft}
        </div>
    </div>)

    const periodStartTimeLeft = (<div className="time-to-wait">
        You need to wait {" "}
        <Countdown date={periodStartDate}>
        </Countdown>
        {" "} for your next period to start to continue your habit.
        <div style={{ marginTop: "5px" }}>
            Take this time to rest!
        </div>
    </div>)

    const periodNotStarted = new Date() < periodStartDate;


    return (
        <div className="habit-visualizer-container">
            <div className="header">{name}</div>
            <div className="body">
                <div className="habit-data-and-actions">
                    <div className="left">
                        <div>
                            {description}
                        </div>
                        <div className="row">
                            Beneficiary: {beneficiary}
                        </div>
                        <div className="row">
                            Stake: {stake} ETH
                        </div>
                        <div className="progress-visualizer">
                            {[...Array(chainCommitment)].map((e, i) =>
                                <span className={`dot ${(i < chain) ? "done" : ""}`} key={i} />)
                            }
                        </div>
                    </div>
                    <div className="right">
                        <div className="right-content">
                            <Button data-tip data-for={`habit-${id}`} type="primary" disabled={periodNotStarted} className="done-button" onClick={() => onDoneClicked(id)}>
                                Done
                            </Button>
                            {(periodNotStarted) ? <ReactTooltip id={`habit-${id}`} place="top" type="info" effect="solid" > {periodStartTimeLeft}</ReactTooltip> : periodTimeLeft}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}