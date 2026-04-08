// npm install @httpstate/typescript

import httpstate from '@httpstate/typescript';

httpstate('45fb36540e9244daaa21ca409c6bdab3')
  .on('change', data => console.log(new Date().toISOString(), 'data', data));
