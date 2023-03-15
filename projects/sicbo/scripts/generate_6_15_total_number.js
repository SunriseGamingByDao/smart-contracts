const web3 = require('web3');

const type = parseInt(8).toString(16).padStart(2, '0');

console.log(web3.utils.hexToNumberString('0x' + type + parseInt(6).toString(16).padStart(2, '0') + parseInt(0).toString(16).padStart(60, '0')));

console.log(web3.utils.hexToNumberString('0x' + type + parseInt(15).toString(16).padStart(2, '0') + parseInt(0).toString(16).padStart(60, '0')));