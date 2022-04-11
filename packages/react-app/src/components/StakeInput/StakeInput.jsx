import React from "react";
import NumberFormat from 'react-number-format';

export default function StakeInput({ createNewHabitForm }) {

    const updateFormValue = (newValue) => {
        console.log(newValue.value)
        createNewHabitForm.setFieldsValue({
            stake: newValue.value
        })
    }

    return (
        <div>
            <NumberFormat onValueChange={(val) => { updateFormValue(val) }} className="stake-input" suffix={" ETH"} placeholder="0.00 ETH" allowNegative={false} />
        </div>
    )
}