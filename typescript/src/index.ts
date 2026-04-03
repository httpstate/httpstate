// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

const UID:() => string = ():string => Date.now().toString(36) + Math.random().toString(36).slice(2);

export const get:(uuid:string) => Promise<undefined|string> = async (uuid:string):Promise<undefined|string> => {
  try {
    const response:Response = await fetch('https://httpstate.com/' + uuid);

    if(response.status === 200)
      return await response.text();
  } catch(e) {
    console.error(new Date().toISOString(), 'get.error', e);
  }
};

export const load:() => Promise<void> = async ():Promise<void> => {
  for(const uuid of new Set(Array.from(document.querySelectorAll<HTMLElement>('[httpstate]')).map(v => v.getAttribute('httpstate')).filter((v):v is string => Boolean(v)))) {
    if(!(load as any)._)
      (load as any)._ = {};

    if(!(load as any)._[uuid])
      (load as any)._[uuid] = httpstate(uuid).on('change', (data?:undefined|string) => {
        for(const node of document.querySelectorAll<HTMLElement>('[httpstate="' + uuid + '"]'))
          node.innerHTML = String(data);
      });
  }
};

export type MessageType = {
  uuid:string;
  timestamp:number;
  type:number;
  value:Uint8Array;
};

export const message:{ unpack(ab:ArrayBuffer):MessageType } = { unpack(ab:ArrayBuffer):MessageType {
  const ui8a:Uint8Array = new Uint8Array(ab);
  const length:number = new DataView(ui8a.buffer, ui8a.byteOffset, 1).getUint8(0);

  return {
    uuid:new TextDecoder().decode(ui8a.slice(1, 1+length)),
    timestamp:Number(new DataView(ui8a.buffer, ui8a.byteOffset+1+length, 8).getBigUint64(0)),
    type:new DataView(ui8a.buffer, ui8a.byteOffset+1+length+8, 1).getUint8(0),
    value:ui8a.slice(1+length+8+1)
  };
} };

export const post:(uuid:string, data?:undefined|string) => Promise<number> = async (uuid:string, data?:undefined|string):Promise<number> => set(uuid, data);

export const put:(uuid:string, data?:undefined|string) => Promise<number> = async (uuid:string, data?:undefined|string):Promise<number> => set(uuid, data);

export const read:(uuid:string) => Promise<undefined|string> = async (uuid:string):Promise<undefined|string> => get(uuid);

export const set:(uuid:string, data?:undefined|string) => Promise<number> = async (uuid:string, data?:undefined|string):Promise<number> => {
  if(!data)
    data = '';

  try {
    const response:Response = await fetch('https://httpstate.com/' + uuid, {
      body:data,
      headers:{ 'Content-Type':'text/plain;charset=UTF-8' },
      method:'POST'
    });

    return response.status;
  } catch(e) {
    console.error(new Date().toISOString(), 'set.error', e);
  }
};

export const write:(uuid:string, data?:undefined|string) => Promise<number> = async (uuid:string, data?:undefined|string):Promise<number> => set(uuid, data);


// HTTP State
export type HttpStateType = {
  data?:undefined|string;
  et?:undefined|{ [type:string]:((data?:undefined|string) => void)[] };
  uid?:undefined|string;
  uuid?:undefined|string;
  visibilitychange?:undefined|((() => void)&{ now?:number });
  ws:{
    _?:undefined|HttpStateWebSocketType,

    delete():void,
    new:() => void
  };

  addEventListener(type:string, callback:(data?:undefined|string) => void):void;
  delete():void;
  emit(type:string, data?:undefined|string):HttpStateType;
  get():Promise<undefined|string>;
  off(type:string, callback?:(data?:undefined|string) => void):HttpStateType;
  on(type:string, callback:(data?:undefined|string) => void):HttpStateType;
  post(data?:undefined|string):Promise<undefined|number>;
  put(data?:undefined|string):Promise<undefined|number>;
  read():Promise<undefined|string>;
  removeEventListener(type:string, callback:(data?:undefined|string) => void):void;
  set(data?:undefined|string):Promise<undefined|number>;
  write(data?:undefined|string):Promise<undefined|number>;
};

