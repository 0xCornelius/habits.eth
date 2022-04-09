// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

import "./NFTSVG.sol";
import "base64-sol/base64.sol";

error InvalidTimeframe();

library HabitNFT {
    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
    }

    struct HabitNFTData {
        string name;
        string description;
        uint256 id;
        uint256 chain;
        uint256 chainCommitment;
        string timeframeString;
        uint256 timesPerTimeframe;
        uint256 stake;
        address beneficiary;
    }

    function timeframeToDescription(uint256 _habitTimeframe)
        public
        pure
        returns (string memory)
    {
        if (_habitTimeframe == 1 days) return "Daily";
        if (_habitTimeframe == 1 weeks) return "Weekly";
        if (_habitTimeframe == 30 days) return "Monthly";
        if (_habitTimeframe == 365 days) return "Yearly";
        revert InvalidTimeframe();
    }

    function generateTokenURI(HabitNFTData memory habitNFTData)
        public
        pure
        returns (string memory)
    {
        string memory svg = _generateSVGImage(
            habitNFTData.id,
            habitNFTData.chain,
            habitNFTData.chainCommitment,
            habitNFTData.timeframeString,
            habitNFTData.timesPerTimeframe,
            habitNFTData.stake,
            habitNFTData.beneficiary,
            habitNFTData.name
        );

        string memory _image = Base64.encode(bytes(svg));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Habit: ',
                                habitNFTData.name,
                                '", "description":"',
                                habitNFTData.description,
                                '", "image": "data:image/svg+xml;base64,',
                                _image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _generateSVGImage(
        uint256 _id,
        uint256 _chain,
        uint256 _chainCommitment,
        string memory _timeframeString,
        uint256 _timesPerTimeframe,
        uint256 _stake,
        address _beneficiary,
        string memory _name
    ) private pure returns (string memory svg) {
        NFTSVG.HabitSVGParams memory _svgParams = NFTSVG.HabitSVGParams({
            habitId: _id,
            chain: _chain,
            chainCommitment: _chainCommitment,
            timeframeString: _timeframeString,
            timesPerTimeframe: _timesPerTimeframe,
            stake: string(
                abi.encodePacked(
                    fixedPointToDecimalString(_stake, 2),
                    " ",
                    "ETH"
                )
            ),
            beneficiary: addressToString(_beneficiary),
            name: _name
        });

        return NFTSVG.generateSVG(_svgParams);
    }

    function fixedPointToDecimalString(uint256 value, uint8 decimals)
        public
        pure
        returns (string memory)
    {
        if (value == 0) {
            return "0.0000";
        }

        bool priceBelow1 = value < 10**decimals;

        // get digit count
        uint256 temp = value;
        uint8 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        // don't count extra digit kept for rounding
        digits = digits - 1;

        // address rounding
        (uint256 sigfigs, bool extraDigit) = _sigfigsRounded(value, digits);
        if (extraDigit) {
            digits++;
        }

        DecimalStringParams memory params;
        if (priceBelow1) {
            // 7 bytes ( "0." and 5 sigfigs) + leading 0's bytes
            params.bufferLength = digits >= 5
                ? decimals - digits + 6
                : decimals + 2;
            params.zerosStartIndex = 2;
            params.zerosEndIndex = decimals - digits + 1;
            params.sigfigIndex = params.bufferLength - 1;
        } else if (digits >= decimals + 4) {
            // no decimal in price string
            params.bufferLength = digits - decimals + 1;
            params.zerosStartIndex = 5;
            params.zerosEndIndex = params.bufferLength - 1;
            params.sigfigIndex = 4;
        } else {
            // 5 sigfigs surround decimal
            params.bufferLength = 6;
            params.sigfigIndex = 5;
            params.decimalIndex = digits - decimals + 1;
        }
        params.sigfigs = sigfigs;
        params.isLessThanOne = priceBelow1;

        return _generateDecimalString(params);
    }

    function _char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function addressToString(address _addr)
        public
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(
                uint8(uint256(uint160(_addr)) / (2**(8 * (19 - i))))
            );
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(abi.encodePacked("0x", string(s)));
    }

    function _generateDecimalString(DecimalStringParams memory params)
        private
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isLessThanOne) {
            buffer[0] = "0";
            buffer[1] = ".";
        }

        // add leading/trailing 0's
        for (
            uint256 zerosCursor = params.zerosStartIndex;
            zerosCursor < params.zerosEndIndex + 1;
            zerosCursor++
        ) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (
                params.decimalIndex > 0 &&
                params.sigfigIndex == params.decimalIndex
            ) {
                buffer[params.sigfigIndex--] = ".";
            }
            uint8 charIndex = uint8(48 + (params.sigfigs % 10));
            buffer[params.sigfigIndex] = bytes1(charIndex);
            params.sigfigs /= 10;
            if (params.sigfigs > 0) {
                params.sigfigIndex--;
            }
        }
        return string(buffer);
    }

    function _sigfigsRounded(uint256 value, uint8 digits)
        private
        pure
        returns (uint256, bool)
    {
        bool extraDigit;
        if (digits > 5) {
            value = value / (10**(digits - 5));
        }
        bool roundUp = value % 10 > 4;
        value = value / 10;
        if (roundUp) {
            value = value + 1;
        }
        // 99999 -> 100000 gives an extra sigfig
        if (value == 100000) {
            value /= 10;
            extraDigit = true;
        }
        return (value, extraDigit);
    }
}
