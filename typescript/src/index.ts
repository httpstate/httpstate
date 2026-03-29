// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

const UID:() => string = ():string => Date.now().toString(36) + Math.random().toString(36).slice(2);

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
  for(const uuid of new Set(Array.from(document.querySelectorAll<HTMLElement>('[httpstate]')).map(v => v.getAttribute('httpstate')).filter((v):v is string => Boolean(v)))) {
    if(!(load as any)._)
      (load as any)._ = {};

    if(!(load as any)._[uuid])
      (load as any)._[uuid] = httpstate(uuid).on('change', (data:undefined|string) => {
        for(const node of document.querySelectorAll<HTMLElement>('[httpstate="' + uuid + '"]'))
          node.innerHTML = String(data);
      });
  }
};

export const post:(uuid:string, data:string) => Promise<number> = async (uuid:string, data:string):Promise<number> => set(uuid, data);

export const put:(uuid:string, data:string) => Promise<number> = async (uuid:string, data:string):Promise<number> => set(uuid, data);

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
  uid:string;
  uuid?:undefined|string;
  // ws:{
  //   _?:undefined|WebSocket,
  //   delete:() => void,
  //   new:() => void,
  //   pingInterval?:undefined|number
  // };
  ws:any; //X

  addEventListener(type:string, callback:(data?:undefined|string) => void):void;
  delete():void;
  emit(type:string, data?:undefined|string):HttpState;
  get():Promise<undefined|string>;
  off(type:string, callback?:(data?:undefined|string) => void):HttpState;
  on(type:string, callback:(data?:undefined|string) => void):HttpState;
  post(data:string):Promise<undefined|number>;
  put(data:string):Promise<undefined|number>;
  read():Promise<undefined|string>;
  removeEventListener(type:string, callback:(data?:undefined|string) => void):void;
  set(data:string):Promise<undefined|number>;
  write(data:string):Promise<undefined|number>;
};

export const HttpStateWebSocket:any = { //X - type
  _:undefined,
  addEventListener:(uuid:string, uid:string, type:string, callback:any) => { //X
    //T - once:true

    // ...
    if(HttpStateWebSocket._?.[uuid]) {
      if(!HttpStateWebSocket._[uuid][uid])
        HttpStateWebSocket._[uuid][uid] = {};

      if(!HttpStateWebSocket._[uuid][uid][type])
        HttpStateWebSocket._[uuid][uid][type] = [];

      HttpStateWebSocket._[uuid][uid][type].push(callback);
    }
  },
  close:(uid:string) => {
    console.log('HttpStateWebSocket', 'close', uid);
  },
  delete:(uid:string) => {
    console.log('HttpStateWebSocket', 'delete', uid);
  },
  dispatchEvent:(uuid:string, type:string, data:string) => {
    if(HttpStateWebSocket._?.[uuid])
      for(const uid of Object.keys(HttpStateWebSocket._[uuid]))
        if(HttpStateWebSocket._[uuid][uid]?.[type])
          for(const callback of HttpStateWebSocket._[uuid][uid][type])
            callback(data);
  },
  new:():void => {
    HttpStateWebSocket.delete();

    HttpStateWebSocket.ws = new WebSocket('wss://httpstate.com');
    (window as any).ws = HttpStateWebSocket.ws; //X

    HttpStateWebSocket.ws.addEventListener('close', (e:any) => { //X
      console.log('ws.close', e);
    });
    HttpStateWebSocket.ws.addEventListener('error', (e:any) => { //X
      console.log('ws.error', e);
    });
    HttpStateWebSocket.ws.addEventListener('open', () => {
      console.log('ws.open');

      for(const uuid of Object.keys(HttpStateWebSocket._))
        HttpStateWebSocket.ws.send(JSON.stringify({ open:uuid }));
    }, { once:true });
    HttpStateWebSocket.ws.addEventListener('message', async (e:any) => { //X
      const data:string = String(await e.data.text());

      if(
            data
        && data.length > 32
        && data.substring(45, 46) === '1'
      ) {
        const uuid:string = data.substring(0, 32);

        HttpStateWebSocket.dispatchEvent(uuid, 'message', data.substring(46));
      }
    });
  },
  open:(uuid:string, uid:string) => {
    console.log('HttpStateWebSocket', 'open', uuid, uid);

    if(!HttpStateWebSocket._)
      HttpStateWebSocket._ = {};
    
    if(!HttpStateWebSocket._[uuid])
      HttpStateWebSocket._[uuid] = {};

    if(!HttpStateWebSocket.ws)
      HttpStateWebSocket.new();

    return HttpStateWebSocket;
  },
  ws:undefined
};

