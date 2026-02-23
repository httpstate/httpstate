// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

export const get:(uuid:string) => Promise<undefined|string> = async (uuid:string):Promise<undefined|string> => {
  const response:Response = await fetch('https://httpstate.com/' + uuid);

  if(response.status === 200)
    return await response.text();
};

export const load:() => Promise<void> = async ():Promise<void> => {
  for(const node of document.querySelectorAll('[httpstate]')) {
    const uuid:null|string = node.getAttribute('httpstate');

    (globalThis as any).httpstate(uuid)
      .on('change', (e:Event&{ data:string }) => node.innerHTML = e.data);
  }
};

export const read:(uuid:string) => Promise<undefined|string> = async (uuid:string):Promise<undefined|string> => get(uuid);

export const set:(uuid:string, data:string) => Promise<number> = async (uuid:string, data:string):Promise<number> => {
  const response:Response = await fetch('https://httpstate.com/' + uuid, {
    body:data,
    headers:{ 'Content-Type':'text/plain;charset=UTF-8' },
    method:'POST'
  });

  return response.status;
};

export const write:(uuid:string, data:string) => Promise<number> = async (uuid:string, data:string):Promise<number> => set(uuid, data);

// HTTP State
export type HttpState = {
  data?:undefined|string;
  et?:undefined|{ [type:string]:((data?:undefined|string) => void)[] };
  uuid?:undefined|string;
  ws?:undefined|WebSocket;

  addEventListener(type:string, callback:(data?:undefined|string) => void):void;
  destroy():void;
  emit(type:string, data?:undefined|string):HttpState;
  get():Promise<undefined|string>;
  off(type:string, callback:(data?:undefined|string) => void):HttpState;
  on(type:string, callback:(data?:undefined|string) => void):HttpState;
  read():Promise<undefined|string>;
  removeEventListener(type:string, callback:(data?:undefined|string) => void):void;
  set(data:string):Promise<undefined|number>;
  write(data:string):Promise<undefined|number>;
};

const httpstate:(uuid:string) => HttpState = (uuid:string):HttpState => {
  const _:HttpState = {
    data:undefined,
    et:{},
    uuid,
    ws:new WebSocket('wss://httpstate.com/' + uuid),

    addEventListener:(type:string, callback:(data?:undefined|string) => void) => _.on(type, callback),
    destroy:() => {
      clearInterval((_.ws as any).interval);
      _.ws?.close(1000);

      delete _.data;
      delete _.et;
      delete _.uuid;
      delete _.ws;
    },
    emit:(type:string, data?:undefined|string) => {
      if(_.et?.[type])
        for(const callback of _.et[type])
          if(data === undefined)
            callback.call(_);
          else
            callback.call(_, data);

      return _;
    },
    get:async ():Promise<undefined|string> => {
      if(_.uuid) {
        const data = await get(_.uuid);

        if(data !== _.data)
          setTimeout(() => _.emit('change', _.data), 0);
        
        _.data = data;

        return _.data;
      }
    },
    off:(type:string, callback:(data?:undefined|string) => void) => {
      if(_.et?.[type]) {
        _.et[type] = _.et[type].filter(_callback => _callback !== callback);

        if(!_.et[type].length)
          delete _.et[type];
      }

      return _;
    },
    on:(type:string, callback:(data?:undefined|string) => void) => {
      if(_.et) {
        if(!_.et[type])
          _.et[type] = [];

        _.et[type].push(callback);
      }

      return _;
    },
    read:async ():Promise<undefined|string> => _.get(),
    removeEventListener:(type:string, callback:(data?:undefined|string) => void) => _.off(type, callback),
    set:async (data:string):Promise<undefined|number> => {
      if(_.uuid)
        return set(_.uuid, data);
    },
    write:async (data:string):Promise<undefined|number> => _.set(data)
  };

  _.ws?.addEventListener('close', e => console.log('close', e));
  _.ws?.addEventListener('error', e => console.log('error', e));
  _.ws?.addEventListener('message', async e => {
    const data = await e.data.text();

    if(
         data
      && data.length > 32
      && data.substring(0, 32) === _.uuid
      && data.substring(45, 46) === '1'
    ) {
      _.data = data.substring(46);

      _.emit('change', _.data);
    }
  });
  _.ws?.addEventListener('open', () => {
    _.ws?.send(JSON.stringify({ open:_.uuid }));

    _.emit('open');
  });

  (_.ws as any).interval = setInterval(() => {
    if(_.ws?.readyState === WebSocket.OPEN)
      _.ws?.send('0');
    else
      clearInterval((_.ws as any).interval);
  }, 1000*30); // 30 SECONDS

  setTimeout(_.get, 0);

  return _;
};

export default httpstate;

if(
     typeof document !== 'undefined'
  && typeof window !== 'undefined'
  && globalThis === window
)
  globalThis.addEventListener('load', async () => {
    if((globalThis as any).httpstate)
      (globalThis as any).httpstate = Object.assign(
        (globalThis as any).httpstate.default,
        (globalThis as any).httpstate
      );

    await load();
  }, { once:true });
