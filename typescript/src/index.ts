// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

const UID:() => string = ():string => Date.now().toString(36) + Math.random().toString(36).slice(2);

export const get:(uuid:string, args?:undefined|HTTPStateGetArgsType) => Promise<undefined|string|HTTPStateGetReturnType> = async (uuid:string, args?:undefined|HTTPStateGetArgsType):Promise<undefined|string|HTTPStateGetReturnType> => {
  try {
    const response:Response = await fetch('https://httpstate.com/' + uuid, { ...args?.Authorization && { headers:{ Authorization:args.Authorization } } });

    if(response.status === 200) {
      const data = await response.text();

      if(
           !args?.ETag
        && !args?.['Last-Modified']
      )
        return data;
      else
        return {
          ...args.ETag             && { ETag           :response.headers.get('ETag')          ?? undefined },
          ...args['Last-Modified'] && { 'Last-Modified':response.headers.get('Last-Modified') ?? undefined },
          data
        };
    } else if(response.status === 401)
      throw new Error('401 Unauthorized');
    else if(response.status === 404)
      throw new Error('404 Not Found');
    else if(response.status === 429)
      throw new Error('429 Too Many Requests: You can send up to 8 requests per second');
  } catch(e) {
    console.error(new Date().toISOString(), 'get.error', e);

    throw e;
  }
};

export const load:() => Promise<void> = async ():Promise<void> => {
  for(const uuid of new Set(Array.from(document.querySelectorAll<HTMLElement>('[httpstate]')).map(v => v.getAttribute('httpstate')).filter((v):v is string => Boolean(v)))) {
    if(!(load as any)._)
      (load as any)._ = {};

    if(!(load as any)._[uuid])
      (load as any)._[uuid] = httpstate(uuid).on('change', (data?:undefined|string) => {
        for(const node of document.querySelectorAll<HTMLElement>('[httpstate="' + uuid + '"]'))
          if(node instanceof HTMLImageElement)
            node.src = String(data);
          else
            node.textContent = String(data);
      });
  }
};

export type MessageStateType = {
  uuid:string;
  timestamp:number;
  type:number;
  value:Uint8Array;
};

export const message:{ unpack(ab:ArrayBuffer):undefined|MessageStateType } = { unpack(ab:ArrayBuffer):undefined|MessageStateType {
  const ui8a:Uint8Array = new Uint8Array(ab);
  const header:number = new DataView(ui8a.buffer, ui8a.byteOffset, 1).getUint8(0);

  if(header === 0) {
    const length:number = new DataView(ui8a.buffer, ui8a.byteOffset+1, 1).getUint8(0);

    return {
      uuid:new TextDecoder().decode(ui8a.slice(2, 2+length)),
      timestamp:Number(new DataView(ui8a.buffer, ui8a.byteOffset+2+length, 8).getBigUint64(0)),
      type:new DataView(ui8a.buffer, ui8a.byteOffset+2+length+8, 1).getUint8(0),
      value:ui8a.slice(2+length+8+1)
    };
  }
} };

