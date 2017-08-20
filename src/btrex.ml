module Encoding = struct
  let timestamp =
    let open Json_encoding in
    let of_rfc3339_exn s = match Ptime.of_rfc3339 (s ^ "Z") with
      | Ok (t, _, _) -> t
      | Error _ -> invalid_arg "Ptime.of_rfc3339" in
    conv Ptime.to_rfc3339 of_rfc3339_exn string

  let uint =
    Json_encoding.ranged_int ~minimum:0 ~maximum:max_int "uint"

  let uuid =
    let open Json_encoding in
    let string_of_uuid s =
      match Uuidm.of_string s with
      | Some uuid -> uuid
      | None -> invalid_arg "Uuidm.of_string" in
    conv (Uuidm.to_string ~upper:false) string_of_uuid string
end

module BTResult = struct
  exception BittrexError of string

  let encoding result_encoding =
    let open Json_encoding in
    conv
      (fun _ -> failwith "BTResult.encoding: not implemented")
      (fun (success, msg, result) ->
         match success, result with
         | true, Some result -> result
         | true, None ->
           raise (BittrexError "Command successful but no result returned")
         | false, _ ->
           raise (BittrexError msg))
      (obj3
         (req "success" bool)
         (req "message" string)
         (opt "result" result_encoding))
end

module Market = struct
  type t = {
    quote : string ;
    base : string ;
    quote_descr : string ;
    base_descr : string ;
    ticksize : float ;
    active : bool ;
    created : Ptime.t ;
  }

  let encoding =
    let open Json_encoding in
    conv
      (fun _ -> failwith "Market.encoding: not implemented")
      (fun ((), (quote, base, quote_descr, base_descr, ticksize, active, created)) ->
         { quote ; base ; quote_descr ; base_descr ; ticksize ; active ; created })
      (merge_objs unit
         ((obj7
             (req "MarketCurrency" string)
             (req "BaseCurrency" string)
             (req "MarketCurrencyLong" string)
             (req "BaseCurrencyLong" string)
             (req "MinTradeSize" float)
             (req "IsActive" bool)
             (req "Created" Encoding.timestamp))))
end

module Currency = struct
  type t = {
    name : string ;
    descr : string ;
    min_confirmations : int ;
    fee : float ;
    active : bool ;
  }

  let encoding =
    let open Json_encoding in
    conv
      (fun _ -> failwith "Currency.encoding: not implemented")
      (fun ((), (name, descr, min_confirmations, fee, active)) ->
         { name ; descr ; min_confirmations ; fee ; active })
      (merge_objs unit
         (obj5
            (req "Currency" string)
            (req "CurrencyLong" string)
            (req "MinConfirmation" int)
            (req "TxFee" float)
            (req "IsActive" bool)))
end

module Ticker = struct
  type t = {
    bid : float ;
    ask : float ;
    last : float ;
  }

  let encoding =
    let open Json_encoding in
    conv
      (fun _ -> failwith "Ticker.encoding: not implemented")
      (fun (bid, ask, last) -> { bid ; ask ; last })
      (obj3
         (req "Bid" float)
         (req "Ask" float)
         (req "Last" float))
end

module MarketSummary = struct
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

  let encoding =
    let open Json_encoding in
    conv
      (fun _ -> failwith "MarketSummary.encoding: not implemented")
      (fun ((), ((symbol, high, low, volume, last, base_volume, timestamp),
                 (bid, ask, open_buy_orders, open_sell_orders, prev_day, created))) ->
        { symbol ; high ; low ; volume ; last ; base_volume ; timestamp ;
          bid ; ask ; open_buy_orders ; open_sell_orders ; prev_day ; created })
      (merge_objs unit
         (merge_objs
            (obj7
               (req "MarketName" string)
               (req "High" float)
               (req "Low" float)
               (req "Volume" float)
               (req "Last" float)
               (req "BaseVolume" float)
               (req "TimeStamp" Encoding.timestamp))
            (obj6
               (req "Bid" float)
               (req "Ask" float)
               (req "OpenBuyOrders" int)
               (req "OpenSellOrders" int)
               (req "PrevDay" float)
               (req "Created" Encoding.timestamp))))
end

module OrderBook = struct
  type entry = {
    price : float ;
    qty : float ;
  }

  let entry_encoding =
    let open Json_encoding in
    conv
      (fun _ -> failwith "OrderBook.entry_encoding: not implemented")
      (fun (qty, price) -> { qty ; price })
      (obj2
         (req "Quantity" float)
         (req "Rate" float))

  type t = {
    buy : entry list ;
    sell : entry list ;
  }

  let encoding =
    let open Json_encoding in
    conv
      (fun _ -> failwith "OrderBook.encoding: not implemented")
      (fun (buy, sell) -> { buy ; sell })
      (obj2
         (req "buy" (list entry_encoding))
         (req "sell" (list entry_encoding)))
end

module Side = struct
  type t = [
    | `buy
    | `sell
    | `buy_sell_unset
  ] [@@deriving sexp]

  let to_string = function
    | `buy -> "BUY"
    | `sell -> "SELL"
    | `buy_sell_unset -> ""

  let of_string = function
    | "BUY" -> `buy
    | "SELL" -> `sell
    | _ -> invalid_arg "Side.of_string"

  let encoding =
    let open Json_encoding in
    string_enum [
      "BUY", `buy ;
      "SELL", `sell ;
    ]
end

module OrdStatus = struct
  type t = [
    | `order_status_filled
    | `order_status_partially_filled
  ]

  let encoding =
    let open Json_encoding in
    string_enum [
      "FILL", `order_status_filled ;
      "PARTIAL_FILL", `order_status_partially_filled ;
    ]
end

module MarketHistory = struct
  type t = {
    id : int ;
    timestamp : Ptime.t ;
    qty : float ;
    price : float ;
    total : float ;
    ordStatus : OrdStatus.t ;
    side : Side.t ;
  }

  let compare { id } { id = id' } =
    if id > id' then 1
    else if id < id' then -1
    else 0

  let encoding =
    let open Json_encoding in
    conv
      (fun _ -> failwith "MarketHistory.entry_encoding: not implemented")
      (fun (id, timestamp, qty, price, total, ordStatus, side) ->
         { id ; timestamp ; qty ; price ; total ; ordStatus ; side })
      (obj7
         (req "Id" Encoding.uint)
         (req "TimeStamp" Encoding.timestamp)
         (req "Quantity" float)
         (req "Price" float)
         (req "Total" float)
         (req "FillType" OrdStatus.encoding)
         (req "OrderType" Side.encoding))
end

module Order = struct
  type t = Uuidm.t

  let encoding =
    let open Json_encoding in
    conv
      (fun u -> u)
      (fun u -> u)
      (obj1
        (req "uuid" Encoding.uuid))
end
