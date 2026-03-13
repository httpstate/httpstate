// HTTP State, https://httpstate.com/
// Copyright (C) Alex Morales, 2026
//
// Unless otherwise stated in particular files or directories, this software is free software.
// You can redistribute it and/or modify it under the terms of the GNU Affero
// General Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.

package com.httpstate;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.WebSocket;
import java.net.http.WebSocket.Listener;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

public class HttpState {
  static String Get(String uuid) throws Exception {
    HttpClient httpClient = HttpClient.newHttpClient();

    HttpRequest httpRequest = HttpRequest.newBuilder()
      .uri(URI.create("https://httpstate.com/" + uuid))
      .GET()
      .build();

    HttpResponse<String> httpResponse = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());

    return httpResponse.statusCode() == 200
      ? httpResponse.body()
      : null;
  }

  static String Read(String uuid) throws Exception {
    return Get(uuid);
  }

  static int Set(String uuid, String body) throws Exception {
    HttpClient httpClient = HttpClient.newHttpClient();

    HttpRequest httpRequest = HttpRequest.newBuilder()
      .uri(URI.create("https://httpstate.com/" + uuid))
      .header("Content-Type", "text/plain;charset=UTF-8")
      .POST(HttpRequest.BodyPublishers.ofString(body))
      .build();

    HttpResponse<String> httpResponse = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());

    return httpResponse.statusCode();
  }

  static int Write(String uuid, String body) throws Exception {
    return Set(uuid, body);
  }

  public String data;
  private final Map<String, List<Consumer<String>>> et;
  private String uuid;
  private WebSocket ws;

  public void Emit(String type) {
    this.Emit(type, null);
  }

  public void Emit(String type, String data) {
    if(this.et.get(type) != null)
      for(Consumer<String> callback : this.et.get(type))
        callback.accept(data);
  }

  public String Get() throws Exception {
    if(this.uuid != null) {
      String data = HttpState.Get(this.uuid);

      if(!data.equals(this.data))
        CompletableFuture.runAsync(() -> this.Emit("change", this.data));

      this.data = data;

      return this.data;
    } else return null;
  }

  public void Off(String type, Consumer<String> callback) {
    if(this.et.get(type) != null) {
      if(callback != null)
        this.et.get(type).remove(callback);

      if(callback == null || this.et.get(type).isEmpty())
        this.et.remove(type);
    }
  }

  public void On(String type, Consumer<String> callback) {
    if(this.et.get(type) == null)
      this.et.put(type, new ArrayList<>());

    this.et.get(type).add(callback);
  }

  public String Read() throws Exception {
    return this.Get();
  }

  public int Set(String body) throws Exception {
    return this.uuid != null
      ? HttpState.Set(this.uuid, body)
      : null;
  }

  public int Write(String body) throws Exception {
    return this.Set(body);
  }

  public HttpState(String uuid) throws Exception {
    this.data = null;
    this.et = new HashMap<String, List<Consumer<String>>>();
    this.uuid = uuid;
    this.ws = null;

    Listener listener = new Listener() {
      @Override
      public CompletionStage<?> onClose(WebSocket webSocket, int statusCode, String reason) {
        System.out.println("onClose");

        return null;
      }

      @Override
      public void onError(WebSocket webSocket, Throwable error) {
        error.printStackTrace();
      }

      @Override
      public void onOpen(WebSocket webSocket) {
        HttpState.this.ws = webSocket;

        HttpState.this.ws.sendText("{\"open\":\"" + HttpState.this.uuid + "\"}", true);

        HttpState.this.Emit("open");

        Executors.newSingleThreadScheduledExecutor()
          .scheduleAtFixedRate(() -> HttpState.this.ws.sendPing(ByteBuffer.allocate(0)), 0, 30, TimeUnit.SECONDS);

        HttpState.this.ws.request(1);
      }

      @Override
      public CompletionStage<?> onBinary(WebSocket webSocket, ByteBuffer data, boolean last) {
        String _data = StandardCharsets.UTF_8.decode(data).toString();

        if(
             HttpState.this.uuid != null
          && !_data.isEmpty()
          && _data.length() > 32
          && _data.substring(0, 32).equals(HttpState.this.uuid)
          && _data.substring(45, 46).equals("1")
        ) {
          HttpState.this.data = _data.substring(46);

          HttpState.this.Emit("change", HttpState.this.data);
        }

        HttpState.this.ws.request(1);

        return null;
      }
    };

    HttpClient.newHttpClient()
      .newWebSocketBuilder()
      .buildAsync(URI.create("wss://httpstate.com/" + this.uuid), listener)
      .join();

    this.Get();
  }
}
