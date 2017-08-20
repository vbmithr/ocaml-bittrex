module BTResult : sig
  exception BittrexError of string

  val encoding : 'a Json_encoding.encoding -> 'a Json_encoding.encoding
  (** [encoding t_encoding] extracts [t] or fails with
      BittrexError otherwise. *)
end

module Market : sig
  type t = {
    symbol : string ;
    quote : string ;
    base : string ;
    quote_descr : string ;
    base_descr : string ;
    ticksize : float ;
    active : bool ;
    created : Ptime.t ;
  }

  val encoding : t Json_encoding.encoding
end

module Currency : sig
  type t = {
    name : string ;
    descr : string ;
    min_confirmations : int ;
    fee : float ;
    active : bool ;
  }

  val encoding : t Json_encoding.encoding
end

module Ticker : sig
    type t = {
    bid : float ;
    ask : float ;
    last : float ;
  }

  val encoding : t Json_encoding.encoding
end

module MarketSummary : sig
    type t = {
    symbol : string ;
    high : float ;
    low : float ;
    volume : float ;
    last : float ;
    base_volume : float ;
    timestamp : Ptime.t ;
    bid : float ;
    ask : float ;
    open_buy_orders : int ;
    open_sell_orders : int ;
    prev_day : float ;
    created : Ptime.t ;
  }

  val encoding : t Json_encoding.encoding
end

module OrderBook : sig
  type entry = {
    price : float ;
    qty : float ;
  }

  type t = {
    buy : entry list ;
    sell : entry list ;
  }

  val encoding : t Json_encoding.encoding
end

module Side : sig
  type t = [
    | `buy
    | `sell
    | `buy_sell_unset
  ] [@@deriving sexp]
end

module OrdStatus : sig
  type t = [
    | `order_status_filled
    | `order_status_partially_filled
  ]
end

module MarketHistory : sig
  type t = {
    id : int ;
    timestamp : Ptime.t ;
    qty : float ;
    price : float ;
    total : float ;
    ordStatus : OrdStatus.t ;
    side : Side.t ;
  }

  val compare : t -> t -> int
  val encoding : t Json_encoding.encoding
end

module OrderID : sig
  type t = Uuidm.t

  val encoding : t Json_encoding.encoding
end

module Balance : sig
  type t = {
    currency : string ;
    balance : float ;
    available : float ;
    pending : float ;
    address : string ;
    requested : bool ;
    uuid : Uuidm.t option ;
  }
end
