open Core
open Async

open Bittrex

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
