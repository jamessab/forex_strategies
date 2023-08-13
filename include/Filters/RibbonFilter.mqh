//+------------------------------------------------------------------+
//|                                                 RibbonFilter.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "Filter.mqh"
#include "../Util.mqh"

input bool InpUseRibbonPriceOutsideRibbonFilter = true;
input bool InpUseRibbonStackedFilter = true;

input ENUM_MA_METHOD InpRibbonMode = MODE_EMA;
input int InpRibbon1Period = 10;
input int InpRibbon2Period = 20;
input int InpRibbon3Period = 30;
input int InpRibbon4Period = 40;
input int InpRibbon5Period = 50;
input int InpRibbon6Period = 60;
input int InpRibbon7Period = 70;

class RibbonFilter : public Filter {

private:
   int handleRibbon;
   double bufferRibbon1[], bufferRibbon2[], bufferRibbon3[], bufferRibbon4[], 
      bufferRibbon5[], bufferRibbon6[], bufferRibbon7[], bufferRibbon8[];

public:
   Util util;
   void Update();

   int RibbonFilter::HandleOnInit() override;
   bool RibbonFilter::IsPriceAboveRibbon();
   bool RibbonFilter::IsPriceBelowRibbon();
   bool RibbonFilter::IsRibbonStackedBullish();
   bool RibbonFilter::IsRibbonStackedBearish();

};

int RibbonFilter::HandleOnInit() override {
   ArraySetAsSeries(bufferRibbon1, true);
   ArraySetAsSeries(bufferRibbon2, true);
   ArraySetAsSeries(bufferRibbon3, true);
   ArraySetAsSeries(bufferRibbon4, true);
   ArraySetAsSeries(bufferRibbon5, true);
   ArraySetAsSeries(bufferRibbon6, true);
   ArraySetAsSeries(bufferRibbon7, true);

   handleRibbon = iCustom(InpSymbol, InpTimeframe, "MultiMA", 
      "", InpRibbon1Period, InpRibbonMode, 0, clrRed, PRICE_CLOSE, 1, (InpRibbon1Period == -1 ? 0 : 1),
      "", InpRibbon2Period, InpRibbonMode, 0, clrRed, PRICE_CLOSE, 1, (InpRibbon2Period == -1 ? 0 : 1),
      "", InpRibbon3Period, InpRibbonMode, 0, clrRed, PRICE_CLOSE, 1, (InpRibbon3Period == -1 ? 0 : 1),
      "", InpRibbon4Period, InpRibbonMode, 0, clrRed, PRICE_CLOSE, 1, (InpRibbon4Period == -1 ? 0 : 1),
      "", InpRibbon5Period, InpRibbonMode, 0, clrRed, PRICE_CLOSE, 1, (InpRibbon5Period == -1 ? 0 : 1),
      "", InpRibbon6Period, InpRibbonMode, 0, clrRed, PRICE_CLOSE, 1, (InpRibbon6Period == -1 ? 0 : 1),
      "", InpRibbon7Period, InpRibbonMode, 0, clrRed, PRICE_CLOSE, 1, (InpRibbon7Period == -1 ? 0 : 1)
   );
   
   if (handleRibbon < 0) {
      PrintFormat("Error creating Ribbon indicator. retValue: %d, error: %d", handleRibbon, GetLastError());
      return INIT_FAILED;
   }
   return INIT_SUCCEEDED;
}

void RibbonFilter::Update() {
   util.m_symbol.RefreshRates();
   
   if (CopyBuffer(handleRibbon, 0, 0, 2, bufferRibbon1) <= 0) {
      Print("Getting Ribbon1 is failed! Error ", GetLastError());
      return;
   }
   
   if (CopyBuffer(handleRibbon, 1, 0, 2, bufferRibbon2) <= 0) {
      Print("Getting Ribbon2 is failed! Error ", GetLastError());
      return;
   }
   
   if (CopyBuffer(handleRibbon, 2, 0, 2, bufferRibbon3) <= 0) {
      Print("Getting Ribbon3 is failed! Error ", GetLastError());
      return;
   }
   
   if (CopyBuffer(handleRibbon, 3, 0, 2, bufferRibbon4) <= 0) {
      Print("Getting Ribbon4 is failed! Error ", GetLastError());
      return;
   }
   
   if (CopyBuffer(handleRibbon, 4, 0, 2, bufferRibbon5) <= 0) {
      Print("Getting Ribbon5 is failed! Error ", GetLastError());
      return;
   }
   
   if (CopyBuffer(handleRibbon, 5, 0, 2, bufferRibbon6) <= 0) {
      Print("Getting Ribbon6 is failed! Error ", GetLastError());
      return;
   }
   
   if (CopyBuffer(handleRibbon, 6, 0, 2, bufferRibbon7) <= 0) {
      Print("Getting Ribbon7 is failed! Error ", GetLastError());
      return;
   }
}

bool RibbonFilter::IsPriceAboveRibbon() {
   if (util.m_symbol.Ask() > bufferRibbon1[1] &&
      util.m_symbol.Ask() > bufferRibbon2[1] &&
      util.m_symbol.Ask() > bufferRibbon3[1] &&
      util.m_symbol.Ask() > bufferRibbon4[1] &&
      util.m_symbol.Ask() > bufferRibbon5[1] &&
      util.m_symbol.Ask() > bufferRibbon6[1] &&
      util.m_symbol.Ask() > bufferRibbon7[1]
   ) {
      return true;
   }
   
   return false;
}

bool RibbonFilter::IsPriceBelowRibbon() {
   if (util.m_symbol.Ask() < bufferRibbon1[1] &&
      util.m_symbol.Ask() < bufferRibbon2[1] &&
      util.m_symbol.Ask() < bufferRibbon3[1] &&
      util.m_symbol.Ask() < bufferRibbon4[1] &&
      util.m_symbol.Ask() < bufferRibbon5[1] &&
      util.m_symbol.Ask() < bufferRibbon6[1] &&
      util.m_symbol.Ask() < bufferRibbon7[1]
   ) {
      return true;
   }
   
   return false;
}

bool RibbonFilter::IsRibbonStackedBullish() {
   if (bufferRibbon1[1] > bufferRibbon2[1] &&
      bufferRibbon2[1] > bufferRibbon3[1] &&
      bufferRibbon3[1] > bufferRibbon4[1] &&
      bufferRibbon4[1] > bufferRibbon5[1] &&
      bufferRibbon5[1] > bufferRibbon6[1] &&
      bufferRibbon6[1] > bufferRibbon7[1]
   ) {
      return true;
   }
   
   return false;
}

bool RibbonFilter::IsRibbonStackedBearish() {
   if (bufferRibbon1[1] < bufferRibbon2[1] &&
      bufferRibbon2[1] < bufferRibbon3[1] &&
      bufferRibbon3[1] < bufferRibbon4[1] &&
      bufferRibbon4[1] < bufferRibbon5[1] &&
      bufferRibbon5[1] < bufferRibbon6[1] &&
      bufferRibbon6[1] < bufferRibbon7[1]
   ) {
      return true;
   }
   
   return false;
}

