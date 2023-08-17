//+------------------------------------------------------------------+
//|                                                 StochFilter.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "Filter.mqh"
#include "../Util.mqh"

input string InpStochComment = ""; //--- Stochastic Filter ---

input bool InpUseStochFilter = true;
input ENUM_TIMEFRAMES InpStochTimeframe = PERIOD_H4;
input int InpStochKPeriod = 5;
input int InpStochDPeriod = 3;
input int InpStochSlowing = 3;
input int InpStochThreshold = 20;

input bool InpUseStochIsIncreasingFilter = true;

class StochFilter : public Filter {

private:
   int handleStoch;
   double bufferStoch[], bufferStochSignal[];

public:
   Util util;
   void Update();
   bool isOverbought();
   bool isOversold();
   bool isIncreasing();
   double GetCurrStoch();

   int StochFilter::HandleOnInit() override;
   
};

int StochFilter::HandleOnInit() override {
   ArraySetAsSeries(bufferStoch, true);
   
   handleStoch = iStochastic(InpSymbol, InpStochTimeframe, InpStochKPeriod, InpStochDPeriod, InpStochSlowing, MODE_SMA, STO_LOWHIGH);
   if (handleStoch < 0) {
      PrintFormat("Error creating Stoch indicator. retValue: %d, error: %d", handleStoch, GetLastError());
      return INIT_FAILED;
   }
   return INIT_SUCCEEDED;
}

void StochFilter::Update() {
   util.m_symbol.RefreshRates();

   if (CopyBuffer(handleStoch, 0, 0, 3, bufferStoch) <= 0) {
      Print("Getting Stoch is failed! Error ", GetLastError());
      return;
   }

   if (CopyBuffer(handleStoch, 1, 0, 3, bufferStochSignal) <= 0) {
      Print("Getting bufferStochSignal is failed! Error ", GetLastError());
      return;
   }
}

bool StochFilter::isOversold() {
   if (bufferStoch[1] <= InpStochThreshold && bufferStochSignal[1] > bufferStoch[1]) {
      return true;
   }
   return false;
}

bool StochFilter::isOverbought() {
   if (bufferStoch[1] >= 100 - InpStochThreshold && bufferStochSignal[1] < bufferStoch[1]) {
      return true;
   }
   return false;
}

bool StochFilter::isIncreasing() {
   if (bufferStoch[2] < bufferStoch[1]) {
      return true;
   }
   return false;
}

double StochFilter::GetCurrStoch() {
   return bufferStoch[1];
}

