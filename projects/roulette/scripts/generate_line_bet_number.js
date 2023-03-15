const web3 = require('web3');

const type = parseInt(5).toString(16).padStart(2, '0');

const pairs = [
    [1, 2, 3, 4, 5, 6],
    [4, 5, 6, 7, 8, 9],
    [7, 8, 9, 10, 11, 12],
    [10, 11, 12, 13, 14, 15],
    [13, 14, 15, 16, 17, 18],
    [16, 17, 18, 19, 20, 21],
    [19, 20, 21, 22, 23, 24],
    [22, 23, 24, 25, 26, 27],
    [25, 26, 27, 28, 29, 30],
    [28, 29, 30, 31, 32, 33],
    [31, 32, 33, 34, 35, 36]
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
