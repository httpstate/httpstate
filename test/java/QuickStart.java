// HTTPState, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

import com.httpstate.HttpState;

public class QuickStart {
  public static void main(String[] args) throws Exception {
    new HttpState("58bff2fcbeb846958f36e7ae5b8a75b0")
      .On("change", data -> System.out.println(java.time.Instant.now().toString() + " data " + data));

    // Not needed per se, only meant to keep the script alive
    Thread.sleep(Long.MAX_VALUE);
  }
}
