%%--------------------------------------------------------------------
%% Copyright (c) 2020 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqx_plugin_rabbitmq_stream_app).

-behaviour(application).

-emqx_plugin(?MODULE).

-export([start/2
  , stop/1
]).
-include("emqx_plugin_rabbitmq_stream.hrl").

start(_StartType, _StartArgs) ->
  {ok, Connection} = connect(),
  ets:new(rabbitmq_client, [named_table, protected, set, {keypos, 1}]),
  ets:insert(rabbitmq_client, {connection, Connection}),
  ok = lake:create(Connection, ?STREAM, []),
  ok = lake:declare_publisher(Connection,?STREAM, ?PublisherId, ?PublisherReference),
  {ok, Sup} = emqx_plugin_rabbitmq_stream_sup:start_link(),
  emqx_plugin_rabbitmq_stream:load(application:get_all_env()),
  {ok, Sup}.

stop(_State) ->
  [{_,Connection}] = ets:lookup(rabbitmq_client, connection),
  ok = lake:delete_publisher(Connection, ?PublisherId),
  ok = lake:stop(Connection),
  emqx_plugin_rabbitmq_stream:unload().

connect() ->
  application:ensure_all_started(lake),
  Host = application:get_env(emqx_plugin_rabbitmq_stream, host, "localhost"),
  Port = application:get_env(emqx_plugin_rabbitmq_stream, port, 5552),
  User = application:get_env(emqx_plugin_rabbitmq_stream, user, "guest"),
  Password = application:get_env(emqx_plugin_rabbitmq_stream, password, "password"),
  Vhost = application:get_env(emqx_plugin_rabbitmq_stream, vhost, "/"),
  lake:connect(Host, Port, <<User>>, <<Password>>, <<Vhost>>).

