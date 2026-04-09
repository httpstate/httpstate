// npm install @httpstate/typescript

import httpstate from '@httpstate/typescript';

httpstate('58bff2fcbeb846958f36e7ae5b8a75b0')
  .on('change', data => console.log(new Date().toISOString(), 'data', data));
