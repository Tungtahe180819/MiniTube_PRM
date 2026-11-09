import {open} from 'node:fs/promises';
export async function validateMp4(path) {
 const handle=await open(path,'r');
 try {const header=Buffer.alloc(12);const {bytesRead}=await handle.read(header,0,12,0);return bytesRead===12 && header.toString('ascii',4,8)==='ftyp' && header.readUInt32BE(0)>=12;} finally {await handle.close();}
}
