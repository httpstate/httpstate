# HTTP State, https://httpstate.com/
# Copyright (C) Alex Morales, 2026
#
# Unless otherwise stated in particular files or directories, this software is free software.
# You can redistribute it and/or modify it under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.

# frozen_string_literal: true

require 'eventmachine'
require 'faye/websocket'
require 'json'
require 'net/http'
require 'socket'
require 'uri'

class HttpState
  VERSION = '0.0.1'

  attr_reader :data, :uuid, :ws

  def self.get(uuid)
    response = Net::HTTP.get(URI.join('https://httpstate.com', uuid))

    response
  rescue StandardError => e
    puts 'Error: ' + e.message

    nil
  end

  def self.set(uuid, data)
    uri = URI.join('https://httpstate.com', uuid)

    request = Net::HTTP::Post.new(uri)
    request.body = data
    request.content_type = 'text/plain;charset=UTF-8'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl:uri.scheme == 'https') do |http|
      http.request(request)
    end

    response.code
  rescue StandardError => e
    puts 'Error: ' + e.message

    nil
  end

  class << self
    alias read get
    alias write set
  end

  def initialize(uuid)
    @data = nil
    @et = nil
    @uuid = uuid
    @ws = nil

    Thread.new do
      EM.run do
        @ws = Faye::WebSocket::Client.new('wss://httpstate.com/' + @uuid)

        @ws.on :close do |_|
          puts '@ws.close'
        end

        @ws.on :error do |_|
          puts '@ws.error'
        end

        @ws.on :message do |event|
          if @uuid &&
             !event.data.empty? &&
             event.data.length > 32 &&
             event.data[0...32] == @uuid &&
             event.data[45] == '1'
            @data = event.data[46..]

            emit('change', @data)
          end
        end

        @ws.on :open do |_|
          puts '@ws.open'

          @ws.send({ open:@uuid }.to_json)
        end
      end

      get()
    end
  end

  def emit(type, data = nil)
    if @et && @et[type]
      for callback in @et[type]
        if data.nil?
          callback.call
        else
          callback.call(data)
        end
      end
    end

    self
  end

  def get
    if @uuid
      data = self.class.get(@uuid)

      if(data != @data)
        # emit change
      end
      
      @data = data

      return @data
    end
  end

  def off(type, &callback)
    if @et && @et[type]
      if callback
        @et[type].delete(callback)
      end
      
      if !callback || @et[type].empty?
        @et.delete(type)
      end
    end

    self
  end

  def on(type, &callback)
    @et ||= {}
    @et[type] ||= []
    @et[type] << callback

    self
  end

  def set(data)
    self.class.set(@uuid, data) if @uuid
  end

  alias read get
  alias write set
end
