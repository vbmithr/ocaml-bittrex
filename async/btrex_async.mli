open Core
open Async

open Btrex

module RestError : sig
  type t =
    | Cohttp of exn
    | Client of string
    | Server of string
    | Bittrex of string
    | Data_encoding

  val to_string : t -> string
end

val markets :
  ?buf : Bi_outbuf.t -> ?log:Log.t -> unit ->
  (Cohttp.Response.t * Market.t list, RestError.t) Deferred.Result.t

val currencies :
  ?buf : Bi_outbuf.t -> ?log:Log.t -> unit ->
  (Cohttp.Response.t * Currency.t list, RestError.t) Deferred.Result.t

val ticker :
  ?buf : Bi_outbuf.t -> ?log:Log.t -> string ->
  (Cohttp.Response.t * Ticker.t, RestError.t) Deferred.Result.t

val marketsummaries :
  ?buf : Bi_outbuf.t -> ?log:Log.t -> unit ->
  (Cohttp.Response.t * MarketSummary.t list, RestError.t) Deferred.Result.t

val marketsummary :
  ?buf : Bi_outbuf.t -> ?log:Log.t -> string ->
  (Cohttp.Response.t * MarketSummary.t list, RestError.t) Deferred.Result.t

val orderbook :
  ?buf : Bi_outbuf.t -> ?log:Log.t -> string ->
  (Cohttp.Response.t * OrderBook.t, RestError.t) Deferred.Result.t

val markethistory :
  ?buf : Bi_outbuf.t -> ?log:Log.t -> string ->
  (Cohttp.Response.t * MarketHistory.t list, RestError.t) Deferred.Result.t

val buylimit :
  ?buf : Bi_outbuf.t -> ?log:Log.t ->
  symbol:string -> price:float -> qty:float -> key:string -> secret:string -> unit ->
  (Cohttp.Response.t * Uuidm.t, RestError.t) Deferred.Result.t

val selllimit :
  ?buf : Bi_outbuf.t -> ?log:Log.t ->
  symbol:string -> price:float -> qty:float -> key:string -> secret:string -> unit ->
  (Cohttp.Response.t * Uuidm.t, RestError.t) Deferred.Result.t

val cancel :
  ?buf : Bi_outbuf.t -> ?log:Log.t -> key:string -> secret:string -> Uuidm.t ->
  (Cohttp.Response.t * unit, RestError.t) Deferred.Result.t

val openorders :
  ?buf : Bi_outbuf.t -> ?log:Log.t -> ?symbol:string ->
  key:string -> secret:string -> unit ->
  (Cohttp.Response.t * Yojson.Safe.json list, RestError.t) Deferred.Result.t

val orderhistory :
  ?buf : Bi_outbuf.t -> ?log:Log.t -> ?symbol:string ->
  key:string -> secret:string -> unit ->
  (Cohttp.Response.t * Yojson.Safe.json list, RestError.t) Deferred.Result.t
