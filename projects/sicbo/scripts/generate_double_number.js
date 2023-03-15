const web3 = require('web3');

const type = parseInt(5).toString(16).padStart(2, '0');

for (let i = 1; i <= 6; i++) {
    console.log(web3.utils.hexToNumberString('0x' + type + parseInt(i).toString(16).padStart(2, '0') + parseInt(0).toString(16).padStart(60, '0')));
}