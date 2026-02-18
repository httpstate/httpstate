// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import httpState, { set } from '@httpstate/typescript';
import { useEffect, useState } from 'react';

export const useHttpState:(uuid:string) => undefined|[undefined|string, (data:string) => Promise<number>] = (uuid:string):undefined|[undefined|string, (data:string) => Promise<number>] => {
  if(!uuid)
    return;

  const [state, setState]:[undefined|string, React.Dispatch<React.SetStateAction<undefined|string>>] = useState<undefined|string>(undefined);

  useEffect(() => {
    (async() => {
      const _ = httpState(uuid)
        .on('change', (e:Event&{ data?:string }) => setState(e.data));

      _.emit('change', await _.get());
    })();

    return () => {
      // ...
    };
  }, []);

  return [state, (data:string) => set(uuid, data)];
};
