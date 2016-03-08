-module(octo_http_helper_test).
-include_lib("eunit/include/eunit.hrl").
-include("include/octo.hrl").

options_to_query_params_test_() ->
  {inparallel,
   [?_assertEqual(
      "",
      octo_http_helper:options_to_query_params([])),
    ?_assertEqual(
      "per_page=100",
      octo_http_helper:options_to_query_params([{per_page, 100}])),
    ?_assertEqual(
      "page=2",
      octo_http_helper:options_to_query_params([{page, 2}])),
    ?_assertEqual(
      "per_page=100&page=2",
      octo_http_helper:options_to_query_params([{per_page, 100}, {page, 2}])),
    ?_assertEqual(
      "per_page=100&page=2",
      octo_http_helper:options_to_query_params([{per_page, 100}, hi, {page, 2}]))
   ]}.

ternary_fns_test_() ->
  Url = "http://example.com",
  Body = "empty!",

  {setup,
   fun() ->
       ok = meck:new(hackney),
       meck:expect(hackney, start, fun() -> ok end)
   end,
   fun(_) -> ok = meck:unload(hackney) end,
   [fun() ->
      meck:expect(hackney, request,
                  fun(M, U, "", <<>>, "") when M == Method, U =:= Url ->
                      {ok, Status, undef, undef}
                  end),
      meck:expect(hackney, body, fun(undef) -> {ok, Body} end),

      ?assertEqual(
         {StatusTerm, Body},
         apply(octo_http_helper, Method, [Url, [], <<>>])
      ),
      ?assert(meck:validate(hackney))
    end
    ||
    Method <- [post, put, patch],
    {Status, StatusTerm} <- [{200, ok}, {404, err}]]}.

get_test_() ->
  Url = "http://example.com",
  Body = "empty!",

  {setup,
   fun() ->
       ok = meck:new(hackney),
       meck:expect(hackney, start, fun() -> ok end)
   end,
   fun(_) -> ok = meck:unload(hackney) end,
   [fun() ->
      meck:expect(hackney, request,
                  fun(get, U, "", <<>>, "") when U =:= Url ->
                      {ok, Status, undef, undef}
                  end),
      meck:expect(hackney, body, fun(undef) -> {ok, Body} end),

      ?assertEqual(
         {StatusTerm, Body},
         octo_http_helper:get(Url, [])
      ),
      ?assert(meck:validate(hackney))
    end
    ||
    {Status, StatusTerm} <- [{200, ok}, {404, err}]]}.

delete_test_() ->
  Url = "http://example.com",

  {setup,
   fun() ->
       ok = meck:new(hackney),
       meck:expect(hackney, start, fun() -> ok end)
   end,
   fun(_) -> ok = meck:unload(hackney) end,
   [fun() ->
      meck:expect(hackney, request,
                  fun(delete, U, "", <<>>, "") when U =:= Url ->
                      {ok, Status, undef, undef}
                  end),

      ?assertEqual(
         {StatusTerm, null},
         octo_http_helper:delete(Url, [])
      ),
      ?assert(meck:validate(hackney))
    end
    ||
    {Status, StatusTerm} <- [{200, ok}, {404, err}]]}.

get_response_status_code_test_() ->
  Url = "http://example.com",

  {setup,
   fun() ->
       ok = meck:new(hackney),
       meck:expect(hackney, start, fun() -> ok end)
   end,
   fun(_) -> ok = meck:unload(hackney) end,
   [fun() ->
      meck:expect(hackney, request,
                  fun(get, U, "", <<>>, "") when U =:= Url ->
                      {ok, StatusCode, undef, undef}
                  end),

      ?assertEqual(
         StatusCode,
         octo_http_helper:get_response_status_code(Url, [])
      ),
      ?assert(meck:validate(hackney))
    end
    ||
    StatusCode <- [200, 404]]}.

read_collection_test_() ->
  Owner = "testuser",
  Repo = "testrepo",
  PRNumber = 42,
  Options = [],

  {setup,
   fun() ->
       ok = meck:new(hackney),
       meck:expect(hackney, start, fun() -> ok end)
   end,
   fun(_) -> ok = meck:unload(hackney) end,
   [fun() ->
        meck:expect(hackney, request,
                    fun(get, U, "", <<>>, "") when U =:= Url ->
                        {ok, 200, undef, clientref}
                    end),
        meck:expect(hackney, body,
                    fun(clientref) ->
                        {ok, <<"{\"id\": 1}">>}
                    end),

        ?assertEqual(
           {{<<"id">>, 1}},
           octo_http_helper:read_collection(Thing, Args, Options)),
        ?assert(meck:validate(hackney))
    end
    ||
    {Thing, Args, Url} <-
    [{pull_request,
      [Owner, Repo, PRNumber],
      "https://api.github.com/repos/testuser/testrepo/pulls/42?"},

     {pull_request_commits,
      [Owner, Repo, PRNumber],
      "https://api.github.com/repos/testuser/testrepo/pulls/42/commits?"},

     {pull_request_files,
      [Owner, Repo, PRNumber],
      "https://api.github.com/repos/testuser/testrepo/pulls/42/files?"}]
   ]}.
