const solc=require('solc'),fs=require('fs');
const src=fs.readFileSync('contracts/CommunityLots.sol','utf8');
const o=JSON.parse(solc.compile(JSON.stringify({language:'Solidity',sources:{'C.sol':{content:src}},settings:{optimizer:{enabled:true,runs:200},outputSelection:{'*':{'*':['abi']}}}})));
(o.errors||[]).forEach(e=>console.log(e.severity,e.formattedMessage));
console.log(o.errors&&o.errors.some(e=>e.severity==='error')?'FAIL':'OK');
