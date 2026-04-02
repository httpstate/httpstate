import httpstate from '@httpstate/typescript';

const uuid = '58bff2fcbeb846958f36e7ae5b8a75b0';

console.log(new Date().toISOString(), '@httpstate/typescript', uuid);

httpstate(uuid)
  .on('change', data => console.log(new Date().toISOString(), 'data', data));
