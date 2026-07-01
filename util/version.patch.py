# HTTPState, https://httpstate.com/
# Copyright (C) Alex Morales, 2026

# Unless otherwise stated in particular files or directories, this software is free software.
# You can redistribute it and/or modify it under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.

import re
import sys

with open(sys.argv[1] + '/pyproject.toml', 'r+') as f:
  content:str = f.read()

  version:re.Match = re.search(r'version = \"(\d+)\.(\d+)\.(\d+)\"', content)

  content = content.replace(
    version.group(0),
    f'version = \"{version[1]}.{version[2]}.{int(version[3])+1}\"'
  )

  f.seek(0)
  f.truncate()
  f.write(content)