export const post:(uuid:string, data?:undefined|string, args?:undefined|HTTPStateSetArgsType) => Promise<undefined|number> = async (uuid:string, data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number> => set(uuid, data, args);

export const put:(uuid:string, data?:undefined|string, args?:undefined|HTTPStateSetArgsType) => Promise<undefined|number> = async (uuid:string, data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number> => set(uuid, data, args);

export const read:(uuid:string, args?:undefined|HTTPStateGetArgsType) => Promise<undefined|string|HTTPStateGetReturnType> = async (uuid:string, args?:undefined|HTTPStateGetArgsType):Promise<undefined|string|HTTPStateGetReturnType> => get(uuid, args);

export const set:(uuid:string, data?:undefined|string, args?:undefined|HTTPStateSetArgsType) => Promise<undefined|number> = async (uuid:string, data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number> => {
  if(data === undefined || data === null)
    data = '';

  try {
    const response:Response = await fetch('https://httpstate.com/' + uuid, {
      body:data,
      headers:{
        ...args?.Authorization && { Authorization:args.Authorization },
        'Content-Type':'text/plain;charset=UTF-8'
      },
      method:'POST'
    });

    if(response.status === 401)
      throw new Error('401 Unauthorized');
    else if(response.status === 404)
      throw new Error('404 Not Found');
    else if(response.status === 413)
      throw new Error('413 Content Too Large');

    return response.status;
  } catch(e) {
    console.error(new Date().toISOString(), 'set.error', e);
  }
};

export const write:(uuid:string, data?:undefined|string, args?:undefined|HTTPStateSetArgsType) => Promise<undefined|number> = async (uuid:string, data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number> => set(uuid, data, args);


// HTTPState
export type HTTPStateGetArgsType = {
  Authorization?:string,
  ETag?:boolean,
  'Last-Modified'?:boolean
};
export type HTTPStateGetReturnType = {
  ETag?:undefined|string,
  'Last-Modified'?:undefined|string,
  data:undefined|string
};
export type HTTPStateSetArgsType = { Authorization?:undefined|string };

export type HTTPStateType = {
  authorization?:undefined|string;
  data?:undefined|string;
  et?:undefined|{ [type:string]:((data?:undefined|string) => void)[] };
  uid?:undefined|string;
  uuid?:undefined|string;
  visibilitychange?:undefined|((() => void)&{ now?:number });
  ws?:undefined|{
    _?:undefined|HTTPStateWebSocketType,

    delete():void,
    new:() => void
  };

  addEventListener(type:string, callback:(data?:undefined|string) => void):void;
  delete():void;
  emit(type:string, data?:undefined|string):HTTPStateType;
  get(args?:undefined|HTTPStateGetArgsType):Promise<undefined|string>;
  off(type:string, callback?:(data?:undefined|string) => void):HTTPStateType;
  on(type:string, callback:(data?:undefined|string) => void):HTTPStateType;
  post(data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number>;
  put(data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number>;
  read(args?:undefined|HTTPStateGetArgsType):Promise<undefined|string>;
  removeEventListener(type:string, callback:(data?:undefined|string) => void):void;
  set(data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number>;
  write(data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number>;
};

export type HTTPStateWebSocketOpenArgsType = { Authorization?:string };

export type HTTPStateWebSocketType = {
  _?:undefined|{ [uuid:string]:{
    authorization?:string,
    uid?:{ [uid:string]:{ [type:string]:((data?:undefined|string) => void)[] } }
  } };
  ws?:undefined|(WebSocket&{ pingInterval?:ReturnType<typeof setInterval> });

  addEventListener(uid:string, uuid:string, type:string, callback:(data?:undefined|string) => void):void;
  close(uid:string, uuid:string):void;
  delete():void;
  dispatchEvent(uuid:string, type:string, data?:undefined|string):void;
  open(uid:string, uuid:string, args?:HTTPStateWebSocketOpenArgsType):HTTPStateWebSocketType;
  new:(() => void)&{ timeout?:number };
};

export const HTTPState:(uuid:string, args?:{ Authorization?:string }) => HTTPStateType = (uuid:string, args?:{ Authorization?:string }):HTTPStateType => {
  const _:HTTPStateType = {
    authorization:args?.Authorization,
    data:undefined,
    et:{},
    uid:UID(),
    uuid,
    visibilitychange:undefined,
    ws:{
      _:undefined,
      delete:():void => {
        if(
             _.uid
          && _.uuid
          && _.ws
        ) {
          if(_.ws._)
            _.ws._.close(_.uid, _.uuid);

          delete _.ws._;
        }
      },
      new:():void => {
        if(
             _.uid
          && _.uuid
          && _.ws
        ) {
          _.ws._ = HTTPStateWebSocket.open(_.uid, _.uuid, { ..._.authorization && { Authorization:_.authorization } });

          _.ws._.addEventListener(_.uid, _.uuid, 'message', (data?:undefined|string):void => {
            _.data = data;

            _.emit('change', _.data);
          });
        }
      }
    },

    addEventListener:(type:string, callback:(data?:undefined|string) => void):HTTPStateType => _.on(type, callback),
    delete:():void => {
      if(_.ws)
        _.ws.delete();

      delete _.authorization;
      delete _.data;
      delete _.et;
      delete _.uid;
      delete _.uuid;

      if(_.visibilitychange)
        document.removeEventListener('visibilitychange', _.visibilitychange);
      delete _.visibilitychange;

      delete _.ws;
    },
    emit:(type:string, data?:undefined|string):HTTPStateType => {
      if(_.et?.[type])
        for(const callback of _.et[type])
          if(data === undefined)
            callback.call(_);
          else
            callback.call(_, data);

      return _;
    },
    get:async (args?:undefined|HTTPStateGetArgsType):Promise<undefined|string> => {
      if(_.uuid) {
        const data:undefined|string|HTTPStateGetReturnType = await get(_.uuid, { ..._.authorization && { Authorization:_.authorization }, ...args });

        if(data !== _.data)
          setTimeout(() => _.emit('change', _.data), 0);
        
        if(typeof data === 'string')
          _.data = data;

        return _.data;
      }
    },
    off:(type:string, callback?:(data?:undefined|string) => void):HTTPStateType => {
      if(_.et?.[type]) {
        if(callback)
          _.et[type] = _.et[type].filter(_callback => _callback !== callback);

        if(!callback || !_.et[type].length)
          delete _.et[type];
      }

      return _;
    },
    on:(type:string, callback:(data?:undefined|string) => void):HTTPStateType => {
      if(_.et) {
        if(!_.et[type])
          _.et[type] = [];

        _.et[type].push(callback);
      }

      return _;
    },
    post:async (data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number> => _.set(data, args),
    put:async (data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number> => _.set(data, args),
    read:async (args?:undefined|HTTPStateGetArgsType):Promise<undefined|string> => _.get(args),
    removeEventListener:(type:string, callback:(data?:undefined|string) => void):HTTPStateType => _.off(type, callback),
    set:async (data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number> => {
      if(_.uuid)
        return set(_.uuid, data, { ..._.authorization && { Authorization:_.authorization }, ...args });
    },
    write:async (data?:undefined|string, args?:undefined|HTTPStateSetArgsType):Promise<undefined|number> => _.set(data, args)
  };

  if(_.ws)
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

export const HTTPStateWebSocket:HTTPStateWebSocketType = {
  _:undefined,
  ws:undefined,

  addEventListener:(uid:string, uuid:string, type:string, callback:(data?:undefined|string) => void):void => {
    if(HTTPStateWebSocket._?.[uuid]?.uid?.[uid]) {
      if(!HTTPStateWebSocket._[uuid].uid[uid][type])
        HTTPStateWebSocket._[uuid].uid[uid][type] = [];

      HTTPStateWebSocket._[uuid].uid[uid][type].push(callback);
    }
  },
  close:(uid:string, uuid:string):void => {
    console.log(new Date().toISOString(), 'HTTPStateWebSocket.close', uid, uuid);

    if(HTTPStateWebSocket._?.[uuid]?.uid?.[uid])
      delete HTTPStateWebSocket._[uuid].uid[uid];

    if(
         HTTPStateWebSocket._?.[uuid]?.uid
      && !Object.keys(HTTPStateWebSocket._[uuid].uid).length
    )
      delete HTTPStateWebSocket._[uuid].uid;
    
    if(
         HTTPStateWebSocket._?.[uuid]
      && !Object.keys(HTTPStateWebSocket._[uuid]).length
    )
      delete HTTPStateWebSocket._[uuid];

    if(
         HTTPStateWebSocket._
      && !Object.keys(HTTPStateWebSocket._).length
    )
      delete HTTPStateWebSocket._;
  },
  delete:():void => {
    console.log(new Date().toISOString(), 'HTTPStateWebSocket.delete');
    
    if(HTTPStateWebSocket.ws) {
      clearInterval(HTTPStateWebSocket.ws.pingInterval);
      delete HTTPStateWebSocket.ws.pingInterval;

      if(HTTPStateWebSocket.ws.readyState === WebSocket.OPEN)
        HTTPStateWebSocket.ws.close(1000);

      delete HTTPStateWebSocket.ws;
    }
  },
  dispatchEvent:(uuid:string, type:string, data?:undefined|string):void => {
    if(HTTPStateWebSocket._?.[uuid]?.uid)
      for(const uid of Object.keys(HTTPStateWebSocket._[uuid].uid))
        if(HTTPStateWebSocket._[uuid].uid[uid]?.[type])
          for(const callback of HTTPStateWebSocket._[uuid].uid[uid][type])
            callback(data);
  },
  new:():void => {
    console.log(new Date().toISOString(), 'HTTPStateWebSocket.new');

    HTTPStateWebSocket.delete();

    HTTPStateWebSocket.ws = new WebSocket('wss://httpstate.com');

    HTTPStateWebSocket.ws.addEventListener('close', (e:CloseEvent) => {
      console.log(new Date().toISOString(), 'HTTPStateWebSocket.ws.close');
      
      HTTPStateWebSocket.delete();
      
      if(HTTPStateWebSocket._) {
        HTTPStateWebSocket.new.timeout = Math.min(Math.max(1024, (HTTPStateWebSocket.new.timeout||0)*2), 1024*60); // ~1 SECOND TO ~1 MINUTE

        console.log(new Date().toISOString(), 'HTTPStateWebSocket.new.timeout', HTTPStateWebSocket.new.timeout);
        setTimeout(HTTPStateWebSocket.new, HTTPStateWebSocket.new.timeout);
      }
    }, { once:true });
    HTTPStateWebSocket.ws.addEventListener('error', (e:Event) => console.error(new Date().toISOString(), 'HTTPStateWebSocket.ws.error'));
    HTTPStateWebSocket.ws.addEventListener('message', () => delete HTTPStateWebSocket.new.timeout, { once:true });
    HTTPStateWebSocket.ws.addEventListener('message', async (e:MessageEvent) => {
      const data:undefined|MessageStateType = message.unpack(await e.data.arrayBuffer());
      
      if(
           data
        && data.uuid
        && data.type === 1
      )
        HTTPStateWebSocket.dispatchEvent(data.uuid, 'message', new TextDecoder().decode(data.value));
    });
    HTTPStateWebSocket.ws.addEventListener('open', () => {
      if(HTTPStateWebSocket.ws) {
        if(HTTPStateWebSocket._)
          for(const uuid of Object.keys(HTTPStateWebSocket._))
            HTTPStateWebSocket.ws.send(JSON.stringify({
              open:uuid,
              ...HTTPStateWebSocket._[uuid]?.authorization && { Authorization:HTTPStateWebSocket._[uuid]?.authorization }
            }));

        HTTPStateWebSocket.ws.pingInterval = setInterval(() => {
          if(HTTPStateWebSocket.ws) {
            if(HTTPStateWebSocket.ws.readyState === WebSocket.OPEN)
              HTTPStateWebSocket.ws.send('0');
            else
              clearInterval(HTTPStateWebSocket.ws.pingInterval);
          }
        }, 1000*30); // 30 SECONDS
      }
    }, { once:true });
  },
  open:(uid:string, uuid:string, args?:HTTPStateWebSocketOpenArgsType):HTTPStateWebSocketType => {
    console.log(new Date().toISOString(), 'HTTPStateWebSocket.open', uid, uuid);

    if(!HTTPStateWebSocket._)
      HTTPStateWebSocket._ = {};
    
    if(!HTTPStateWebSocket._[uuid])
      HTTPStateWebSocket._[uuid] = {};

    if(!HTTPStateWebSocket._[uuid].uid)
      HTTPStateWebSocket._[uuid].uid = {};
    
    if(!HTTPStateWebSocket._[uuid].uid[uid])
      HTTPStateWebSocket._[uuid].uid[uid] = {};

    if(args?.Authorization)
      HTTPStateWebSocket._[uuid].authorization = args.Authorization;

    if(!HTTPStateWebSocket.ws)
      HTTPStateWebSocket.new();

    return HTTPStateWebSocket;
  }
};

export default Object.assign(HTTPState, {
  get,
  load,
  message,
  read,
  post,
  put,
  set,
  write
});

export const httpstate:(uuid:string, args?:{ Authorization?:string }) => HTTPStateType = HTTPState;

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
