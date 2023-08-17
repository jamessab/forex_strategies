//+------------------------------------------------------------------+
//|                                                 RSIFilter.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "Filter.mqh"
#include "../Util.mqh"

input string InpRSIComment = ""; //--- RSI Filter ---
input bool InpUseRSIFilter = true;
input ENUM_TIMEFRAMES InpRSITimeframe = PERIOD_H4;
input int InpRSIPeriod = 14;
input int InpRSIThreshold = 30;
input int InpRSIThresholdEntry = 32;

input bool InpUseRSIIsIncreasingFilter = true;

class RSIFilter : public Filter {

private:
   int handleRSI;
   double bufferRSI[];

public:
   Util util;
   void Update();
   bool isOverbought(int entryOrLater);
   bool isOversold(int entryOrLater);
   bool isIncreasing();
   double GetCurrRSI();
   
   int RSIFilter::HandleOnInit() override;
};

int RSIFilter::HandleOnInit() override {
   ArraySetAsSeries(bufferRSI, true);
   
   handleRSI = iRSI(InpSymbol, InpStochTimeframe, InpRSIPeriod, PRICE_CLOSE);
   if (handleRSI < 0) {
      PrintFormat("Error creating RSI indicator. retValue: %d, error: %d", handleRSI, GetLastError());
      return INIT_FAILED;
   }
   return INIT_SUCCEEDED;
}

void RSIFilter::Update() {
   util.m_symbol.RefreshRates();
   
   if (CopyBuffer(handleRSI, 0, 0, 3, bufferRSI) <= 0) {
      Print("Getting RSI is failed! Error ", GetLastError());
      return;
   }
}

bool RSIFilter::isOversold(int entryOrLater) {
   if (entryOrLater == 0) {
      if (bufferRSI[1] <= InpRSIThresholdEntry) {
         return true;
      }
   }
   else {
      if (bufferRSI[1] <= InpRSIThreshold) {
         return true;
      }
   }
   return false;
}

bool RSIFilter::isOverbought(int entryOrLater) {
   if (entryOrLater == 0) {
      if (bufferRSI[1] >= 100 - InpRSIThresholdEntry) {
         return true;
      }
   }
   else {
      if (bufferRSI[1] >= 100 - InpRSIThreshold) {
         return true;
      }
   }
   
   return false;
}

bool RSIFilter::isIncreasing() {
   if (bufferRSI[2] < bufferRSI[1]) {
      return true;
   }
   return false;
}

double RSIFilter::GetCurrRSI() {
   return bufferRSI[1];
}

