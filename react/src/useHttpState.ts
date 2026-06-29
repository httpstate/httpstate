// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import httpState, { set } from '@httpstate/typescript';
import { useEffect, useState } from 'react';

import type { HTTPStateSetArgsType, HTTPStateType } from '@httpstate/typescript';

export const useHttpState:(uuid:string, args?:{ Authorization?:string }) => undefined|[undefined|string, (data:string, args?:HTTPStateSetArgsType) => Promise<undefined|number>] = (uuid:string, args?:{ Authorization?:string }):undefined|[undefined|string, (data:string, args?:HTTPStateSetArgsType) => Promise<undefined|number>] => {
  if(!uuid)
    return;

  const [state, setState]:[undefined|string, React.Dispatch<React.SetStateAction<undefined|string>>] = useState<undefined|string>(undefined);

  useEffect(() => {
    let _:undefined|HTTPStateType;

    (async() => {
      _ = httpState(uuid, args)
        .on('change', (data?:undefined|string) => setState(data));

      _.emit('change', await _.get());
    })();

    return () => {
      if(_)
        _.delete();
    };
  }, []);

  return [state, (data:string, args?:HTTPStateSetArgsType) => set(uuid, data, args)];
};
