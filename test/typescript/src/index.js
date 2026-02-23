import * as httpstate from '@httpstate/typescript';

const uuid = '06ee9a21a70b49c3bcffc335995cf2b4';

console.log(new Date().toISOString(), '@httpstate/typescript', uuid);

{
  const data = String(Date.now());

  await httpstate.set(uuid, data);
  if(await httpstate.get(uuid) === data)
    console.log(new Date().toISOString(), '@httpstate/typescript', uuid, '(static)      get/set', '✅');
}

{
  const data = String(Date.now());

  await httpstate.write(uuid, data);
  if(await httpstate.read(uuid) === data)
    console.log(new Date().toISOString(), '@httpstate/typescript', uuid, '(static)   read/write', '✅');
}

await new Promise(async resolve => {
  const data = String(Date.now());

  await httpstate.set(uuid, data);

  httpstate.default('06ee9a21a70b49c3bcffc335995cf2b4')
    .on('change', function() {
      if(this.data === data) {
        console.log(new Date().toISOString(), '@httpstate/typescript', uuid, '(instance.load)  data', '✅');

        this.destroy();

        resolve();
      }
    });
});

{
  const _ = httpstate.default('06ee9a21a70b49c3bcffc335995cf2b4');
  const data = String(Date.now());

  await _.set(data);
  if(await _.get() === data)
    console.log(new Date().toISOString(), '@httpstate/typescript', uuid, '(instance)    get/set', '✅');
};

{
  const _ = httpstate.default('06ee9a21a70b49c3bcffc335995cf2b4');
  const data = String(Date.now());

  await _.write(data);
  if(await _.read() === data)
    console.log(new Date().toISOString(), '@httpstate/typescript', uuid, '(instance) read/write', '✅');
};

await new Promise(resolve => {
  const _ = httpstate.default('06ee9a21a70b49c3bcffc335995cf2b4');
  const data = String(Date.now());
  
  _
    .on('change', function() {
      if(this.data === data) {
        console.log(new Date().toISOString(), '@httpstate/typescript', uuid, '(instance)     change', '✅');

        resolve();
      }
    })
    .on('open', () => _.set(data));
});

process.exit(0);
