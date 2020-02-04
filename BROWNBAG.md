# Brownbag

## Critical

* Test distribution on cluster
* White list only workers to run game servers
* Optimize possible actions resource (cache actions, use ETS)
* Investigate duplicate winners pkey

      Feb 04 20:55:34 api boardr_api[15145]: 20:55:34.433 [error] Ranch protocol #PID<0.20784.1> of listener BoardrApi.Endpoint.HTTP (connection #PID<0.20783.1>, stream id 1) terminated
      Feb 04 20:55:34 api boardr_api[15145]: ** (exit) an exception was raised:
      Feb 04 20:55:34 api boardr_api[15145]:     ** (Postgrex.Error) ERROR 23505 (unique_violation) duplicate key value violates unique constraint "winners_pkey"
      Feb 04 20:55:34 api boardr_api[15145]:     table: winners
      Feb 04 20:55:34 api boardr_api[15145]:     constraint: winners_pkey
      Feb 04 20:55:34 api boardr_api[15145]: Key (game_id, player_id)=(444ddd9e-daa0-4822-9ba6-41261f481579, 6ccb7bc4-3865-4190-bb2d-30ad0be32d3c) already exists.
      Feb 04 20:55:34 api boardr_api[15145]:         (ecto_sql 3.3.3) lib/ecto/adapters/sql.ex:612: Ecto.Adapters.SQL.raise_sql_call_error/1
      Feb 04 20:55:34 api boardr_api[15145]:         (ecto_sql 3.3.3) lib/ecto/adapters/sql.ex:521: Ecto.Adapters.SQL.insert_all/8
      Feb 04 20:55:34 api boardr_api[15145]:         (ecto 3.3.2) lib/ecto/repo/schema.ex:54: Ecto.Repo.Schema.do_insert_all/6
      Feb 04 20:55:34 api boardr_api[15145]:         (ecto 3.3.2) lib/ecto/association.ex:1202: Ecto.Association.ManyToMany.on_repo_change/5
      Feb 04 20:55:34 api boardr_api[15145]:         (ecto 3.3.2) lib/ecto/association.ex:477: anonymous fn/8 in Ecto.Association.on_repo_change/7
      Feb 04 20:55:34 api boardr_api[15145]:         (elixir 1.10.0) lib/enum.ex:2111: Enum."-reduce/3-lists^foldl/2-0-"/3
      Feb 04 20:55:34 api boardr_api[15145]:         (ecto 3.3.2) lib/ecto/association.ex:473: Ecto.Association.on_repo_change/7
      Feb 04 20:55:34 api boardr_api[15145]:         (elixir 1.10.0) lib/enum.ex:2111: Enum."-reduce/3-lists^foldl/2-0-"/3
* Investigate wrong_turn game_server load state error

      Feb 04 20:56:59 api boardr_api[15145]: 20:56:59.313 [error] Ranch protocol #PID<0.13483.2> of listener BoardrApi.Endpoint.HTTP (connection #PID<0.13482.2>, stream id 1) terminated
      Feb 04 20:56:59 api boardr_api[15145]: ** (exit) an exception was raised:
      Feb 04 20:56:59 api boardr_api[15145]:     ** (CaseClauseError) no case clause matching: {:error, {:game_error, :wrong_turn}}
      Feb 04 20:56:59 api boardr_api[15145]:         (boardr 0.1.0) lib/boardr/gaming/game_server.ex:437: anonymous fn/4 in Boardr.Gaming.GameServer.load_state_from_database/1
      Feb 04 20:56:59 api boardr_api[15145]:         (elixir 1.10.0) lib/enum.ex:2111: Enum."-reduce/3-lists^foldl/2-0-"/3
      Feb 04 20:56:59 api boardr_api[15145]:         (ecto_sql 3.3.3) lib/ecto/adapters/sql.ex:886: anonymous fn/3 in Ecto.Adapters.SQL.checkout_or_transaction/4
      Feb 04 20:56:59 api boardr_api[15145]:         (db_connection 2.2.0) lib/db_connection.ex:1427: DBConnection.run_transaction/4
      Feb 04 20:56:59 api boardr_api[15145]:         (boardr 0.1.0) lib/boardr/gaming/game_server.ex:416: Boardr.Gaming.GameServer.load_state_from_database/1
      Feb 04 20:56:59 api boardr_api[15145]:         (boardr 0.1.0) lib/boardr/gaming/game_server.ex:63: Boardr.Gaming.GameServer.handle_call/3
      Feb 04 20:56:59 api boardr_api[15145]:         (stdlib 3.11.1) gen_server.erl:661: :gen_server.try_handle_call/4
      Feb 04 20:56:59 api boardr_api[15145]:         (stdlib 3.11.1) gen_server.erl:690: :gen_server.handle_msg/6
* Fix FIXMEs & TODOs
* Create script to quickly perform demo

## Important

* Frontend
  * Deploy
  * Style
  * Stats page
    * REST operations executed by node
    * Number of game servers running by node
    * Number of swarm processes running by node
* Generate documentation
* Generate coverage
* Doctests
* README
  * `env.exs` file
    * Mix task to set up `env.exs` file
  * Helper scripts

## Nice-to-have

* Remove hardcoded secrets (including database)
* Optimize PostgreSQL
  * Configuration
  * Check indices
* bcrypt
* Google auth
* Websocket REST API
* More tests
* HAL browser
* Travis CI
* Coveralls
* Read Erlang book
