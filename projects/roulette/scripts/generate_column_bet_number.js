const web3 = require('web3');

const type = parseInt(6).toString(16).padStart(2, '0');

const pairs = [
    [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31, 34],
    [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35],
    [3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36]
];

for (let i = 0; i < pairs.length; i++) {
    const pair = pairs[i];

    let number = 0;

    for (let j = 0; j < pair.length; j++) {
        number += Math.pow(2, pair[j]);
    }

    number = number.toString(16).padStart(62, '0');

    console.log(web3.utils.hexToNumberString('0x' + type + number));
}
