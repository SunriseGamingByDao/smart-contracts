const web3 = require('web3');

const type = parseInt(1).toString(16).padStart(2, '0');

for (let i = 0; i <= 36; i++) {
    const number = Math.pow(2, i).toString(16).padStart(62, '0');

    console.log(web3.utils.hexToNumberString('0x' + type + number));
}
