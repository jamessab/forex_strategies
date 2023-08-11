//+------------------------------------------------------------------+
//|                                                 SpreadFilter.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "Filter.mqh"
#include "../Util.mqh"

input double InpMaxSpreadInPoints = 10;

class SpreadFilter : public Filter {
public:
   Util util;
   int SpreadFilter::HandleOnInit() override;
   bool SpreadFilter::passes() override;
};

int SpreadFilter::HandleOnInit() override {
   return INIT_SUCCEEDED;
}

bool SpreadFilter::passes() override {
   if ((util.m_symbol.Ask() - util.m_symbol.Bid()) > InpMaxSpreadInPoints * Point()) {
      return false;
   }
   return true;
}