export const httpstate:(uuid:string) => HttpState = (uuid:string):HttpState => {
  const _:HttpState = {
    data:undefined,
    et:{},
    uid:UID(),
    uuid,
    // ws:{
    //   _:undefined,
    //   delete:():void => {
    //     if(_.ws._) {
    //       clearInterval(_.ws.pingInterval);
    //       _.ws._.close(1000);

    //       delete _.ws._;
    //     }
    //   },
    //   pingInterval:undefined,
    //   new:():void => {
    //     console.log(new Date().toISOString(), uuid, 'ws.new');
    //     _.ws.delete();

    //     _.ws._ = new WebSocket('wss://httpstate.com/' + uuid);

    //     _.ws._.addEventListener('close', e => {
    //       console.log(new Date().toISOString(), uuid, 'ws.close', e);

    //       let timeout = (_.ws.new as any).timeout||0;
    //       (_.ws.new as any).timeout = Math.min(Math.max(1024, timeout*2), 1024*60); // ~1 SECOND TO ~1 MINUTE

    //       console.log(new Date().toISOString(), uuid, 'ws.new.timeout', (_.ws.new as any).timeout);
    //       setTimeout(_.ws.new, (_.ws.new as any).timeout);
    //     }, { once:true });
    //     _.ws._.addEventListener('error', e => console.error(new Date().toISOString(), uuid, 'ws.error', e));
    //     _.ws._.addEventListener('open', () => {
    //       if(_.ws._) {
    //         _.ws._.addEventListener('message', () => delete (_.ws.new as any).timeout, { once:true });
    //         _.ws._.addEventListener('message', async e => {
    //           const data:string = String(await e.data.text());

    //           if(
    //                _.uuid
    //             && data
    //             && data.length > 32
    //             && data.substring(0, 32) === UUIDV4.short(_.uuid)
    //             && data.substring(45, 46) === '1'
    //           ) {
    //             _.data = data.substring(46);

    //             _.emit('change', _.data);
    //           }
    //         });

    //         _.ws._.send(JSON.stringify({ open:_.uuid }));

    //         _.emit('open');

    //         _.ws.pingInterval = setInterval(() => {
    //           if(
    //                _.ws._
    //             && _.ws._.readyState === WebSocket.OPEN
    //           )
    //             _.ws._.send('0');
    //           else
    //             clearInterval(_.ws.pingInterval);
    //         }, 1000*30); // 30 SECONDS
    //       }
    //     }, { once:true });
    //   }
    // },
    ws:{
      _:undefined,
      delete:():void => {
        // ...
      },
      new:():void => {
        console.log('new ws', _.uid);

        _.ws._ = HttpStateWebSocket.open(_.uuid, _.uid);

        _.ws._.addEventListener(_.uuid, _.uid, 'message', async (data:any) => { //X
          _.data = data;

          _.emit('change', _.data);
        });
      }
    },


    addEventListener:(type:string, callback:(data?:undefined|string) => void) => _.on(type, callback),
    delete:() => {
      delete _.data;
      delete _.et;
      delete _.uuid;

      // _.ws.delete();
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
    post:async (data:string):Promise<undefined|number> => _.set(data),
    put:async (data:string):Promise<undefined|number> => _.set(data),
    read:async ():Promise<undefined|string> => _.get(),
    removeEventListener:(type:string, callback:(data?:undefined|string) => void) => _.off(type, callback),
    set:async (data:string):Promise<undefined|number> => {
      if(_.uuid)
        return set(_.uuid, data);
    },
    write:async (data:string):Promise<undefined|number> => _.set(data)
  };

  _.ws.new();

  setTimeout(_.get, 0);

  return _;
};

export default Object.assign(httpstate, {
  get,
  load,
  read,
  post,
  put,
  set,
  write
});

if(
     typeof document !== 'undefined'
  && typeof window !== 'undefined'
  && globalThis === window
)
  globalThis.addEventListener('DOMContentLoaded', async () => {
    if((globalThis as any).httpstate)
      (globalThis as any).httpstate = (globalThis as any).httpstate.default;

    await load();
  }, { once:true });
