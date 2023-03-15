const web3 = require('web3');

const type = parseInt(13).toString(16).padStart(2, '0');

for (let i = 1; i <= 5; i++) {
    for (let j = i + 1; j <= 6; j++) {
        console.log(web3.utils.hexToNumberString('0x' + type + parseInt(i).toString(16).padStart(2, '0') + parseInt(j).toString(16).padStart(2, '0') + parseInt(0).toString(16).padStart(58, '0')));
    }
}