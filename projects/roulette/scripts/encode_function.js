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
}, ['0x4C433D4b0F9C7F1f7aC4A7025B582536ec07A506', '0x4A6Aa905EF85F055c3146cE70ac0BF3052e8be4d']);

console.log('\n', data);
