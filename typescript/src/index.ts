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
  for(const node of document.querySelectorAll('[httpState],[httpstate]')) {
    const uuid:null|string = node.getAttribute('httpState')||node.getAttribute('httpstate');

    console.log('node.uuid', uuid);

    const ui:HttpState = (globalThis as any).httpState(uuid)
      .on('change', (e:Event&{ data:string }) => node.innerHTML = e.data);

    ui.et.dispatchEvent(Object.assign(new Event('change'), { data:await ui.get() }));
  }
};

export const read:(uuid:string) => Promise<undefined|string> = async (uuid:string):Promise<undefined|string> => get(uuid);

export const set:(uuid:string, data:string) => Promise<number> = async (uuid:string, data:string):Promise<number> => {
  const response:Response = await fetch('https://httpstate.com/' + uuid, { body:data, method:'POST' });

  return response.status;
};

export const write:(uuid:string, data:string) => Promise<number> = async (uuid:string, data:string):Promise<number> => set(uuid, data);

// httpState
type HttpState = {
  addEventListener(type:string, callback:null|EventListenerOrEventListenerObject):void;
  data?:undefined|string;
  et:EventTarget;
  get():Promise<undefined|string>;
  off(type:string, callback:null|EventListenerOrEventListenerObject):HttpState;
  on(type:string, callback:null|EventListenerOrEventListenerObject):HttpState;
  read():Promise<undefined|string>;
  removeEventListener(type:string, callback:null|EventListenerOrEventListenerObject):void;
  set(data:string):Promise<number>;
  write(data:string):Promise<number>;
  ws:WebSocket;
};

const httpState:(uuid:string) => HttpState = (uuid:string):HttpState => {
  const _:HttpState = {
    addEventListener:(type:string, callback:null|EventListenerOrEventListenerObject) => _.et.addEventListener(type, callback),
    data:undefined,
    et:new EventTarget(),
    get:async ():Promise<undefined|string> => get(uuid),
    off:(type:string, callback:null|EventListenerOrEventListenerObject) => {
      _.removeEventListener(type, callback);

      return _;
    },
    on:(type:string, callback:null|EventListenerOrEventListenerObject) => {
      _.addEventListener(type, callback);

      return _;
    },
    read:async ():Promise<undefined|string> => read(uuid),
    removeEventListener:(type:string, callback:null|EventListenerOrEventListenerObject) => _.et.removeEventListener(type, callback),
    set:async (data:string):Promise<number> => set(uuid, data),
    write:async (data:string):Promise<number> => write(uuid, data),
    ws:new WebSocket('wss://httpstate.com/' + uuid)
  };

  // ...

  return _;
};

export default httpState;

if(
     typeof document !== 'undefined'
  && typeof window !== 'undefined'
) {
  console.log('we do some magic ...');
  console.log('-', globalThis === window);
  console.log('-', (globalThis as any).httpstate);

  if(globalThis === window) {
    globalThis.addEventListener('load', async () => {
      if((globalThis as any).httpstate) {
        console.log('do the binding yo ...');

        (globalThis as any).httpState = (globalThis as any).httpstate = Object.assign(
          (globalThis as any).httpstate.default,
          (globalThis as any).httpstate
        );
      }

      await load();
    }, { once:true });
  }
}
