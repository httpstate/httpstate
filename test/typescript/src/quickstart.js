// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

// npm install @httpstate/typescript

import httpstate from '@httpstate/typescript';

httpstate('58bff2fcbeb846958f36e7ae5b8a75b0')
  .on('change', data => console.log(new Date().toISOString(), 'data', data));
