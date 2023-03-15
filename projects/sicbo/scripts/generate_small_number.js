const web3 = require('web3');

const type = parseInt(2).toString(16).padStart(2, '0');

console.log(web3.utils.hexToNumberString('0x' + type + parseInt(0).toString(16).padStart(62, '0')));