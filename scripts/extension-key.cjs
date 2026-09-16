const {generateKeyPairSync,createHash}=require('node:crypto');
const fs=require('node:fs');
const file='extension/manifest.json',m=JSON.parse(fs.readFileSync(file));
if(!m.key) m.key=generateKeyPairSync('rsa',{modulusLength:2048}).publicKey.export({format:'der',type:'spki'}).toString('base64');
fs.writeFileSync(file,JSON.stringify(m,null,2)+'\n');
console.log(createHash('sha256').update(Buffer.from(m.key,'base64')).digest('hex').slice(0,32).replace(/[0-9a-f]/g,c=>String.fromCharCode(97+parseInt(c,16))));
