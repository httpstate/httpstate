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

    const state:HttpState = (globalThis as any).httpstate(uuid)
      .on('change', (e:Event&{ data:string }) => node.innerHTML = e.data);

    state.emit('change', await state.get());
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
  addEventListener(type:string, callback:null|EventListenerOrEventListenerObject):void;
  data?:undefined|string;
  emit(type:string, data:undefined|string):HttpState;
  et:EventTarget;
  get():Promise<undefined|string>;
  off(type:string, callback:null|EventListenerOrEventListenerObject):HttpState;
  on(type:string, callback:null|EventListenerOrEventListenerObject):HttpState;
  read():Promise<undefined|string>;
  removeEventListener(type:string, callback:null|EventListenerOrEventListenerObject):void;
  set(data:string):Promise<number>;
  uuid:string;
  write(data:string):Promise<number>;
  ws:WebSocket;
};

const httpstate:(uuid:string) => HttpState = (uuid:string):HttpState => {
  const _:HttpState = {
    addEventListener:(type:string, callback:null|EventListenerOrEventListenerObject) => _.et.addEventListener(type, callback),
    data:undefined,
    emit:(type:string, data:string) => {
      _.et.dispatchEvent(Object.assign(new Event(type), { data }));

      return _;
    },
    et:new EventTarget(),
    get:async ():Promise<undefined|string> => {
      const data = await get(_.uuid);

      if(data !== _.data)
        setTimeout(() => _.emit('change', _.data), 0);
      
      _.data = data;

      return _.data;
    },
    off:(type:string, callback:null|EventListenerOrEventListenerObject) => {
      _.removeEventListener(type, callback);

      return _;
    },
    on:(type:string, callback:null|EventListenerOrEventListenerObject) => {
      _.addEventListener(type, callback);

      return _;
    },
    read:async ():Promise<undefined|string> => read(_.uuid),
    removeEventListener:(type:string, callback:null|EventListenerOrEventListenerObject) => _.et.removeEventListener(type, callback),
    set:async (data:string):Promise<number> => set(_.uuid, data),
    uuid,
    write:async (data:string):Promise<number> => write(_.uuid, data),
    ws:new WebSocket('wss://httpstate.com/' + uuid)
  };

  _.ws.addEventListener('close', e => console.log('close', e));
  _.ws.addEventListener('error', e => console.log('error', e));
  _.ws.addEventListener('message', async e => {
    const data = await e.data.text();

    if(
         data
      && data.length > 30
      && data.substring(0, 32) === _.uuid
      && data.substring(45, 46) === '1'
    ) {
      _.data = data;

      _.emit('change', _.data);
    }
  });
  _.ws.addEventListener('open', () => _.ws.send(JSON.stringify({ open:_.uuid })));

  (_.ws as any).interval = setInterval(() => {
    if(_.ws.readyState === WebSocket.OPEN)
      _.ws.send('0');
    else
      clearInterval((_.ws as any).interval);
  }, 1000*30); // 30 SECONDS

  setTimeout(get, 0);

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
