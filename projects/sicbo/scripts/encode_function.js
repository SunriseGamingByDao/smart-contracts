const Web3 = require('Web3');

const web3 = new Web3();

const data = web3.eth.abi.encodeFunctionCall({
    name: 'initialize',
    type: 'function',
    inputs: [
        {
            type: 'address',
            name: 'betNumber'
        },
        {
            type: 'address',
            name: 'token'
        }
    ]
}, ['0x830b810cC9b430e2Fa7B25d46F4cF86D45101D4D', '0xc3f1c6A8428D1D9497944f35F68e284Ee75Da629']);

console.log('\n', data);
