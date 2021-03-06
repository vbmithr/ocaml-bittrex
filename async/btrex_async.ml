open Core
open Async

open Btrex

open Cohttp_async

exception ClientError of string
exception ServerError of string

let ssl_config = Conduit_async.Ssl.configure ~version:Tlsv1_2 ()

module RestError = struct
  type t =
    | Cohttp of exn
    | Client of string
    | Server of string
    | Bittrex of string
    | Data_encoding

  let to_string = function
    | Cohttp exn -> Exn.to_string exn
    | Client msg -> "HTTP Client error: " ^ msg
    | Server msg -> "HTTP Server error: " ^ msg
    | Bittrex msg -> "Bittrex error: " ^ msg
    | Data_encoding -> "Data encoding error"
end

module Yojson_encoding = struct
  include Json_encoding.Make(Json_repr.Yojson)

  let destruct_safe encoding value =
    try destruct encoding value with exn ->
      let value_str = Yojson.Safe.to_string value in
      Format.eprintf "%s@.%a@." value_str
        (Json_encoding.print_error ?print_unknown:None) exn ;
      raise exn
end

let safe_get ?(headers=Cohttp.Header.init ()) ?buf ?log url =
  Monitor.try_with ~extract_exn:true begin fun () ->
    Client.get ~ssl_config url >>= fun (resp, body) ->
    let status_code = Cohttp.Code.code_of_status resp.status in
    Body.to_string body >>| fun body_str ->
    Option.iter log ~f:(fun log -> Log.debug log "%s" body_str) ;
    if Cohttp.Code.is_client_error status_code then
      raise (ClientError body_str)
    else if Cohttp.Code.is_server_error status_code then
      raise (ServerError body_str)
    else
      resp, Yojson.Safe.from_string ?buf body_str
  end >>| Result.map_error ~f:begin function
    | ClientError str -> RestError.Client str
    | ServerError str -> Server str
    | exn -> Cohttp exn
  end

let sign ~key ~secret uri =
  let module SHA512 = Digestif.SHA512.Bytes in
  let nonce = Time_ns.(now () |> to_int_ns_since_epoch) / 1_000 in
  let query =
    ("apikey", [key]) :: ("nonce", [Int.to_string nonce]) :: Uri.query uri in
  let uri = Uri.with_query uri query in
  uri,
  Cohttp.Header.init_with "apisign" (SHA512.hmac ~key:secret (Uri.to_string uri))

let call ?auth ?buf ?log url encoding =
  let url, headers =
  match auth with
  | None -> url, Cohttp.Header.init ()
  | Some (key, secret) -> sign ~key ~secret url in
  safe_get ?buf ?log ~headers url >>| function
  | Error err -> Error err
  | Ok (resp, json) -> try
      Ok (resp, (Yojson_encoding.destruct_safe
                   (BTResult.encoding encoding) json))
    with
    | BTResult.BittrexError msg -> Error (Bittrex msg)
    | _ -> Error Data_encoding

let markets ?buf ?log () =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/public/getmarkets" in
  call ?buf ?log url (Json_encoding.list Market.encoding)

let currencies ?buf ?log () =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/public/getcurrencies" in
  call ?buf ?log url (Json_encoding.list Currency.encoding)

let ticker ?buf ?log symbol =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/public/getticker" in
  let url = Uri.with_query' url ["market", symbol] in
  call ?buf ?log url Ticker.encoding

let marketsummaries ?buf ?log () =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/public/getmarketsummaries" in
  call ?buf ?log url (Json_encoding.list MarketSummary.encoding)

let marketsummary ?buf ?log symbol =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/public/getmarketsummary" in
  let url = Uri.with_query' url ["market", symbol] in
  call ?buf ?log url (Json_encoding.list MarketSummary.encoding)

let orderbook ?buf ?log symbol =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/public/getorderbook" in
  let url = Uri.with_query' url ["market", symbol ; "type", "both"] in
  call ?buf ?log url OrderBook.encoding

let markethistory ?buf ?log symbol =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/public/getmarkethistory" in
  let url = Uri.with_query' url ["market", symbol] in
  call ?buf ?log url (Json_encoding.list MarketHistory.encoding)

let buylimit ?buf ?log ~symbol ~price ~qty ~key ~secret () =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/market/buylimit" in
  let url = Uri.with_query' url [
      "market", symbol ;
      "quantity", Float.to_string qty ;
      "rate", Float.to_string price ;
    ] in
  call ~auth:(key, secret) ?buf ?log url OrderID.encoding

let selllimit ?buf ?log ~symbol ~price ~qty ~key ~secret () =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/market/selllimit" in
  let url = Uri.with_query' url [
      "market", symbol ;
      "quantity", Float.to_string qty ;
      "rate", Float.to_string price ;
    ] in
  call ~auth:(key, secret) ?buf ?log url OrderID.encoding

let cancel ?buf ?log ~key ~secret orderID =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/market/selllimit" in
  let url = Uri.with_query' url [
      "uuid", Uuidm.to_string orderID ;
    ] in
  call ~auth:(key, secret) ?buf ?log url Json_encoding.null

let openorders ?buf ?log ?symbol ~key ~secret () =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/market/getopenorders" in
  let url = Uri.with_query' url (List.filter_opt [
      Option.map symbol ~f:(fun symbol -> "market", symbol) ;
    ]) in
  call ~auth:(key, secret) ?buf ?log url Json_encoding.any_value >>|
  Result.bind ~f:begin fun (resp, json) ->
    match Json_repr.(any_to_repr (module Yojson) json) with
    | `List orders ->
      Result.return (resp, orders)
    | #Yojson.Safe.json ->
      Result.fail (RestError.Bittrex "openorders: list expected")
  end

let orderhistory ?buf ?log ?symbol ~key ~secret () =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/account/getorderhistory" in
  let url = Uri.with_query' url (List.filter_opt [
      Option.map symbol ~f:(fun symbol -> "market", symbol) ;
    ]) in
  call ~auth:(key, secret) ?buf ?log url Json_encoding.any_value >>|
  Result.bind ~f:begin fun (resp, json) ->
    match Json_repr.(any_to_repr (module Yojson) json) with
    | `List orders ->
      Result.return (resp, orders)
    | #Yojson.Safe.json ->
      Result.fail (RestError.Bittrex "orderhistory: list expected")
  end

let balances ?buf ?log ~key ~secret () =
  let url = Uri.of_string "https://bittrex.com/api/v1.1/account/getbalances" in
  call ~auth:(key, secret) ?buf ?log url (Json_encoding.list Balance.encoding)
