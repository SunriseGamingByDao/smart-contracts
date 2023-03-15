const web3 = require('web3');

const type = parseInt(4).toString(16).padStart(2, '0');

const pairs = [
    [0, 1, 2, 3],
    [1, 2, 4, 5],
    [2, 3, 5, 6],
    [4, 5, 7, 8],
    [5, 6, 8, 9],
    [7, 8, 10, 11],
    [8, 9, 11, 12],
    [10, 11, 13, 14],
    [11, 12, 14, 15],
    [13, 14, 16, 17],
    [14, 15, 17, 18],
    [16, 17, 19, 20],
    [17, 18, 20, 21],
    [19, 20, 22, 23],
    [20, 21, 23, 24],
    [22, 23, 25, 26],
    [23, 24, 26, 27],
    [25, 26, 28, 29],
    [26, 27, 29, 30],
    [28, 29, 31, 32],
    [29, 30, 32, 33],
    [31, 32, 34, 35],
    [32, 33, 35, 36],
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
