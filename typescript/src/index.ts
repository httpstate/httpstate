// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

const UUIDV4:{ short(s:string):undefined|string; } = { short:(s:string):undefined|string => {
  s = s.toLowerCase();

  if(s.length === 36)
    s = s.replace(/-/g, '');

  if(
       s.length === 32
    && /^[0-9a-f]{12}4[0-9a-f]{3}[89ab][0-9a-f]{15}$/.test(s)
  )
    return s;
} };

export const get:(uuid:string) => Promise<undefined|string> = async (uuid:string):Promise<undefined|string> => {
  const response:Response = await fetch('https://httpstate.com/' + uuid);

  if(response.status === 200)
    return await response.text();
};

export const load:() => Promise<void> = async ():Promise<void> => {
  for(const node of document.querySelectorAll('[httpstate]')) {
    const uuid:null|string = node.getAttribute('httpstate');

    if(!(load as any)._)
      (load as any)._ = {};

    if(
         uuid
      && !(load as any)._[uuid]
    )
      (load as any)._[uuid] = httpstate(uuid)
        .on('change', (data:undefined|string) => {
          console.log('on.change', data);

          node.innerHTML = String(data);
        });
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

  addEventListener(type:string, callback:(data?:undefined|string) => void):void;
  delete():void;
  emit(type:string, data?:undefined|string):HttpState;
  get():Promise<undefined|string>;
  off(type:string, callback?:(data?:undefined|string) => void):HttpState;
  on(type:string, callback:(data?:undefined|string) => void):HttpState;
  read():Promise<undefined|string>;
  removeEventListener(type:string, callback:(data?:undefined|string) => void):void;
  set(data:string):Promise<undefined|number>;
  write(data:string):Promise<undefined|number>;
  ws:{
    _?:undefined|WebSocket,
    delete:() => void,
    new:() => void,
    pingInterval?:undefined|number
  };
};

const httpstate:(uuid:string) => HttpState = (uuid:string):HttpState => {
  const _:HttpState = {
    data:undefined,
    et:{},
    uuid,

    addEventListener:(type:string, callback:(data?:undefined|string) => void) => _.on(type, callback),
    delete:() => {
      delete _.data;
      delete _.et;
      delete _.uuid;

      _.ws.delete();
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
        const data:undefined|string = await get(_.uuid);

        if(data !== _.data)
          setTimeout(() => _.emit('change', _.data), 0);
        
        _.data = data;

        return _.data;
      }
    },
    off:(type:string, callback?:(data?:undefined|string) => void) => {
      if(_.et?.[type]) {
        if(callback)
          _.et[type] = _.et[type].filter(_callback => _callback !== callback);

        if(!callback || !_.et[type].length)
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
    write:async (data:string):Promise<undefined|number> => _.set(data),
    ws:{
      _:undefined,
      delete:():void => {
        if(_.ws._) {
          clearInterval(_.ws.pingInterval);
          _.ws._.close(1000);

          delete _.ws._;
        }
      },
      pingInterval:undefined,
      new:():void => {
        _.ws.delete();

        _.ws._ = new WebSocket('wss://httpstate.com/' + uuid);

        _.ws._.addEventListener('open', () => {
          if(_.ws._) {
            _.ws._.addEventListener('close', e => {
              _.ws.delete();

              (function ᓇ(ms) { setTimeout(() => {
                _.ws.new();

                const onClose:() => void = ():void => ᓇ(Math.min(ms*2, 1024*32));

                if(_.ws._) {
                  _.ws._.addEventListener('close', onClose, { once:true });
                  _.ws._.addEventListener('open', () => {
                    if(_.ws._)
                      _.ws._.removeEventListener('close', onClose);
                  }, { once:true });
                }
              }, ms); })(1024);
            }, { once:true });
            _.ws._.addEventListener('error', e => console.log('error', e));
            _.ws._.addEventListener('message', async e => {
              const data:string = String(await e.data.text());

              if(
                   _.uuid
                && data
                && data.length > 32
                && data.substring(0, 32) === UUIDV4.short(_.uuid)
                && data.substring(45, 46) === '1'
              ) {
                _.data = data.substring(46);

                _.emit('change', _.data);
              }
            });

            _.ws._.send(JSON.stringify({ open:_.uuid }));

            _.emit('open');

            _.ws.pingInterval = setInterval(() => {
              if(
                   _.ws._
                && _.ws._.readyState === WebSocket.OPEN
              )
                _.ws._.send('0');
              else
                clearInterval(_.ws.pingInterval);
            }, 1000*30); // 30 SECONDS
          }
        }, { once:true });
      }
    }
  };

  _.ws.new();

  setTimeout(_.get, 0);

  return _;
};

export default httpstate;

if(
     typeof document !== 'undefined'
  && typeof window !== 'undefined'
  && globalThis === window
)
  globalThis.addEventListener('DOMContentLoaded', async () => {
    if((globalThis as any).httpstate)
      (globalThis as any).httpstate = Object.assign(
        (globalThis as any).httpstate.default,
        (globalThis as any).httpstate
      );

    await load();
  }, { once:true });
