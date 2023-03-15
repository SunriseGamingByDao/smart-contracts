const web3 = require('web3');

const type = parseInt(12).toString(16).padStart(2, '0');

console.log(web3.utils.hexToNumberString('0x' + type + parseInt(10).toString(16).padStart(2, '0') + parseInt(0).toString(16).padStart(60, '0')));

console.log(web3.utils.hexToNumberString('0x' + type + parseInt(11).toString(16).padStart(2, '0') + parseInt(0).toString(16).padStart(60, '0')));