const web3 = require('web3');

const type = parseInt(9).toString(16).padStart(2, '0');

const pairs = [
    [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35],
    [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36]
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
