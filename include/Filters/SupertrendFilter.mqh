//+------------------------------------------------------------------+
//|                                                 SupertrendFilter.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "Filter.mqh"
#include "../Util.mqh"

input bool InpUseSupertrendFilter = true;
input int InpSupertrendPeriod = 14;
input double InpSupertrendMultiplier = 3.0;

class SupertrendFilter : public Filter {

private:
   int handleSupertrend;
   double bufferSupertrend[];

public:
   Util util;
   void Update();
   bool isBullish();
   bool isBearish();

   int SupertrendFilter::HandleOnInit() override;
};

int SupertrendFilter::HandleOnInit() override {
   ArraySetAsSeries(bufferSupertrend, true);
   
   handleSupertrend = iCustom(InpSymbol, InpTimeframe, "Market/Supertrend Line", InpSupertrendPeriod, InpSupertrendMultiplier);
   if (handleSupertrend < 0) {
      PrintFormat("Error creating Supertrend indicator. retValue: %d, error: %d", handleSupertrend, GetLastError());
      return INIT_FAILED;
   }
   return INIT_SUCCEEDED;
}

void SupertrendFilter::Update() {
   util.m_symbol.RefreshRates();
   
   if (CopyBuffer(handleSupertrend, 0, 0, 2, bufferSupertrend) <= 0) {
      Print("Getting Supertrend is failed! Error ", GetLastError());
      return;
   }
}

bool SupertrendFilter::isBullish() {
   if (bufferSupertrend[1] <= util.m_symbol.Bid()) {
      return true;
   }
   return false;
}

bool SupertrendFilter::isBearish() {
   if (bufferSupertrend[1] >= util.m_symbol.Ask()) {
      return true;
   }
   return false;
}