export type HttpStateWebSocketType = {
  _?:undefined|{ [uuid:string]:{ [uid:string]:{ [type:string]:((data?:undefined|string) => void)[] } } };
  ws?:undefined|(WebSocket&{ pingInterval?:ReturnType<typeof setInterval> });

  addEventListener(uid:string, uuid:string, type:string, callback:(data?:undefined|string) => void):void;
  close(uid:string, uuid:string):void;
  delete():void;
  dispatchEvent(uuid:string, type:string, data?:undefined|string):void;
  open(uid:string, uuid:string):HttpStateWebSocketType;
  new:(() => void)&{ timeout?:number };
};

export const HttpState:(uuid:string) => HttpStateType = (uuid:string):HttpStateType => {
  const _:HttpStateType = {
    data:undefined,
    et:{},
    uid:UID(),
    uuid,
    ws:{
      _:undefined,
      delete:():void => {
        if(
             _.uid
          && _.uuid
          && _.ws._
        )
          _.ws._.close(_.uid, _.uuid);

        delete _.ws._;
      },
      new:():void => {
        if(
             _.uid
          && _.uuid
        ) {
          _.ws._ = HttpStateWebSocket.open(_.uid, _.uuid);

          _.ws._.addEventListener(_.uid, _.uuid, 'message', (data?:undefined|string):void => {
            _.data = data;

            _.emit('change', _.data);
          });
        }
      }
    },


    addEventListener:(type:string, callback:(data?:undefined|string) => void):HttpStateType => _.on(type, callback),
    delete:():void => {
      _.ws.delete();

      delete _.data;
      delete _.et;
      delete _.uid;
      delete _.uuid;

      if(_.visibilitychange)
        document.removeEventListener('visibilitychange', _.visibilitychange);
      delete _.visibilitychange;
    },
    emit:(type:string, data?:undefined|string):HttpStateType => {
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
    off:(type:string, callback?:(data?:undefined|string) => void):HttpStateType => {
      if(_.et?.[type]) {
        if(callback)
          _.et[type] = _.et[type].filter(_callback => _callback !== callback);

        if(!callback || !_.et[type].length)
          delete _.et[type];
      }

      return _;
    },
    on:(type:string, callback:(data?:undefined|string) => void):HttpStateType => {
      if(_.et) {
        if(!_.et[type])
          _.et[type] = [];

        _.et[type].push(callback);
      }

      return _;
    },
    post:async (data?:undefined|string):Promise<undefined|number> => _.set(data),
    put:async (data?:undefined|string):Promise<undefined|number> => _.set(data),
    read:async ():Promise<undefined|string> => _.get(),
    removeEventListener:(type:string, callback:(data?:undefined|string) => void):HttpStateType => _.off(type, callback),
    set:async (data?:undefined|string):Promise<undefined|number> => {
      if(_.uuid)
        return set(_.uuid, data);
    },
    write:async (data?:undefined|string):Promise<undefined|number> => _.set(data)
  };

  _.ws.new();

  setTimeout(_.get, 0);
  
  if(
       typeof document !== 'undefined'
    && typeof window !== 'undefined'
    && globalThis === window
  ) {
    _.visibilitychange = () => {
      if(_.visibilitychange) {
        if(document.visibilityState === 'hidden')
          _.visibilitychange.now = Date.now();
        else if(
             document.visibilityState === 'visible'
          && _.visibilitychange.now
          && Date.now()-_.visibilitychange.now > 1000*60 // 1 MIN
        )
          _.get();
      }
    };
    document.addEventListener('visibilitychange', _.visibilitychange);
  }

  return _;
};

export const HttpStateWebSocket:HttpStateWebSocketType = {
  _:undefined,
  ws:undefined,

  addEventListener:(uid:string, uuid:string, type:string, callback:(data?:undefined|string) => void):void => {
    if(HttpStateWebSocket._?.[uuid]?.[uid]) {
      if(!HttpStateWebSocket._[uuid][uid][type])
        HttpStateWebSocket._[uuid][uid][type] = [];

      HttpStateWebSocket._[uuid][uid][type].push(callback);
    }
  },
  close:(uid:string, uuid:string):void => {
    console.log(new Date().toISOString(), 'HttpStateWebSocket.close', uid, uuid);

    if(HttpStateWebSocket._?.[uuid]) {
      delete HttpStateWebSocket._[uuid][uid];

      if(!Object.keys(HttpStateWebSocket._[uuid]).length)
        delete HttpStateWebSocket._[uuid];

      if(!Object.keys(HttpStateWebSocket._).length)
        delete HttpStateWebSocket._;
    }
  },
  delete:():void => {
    console.log(new Date().toISOString(), 'HttpStateWebSocket.delete');
    
    if(HttpStateWebSocket.ws) {
      clearInterval(HttpStateWebSocket.ws.pingInterval);
      delete HttpStateWebSocket.ws.pingInterval;

      if(HttpStateWebSocket.ws.readyState === WebSocket.OPEN)
        HttpStateWebSocket.ws.close(1000);

      delete HttpStateWebSocket.ws;
    }
  },
  dispatchEvent:(uuid:string, type:string, data?:undefined|string):void => {
    if(HttpStateWebSocket._?.[uuid])
      for(const uid of Object.keys(HttpStateWebSocket._[uuid]))
        if(HttpStateWebSocket._[uuid][uid]?.[type])
          for(const callback of HttpStateWebSocket._[uuid][uid][type])
            callback(data);
  },
  new:():void => {
    console.log(new Date().toISOString(), 'HttpStateWebSocket.new');

    HttpStateWebSocket.delete();

    HttpStateWebSocket.ws = new WebSocket('wss://httpstate.com');

    HttpStateWebSocket.ws.addEventListener('close', (e:CloseEvent) => {
      console.log(new Date().toISOString(), 'HttpStateWebSocket.ws.close');
      
      HttpStateWebSocket.delete();
      
      if(HttpStateWebSocket._) {
        HttpStateWebSocket.new.timeout = Math.min(Math.max(1024, (HttpStateWebSocket.new.timeout||0)*2), 1024*60); // ~1 SECOND TO ~1 MINUTE

        console.log(new Date().toISOString(), 'HttpStateWebSocket.new.timeout', HttpStateWebSocket.new.timeout);
        setTimeout(HttpStateWebSocket.new, HttpStateWebSocket.new.timeout);
      }
    }, { once:true });
    HttpStateWebSocket.ws.addEventListener('error', (e:Event) => console.error(new Date().toISOString(), 'HttpStateWebSocket.ws.error'));
    HttpStateWebSocket.ws.addEventListener('message', () => delete HttpStateWebSocket.new.timeout, { once:true });
    HttpStateWebSocket.ws.addEventListener('message', async (e:MessageEvent) => {
      const data:MessageType = message.unpack(await e.data.arrayBuffer());
      
      if(
           data.uuid
        && data.type === 1
      )
        HttpStateWebSocket.dispatchEvent(data.uuid, 'message', new TextDecoder().decode(data.value));
    });
    HttpStateWebSocket.ws.addEventListener('open', () => {
      if(HttpStateWebSocket.ws) {
        if(HttpStateWebSocket._)
          for(const uuid of Object.keys(HttpStateWebSocket._))
            HttpStateWebSocket.ws.send(JSON.stringify({ open:uuid }));

        HttpStateWebSocket.ws.pingInterval = setInterval(() => {
          if(HttpStateWebSocket.ws) {
            if(HttpStateWebSocket.ws.readyState === WebSocket.OPEN)
              HttpStateWebSocket.ws.send('0');
            else
              clearInterval(HttpStateWebSocket.ws.pingInterval);
          }
        }, 1000*30); // 30 SECONDS
      }
    }, { once:true });
  },
  open:(uid:string, uuid:string):HttpStateWebSocketType => {
    console.log(new Date().toISOString(), 'HttpStateWebSocket.open', uid, uuid);

    if(!HttpStateWebSocket._)
      HttpStateWebSocket._ = {};
    
    if(!HttpStateWebSocket._[uuid])
      HttpStateWebSocket._[uuid] = {};
    
    if(!HttpStateWebSocket._[uuid][uid])
      HttpStateWebSocket._[uuid][uid] = {};

    if(!HttpStateWebSocket.ws)
      HttpStateWebSocket.new();

    return HttpStateWebSocket;
  }
};

export default Object.assign(HttpState, {
  get,
  load,
  message,
  read,
  post,
  put,
  set,
  write
});

export const httpstate:(uuid:string) => HttpStateType = HttpState;

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
