/*
 * Copyright (c) 2019-2020 ThoughtWorks Inc.
 */

#include "../include/order_store_influxdb.h"

#include <cdcf/logger.h>

#include "../../common/include/influxdb.hpp"

OrderStoreInfluxDB::OrderStoreInfluxDB(const std::string& host, int port)
    : host_(host), port_(port) {
  std::string resp;
  int ret;

  if (host_ == "localhost") {
    host_ = "127.0.0.1";
  }

  influxdb_cpp::server_info si(host_, port_, "", "", "");
  ret = influxdb_cpp::create_db(resp, "order_manager", si);
  if (0 != ret) {
    CDCF_LOGGER_ERROR("create database of order_manager failed ret: {}", ret);
  }
}

int OrderStoreInfluxDB::PersistOrder(const match_engine_proto::Order& order,
                                     std::string status, int concluded_amount) {
  influxdb_cpp::server_info si(host_, port_, "order_manager", "", "");
  std::string resp;

  std::string trading_side;
  if (order.trading_side() == match_engine_proto::TRADING_BUY) {
    trading_side = "buy";
  } else if (order.trading_side() == match_engine_proto::TRADING_SELL) {
    trading_side = "sell";
  } else {
    trading_side = "unknown";
  }

  int ret = influxdb_cpp::builder()
                .meas("order")
                .tag("order_id", std::to_string(order.order_id()))
                .tag("symbol_id", std::to_string(order.symbol_id()))
                .field("user_id", order.user_id())
                .field("price", order.price())
                .field("amount", order.amount())
                .field("trading_side", trading_side)
                .field("status", std::string(status))
                .field("concluded amount", concluded_amount)
                .timestamp(order.submit_time())
                .post_http(si, &resp);

  if (0 == ret && resp.empty()) {
    CDCF_LOGGER_DEBUG("write db success");
  } else {
    CDCF_LOGGER_ERROR("write db failed, ret: {}", resp);
  }

  return ret;
}
