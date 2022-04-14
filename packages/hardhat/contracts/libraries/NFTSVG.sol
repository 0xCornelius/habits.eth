// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

import '@openzeppelin/contracts/utils/Strings.sol';

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a HABIT NFT. Based on Uniswap's NFTDescriptor
library NFTSVG {
    using Strings for uint256;
    using Strings for uint32;

    struct HabitSVGParams {
        uint256 habitId;
        uint256 chain;
        uint256 chainCommitment;
        string timeframeString;
        uint256 timesPerTimeframe;
        string stakeAmount;
        string stakeTokenSymbol;
        string stakeTokenAddress;
        string beneficiary;
        string name;
    }

    function generateSVG(HabitSVGParams memory params)
        public
        pure
        returns (string memory svg)
    {
        uint256 _percentage = (params.chainCommitment > 0)
            ? ((params.chain * 100) / params.chainCommitment)
            : 100;
        return
            string(
                abi.encodePacked(
                    '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 580.71 1118.71" >',
                    _generateStyleDefs(_percentage),
                    _generateSVGDefs(),
                    _generateSVGBackground(),
                    _generateSVGCardTitle(
                        params.name,
                        params.timesPerTimeframe,
                        params.timeframeString
                    ),
                    _generateSVGPositionData(
                        params.habitId,
                        params.stakeAmount,
                        params.beneficiary,
                        params.stakeTokenSymbol
                    ),
                    _generateSVGBorderText(
                        params.beneficiary,
                        params.stakeTokenAddress,
                        params.stakeTokenSymbol
                    ),
                    _generateSVGLines(_percentage),
                    _generageSVGProgressArea(
                        params.chain,
                        params.chainCommitment
                    ),
                    '</svg>'
                )
            );
    }

    function sqrt(uint256 x) private pure returns (uint256 y) {
        if (x == 0) return 0;
        else if (x <= 3) return 1;
        uint256 z = (x + 1) / 2;
        y = x;
        while (
            z < y /// @why3 invariant { to_int !_z = div ((div (to_int arg_x) (to_int !_y)) + (to_int !_y)) 2 }
        ) /// @why3 invariant { to_int arg_x < (to_int !_y + 1) * (to_int !_y + 1) }
        /// @why3 invariant { to_int arg_x < (to_int !_z + 1) * (to_int !_z + 1) }
        /// @why3 variant { to_int !_y }
        {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function _generateStyleDefs(uint256 _percentage)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<style type="text/css">.st0{fill:url(#SVGID_1)}.st1{fill:none;stroke:#fff;stroke-miterlimit:10}.st2{opacity:.5}.st3{fill:none;stroke:#b5baba;stroke-miterlimit:10}.st36{fill:#fff}.st37{fill:#48a7de}.st38{font-family:"Verdana"}.st39{font-size:60px}.st40{letter-spacing:-4}.st44{font-size:25px}.st46{fill:#c6c6c6}.st47{font-size:18px}.st48{font-size:19.7266px}.st49{font-family:"Verdana";font-weight:bold}.st50{font-size:38px}.st52{stroke:#848484;mix-blend-mode:multiply}.st55{opacity:.2;fill:#fff}.st57{fill:#48a7de;stroke:#fff;stroke-width:2.8347;stroke-miterlimit:10}.st58{font-size:21px}.cls-79{stroke:#d1dbe0;transform:rotate(-90deg);transform-origin:290.35px 488.04px;animation:dash 2s linear alternate forwards}@keyframes dash{from{stroke-dashoffset:750.84}to{stroke-dashoffset:',
                (((100 - _percentage) * 75084) / 10000).toString(),
                ';}}</style>'
            )
        );
    }

    function _generateSVGDefs() private pure returns (string memory svg) {
        svg = '<defs><path id="SVGID_0" class="st2" d="M580.71 1042.17c0 42.09-34.44 76.54-76.54 76.54H76.54c-42.09 0-76.54-34.44-76.54-76.54V76.54C0 34.44 34.44 0 76.54 0h427.64c42.09 0 76.54 34.44 76.54 76.54v965.63z"/><path id="text-path-a" d="M81.54 1095.995a57.405 57.405 0 0 1-57.405-57.405V81.54A57.405 57.405 0 0 1 81.54 24.135h417.64a57.405 57.405 0 0 1 57.405 57.405v955.64a57.405 57.405 0 0 1-57.405 57.405z"/><path id="text-path-executed" d="M290.35 348.77a139.5 139.5 0 1 1 0 279 139.5 139.5 0 1 1 0-279"/><path id="text-path-left" d="M290.35 348.77a-139.5-139.5 0 1 0 0 291 139.5 139.5 0 1 0 0-291"/><radialGradient id="SVGID_3" cx="334.831" cy="592.878" r="428.274" fx="535.494" fy="782.485" gradientUnits="userSpaceOnUse"><stop offset="0"/><stop offset=".11" stop-color="#0d1f29"/><stop offset=".28" stop-color="#1f4860"/><stop offset=".45" stop-color="#2e6a8d"/><stop offset=".61" stop-color="#3985b0"/><stop offset=".76" stop-color="#4198c9"/><stop offset=".89" stop-color="#46a3d9"/><stop offset="1" stop-color="#1890ff"/>&gt;</radialGradient><linearGradient id="SVGID_1" gradientUnits="userSpaceOnUse" x1="290.353" y1="0" x2="290.353" y2="1118.706"><stop offset="0" stop-color="#1890ff"/><stop offset=".105" stop-color="#186ebb"/><stop offset=".292" stop-color="#135997"/><stop offset=".47" stop-color="#0e416c"/><stop offset=".635" stop-color="#121612"/><stop offset=".783" stop-color="#060600"/><stop offset=".91" stop-color="#010100"/><stop offset="1"/></linearGradient><clipPath id="SVGID_2"><use xlink:href="#SVGID_0" overflow="visible"/></clipPath></defs>';
    }

    function _generateSVGBackground() private pure returns (string memory svg) {
        svg = '<path d="M580.71 1042.17c0 42.09-34.44 76.54-76.54 76.54H76.54c-42.09 0-76.54-34.44-76.54-76.54V76.54C0 34.44 34.44 0 76.54 0h427.64c42.09 0 76.54 34.44 76.54 76.54v965.63z" fill="url(#SVGID_1)"/><path d="M76.54 1081.86c-21.88 0-39.68-17.8-39.68-39.68V76.54c0-21.88 17.8-39.69 39.68-39.69h427.64c21.88 0 39.68 17.8 39.68 39.69v965.64c0 21.88-17.8 39.68-39.68 39.68H76.54z" fill="none" stroke="#fff" stroke-miterlimit="10"/>';
    }

    function _generateSVGBorderText(
        string memory _beneficiary,
        string memory _stakeTokenAddress,
        string memory _stakeTokenSymbol
    ) private pure returns (string memory svg) {
        string memory _beneficiaryText = string(
            abi.encodePacked('Beneficiary: ', _beneficiary)
        );
        string memory stakeInfoText = string(
            abi.encodePacked(
                'Token: ',
                _stakeTokenSymbol,
                ' - ',
                _stakeTokenAddress
            )
        );

        svg = string(
            abi.encodePacked(
                _generateTextWithPath('-100', _beneficiaryText),
                _generateTextWithPath('0', _beneficiaryText),
                _generateTextWithPath('50', stakeInfoText),
                _generateTextWithPath('-50', stakeInfoText)
            )
        );
    }

    function _generateTextWithPath(string memory offset, string memory text)
        private
        pure
        returns (string memory path)
    {
        path = string(
            abi.encodePacked(
                '<text text-rendering="optimizeSpeed"><textPath startOffset="',
                offset,
                '%" xlink:href="#text-path-a" class="st46 st38 st47">',
                text,
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" dur="60s" repeatCount="indefinite" /></textPath></text>'
            )
        );
    }

    function _generateSVGCardTitle(
        string memory _habitName,
        uint256 _timesPerTimeframe,
        string memory _timeframeString
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text><tspan x="68.3549" y="146.2414" class="st36 st38 st39 st40">',
                _habitName,
                '</tspan></tspan></text><text x="68.3549" y="225.9683" class="st36 st49 st50">',
                _timesPerTimeframe.toString(),
                ' times ',
                _timeframeString,
                '</text>'
            )
        );
    }

    function _generageSVGProgressArea(uint256 _chain, uint256 _chainCommitment)
        private
        pure
        returns (string memory svg)
    {
        svg = _getDots(200);
    }

    function _getDots(uint256 amount) private pure returns (string memory svg) {
        string memory svg;

        uint256 dotsPerLine = sqrt(amount);

        uint256 scale = ((100 * 100) / (10 * dotsPerLine));

        uint256 initialCX = 80;
        uint256 initialCY = 300;


        uint256 cxStep = (45 * scale) / 100;
        uint256 cyStep = (50 * scale) / 100;

        for (uint256 i; i < amount; ++i) {
            svg = string(
                abi.encodePacked(
                    svg,
                    dot(
                        Strings.toString(initialCX + cxStep * (i % dotsPerLine)),
                        Strings.toString(initialCY + cyStep * (i / dotsPerLine)),
                        scale
                    )
                )
            );
        }
        return svg;
    }

    function dot(
        string memory cx,
        string memory cy,
        uint256 scale
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<circle cx="',
                cx,
                '" cy="',
                cy,
                '" r="',
                Strings.toString((12 * scale) / 100),
                '" fill="url(#SVGID_3)"/>'
            )
        );
    }

    function _generateSVGPositionData(
        uint256 _habitId,
        string memory _stake,
        string memory _beneficiary,
        string memory _stakeTokenSymbol
    ) private pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<text transform="matrix(1 0 0 1 68.3549 775.8853)"><tspan x="0" y="104.73" class="st36 st38 st44">Id: ',
                _habitId.toString(),
                '</tspan><tspan x="0" y="157.1" class="st36 st38 st44">Stake: ',
                _stake,
                ' ',
                _stakeTokenSymbol,
                '</tspan><tspan x="0" y="209.46" class="st36 st38 st44">Beneficiary: ',
                _beneficiary,
                '</tspan></text><text><tspan x="68.3554" y="1050.5089" class="st36 st38 st48"></tspan></text>'
            )
        );
    }

    function _generateSVGLines(uint256 _percentage)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<path class="st1" d="M68.35 175.29h440.12M68.35 249.38h440.12M68.35 844.47h440.12M68.35 896.82h440.12M68.35 949.17h440.12M68.35 1001.53h440.12"/>'
            )
        );
    }

    function render() external pure returns (string memory svg) {
        return
            generateSVG(
                HabitSVGParams({
                    habitId: 1,
                    chain: 24,
                    chainCommitment: 200,
                    timeframeString: 'Weekly',
                    timesPerTimeframe: 4,
                    stakeAmount: '10.5',
                    stakeTokenSymbol: 'USDC',
                    stakeTokenAddress: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
                    beneficiary: '0xd8dA6....96045',
                    name: 'Habit name'
                })
            );
    }
}
