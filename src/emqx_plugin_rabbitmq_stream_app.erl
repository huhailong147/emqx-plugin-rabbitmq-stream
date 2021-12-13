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
  {ok, ?RABBITMQ_CLIENT} = connect(),
  ok = lake:create(?RABBITMQ_CLIENT, ?STREAM, []),
  ok = lake:declare_publisher(?RABBITMQ_CLIENT,?STREAM, ?PublisherId, ?PublisherReference),
  {ok, Sup} = emqx_plugin_template_sup:start_link(),
  {ok, Sup}.

stop(_State) ->
  ok = lake:delete_publisher(?RABBITMQ_CLIENT, ?PublisherId),
  ok = lake:stop(?RABBITMQ_CLIENT),
  emqx_plugin_template:unload().

connect() ->
  application:ensure_all_started(lake),
  Host = application:get_env(emqx_bridge_kafka, host, "localhost"),
  Port = application:get_env(emqx_bridge_kafka, port, 5552),
  User = application:get_env(emqx_bridge_kafka, user, "guest"),
  Password = application:get_env(emqx_bridge_kafka, password, "password"),
  Vhost = application:get_env(emqx_bridge_kafka, vhost, "/"),
  emqx_plugin_template:load(application:get_all_env()),
  {ok, ?RABBITMQ_CLIENT} = lake:connect(Host, Port, <<User>>, <<Password>>, <<Vhost>>),
  lake:connect(Host, Port, <<User>>, <<Password>>, <<Vhost>>).

