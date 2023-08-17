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

input string InpRibbonComment = ""; //--- Ribbon Filter ---

input bool InpUseRibbonPriceOutsideRibbonFilter = true;
input bool InpUseRibbonStackedFilter = false;
input bool InpUseRibbonRecentlyNotStacked = false;

input ENUM_MA_METHOD InpRibbonMode = MODE_EMA;
input ENUM_TIMEFRAMES InpRibbonTimeframe = PERIOD_H4;
input int InpRibbon1Period = 10;
input int InpRibbon2Period = 20;
input int InpRibbon3Period = 30;
input int InpRibbon4Period = 40;
input int InpRibbon5Period = 50;
input int InpRibbon6Period = 60;
input int InpRibbon7Period = 70;
input int InpRibbon8Period = 80;

class RibbonFilter : public Filter {

private:
   int handleRibbon1, handleRibbon2, handleRibbon3, handleRibbon4, handleRibbon5, handleRibbon6, handleRibbon7, handleRibbon8;
   double bufferRibbon1[], bufferRibbon2[], bufferRibbon3[], bufferRibbon4[], 
      bufferRibbon5[], bufferRibbon6[], bufferRibbon7[], bufferRibbon8[];

public:
   Util util;
   void Update();

   int RibbonFilter::HandleOnInit() override;
   bool RibbonFilter::IsPriceAboveRibbon();
   bool RibbonFilter::IsPriceBelowRibbon();
   bool RibbonFilter::IsRibbonStackedBullish(int offset);
   bool RibbonFilter::IsRibbonStackedBearish(int offset);
   bool RibbonFilter::IsRecentlyNotStacked();
   double RibbonFilter::GetMA1();
};

int RibbonFilter::HandleOnInit() override {
   ArraySetAsSeries(bufferRibbon1, true);
   ArraySetAsSeries(bufferRibbon2, true);
   ArraySetAsSeries(bufferRibbon3, true);
   ArraySetAsSeries(bufferRibbon4, true);
   ArraySetAsSeries(bufferRibbon5, true);
   ArraySetAsSeries(bufferRibbon6, true);
   ArraySetAsSeries(bufferRibbon7, true);
   ArraySetAsSeries(bufferRibbon8, true);

   handleRibbon1 = iMA(InpSymbol, InpTimeframe, InpRibbon1Period, 0, InpRibbonMode, PRICE_CLOSE);
   if (handleRibbon1 < 0) {
      PrintFormat("Error creating handleRibbon1 indicator. retValue: %d, error: %d", handleRibbon1, GetLastError());
      return INIT_FAILED;
   }
   
   if (InpRibbon2Period > 0) {
      handleRibbon2 = iMA(InpSymbol, InpTimeframe, InpRibbon2Period, 0, InpRibbonMode, PRICE_CLOSE);
      if (handleRibbon2 < 0) {
         PrintFormat("Error creating handleRibbon2 indicator. retValue: %d, error: %d", handleRibbon2, GetLastError());
         return INIT_FAILED;
      }
   }
   if (InpRibbon3Period > 0) {
      handleRibbon3 = iMA(InpSymbol, InpTimeframe, InpRibbon3Period, 0, InpRibbonMode, PRICE_CLOSE);
      if (handleRibbon3 < 0) {
         PrintFormat("Error creating handleRibbon3 indicator. retValue: %d, error: %d", handleRibbon3, GetLastError());
         return INIT_FAILED;
      }      
   }
   if (InpRibbon4Period > 0) {
      handleRibbon4 = iMA(InpSymbol, InpTimeframe, InpRibbon4Period, 0, InpRibbonMode, PRICE_CLOSE);
      if (handleRibbon4 < 0) {
        PrintFormat("Error creating handleRibbon4 indicator. retValue: %d, error: %d", handleRibbon4, GetLastError());
         return INIT_FAILED;
      }
   }
   if (InpRibbon5Period > 0) {
      handleRibbon5 = iMA(InpSymbol, InpTimeframe, InpRibbon5Period, 0, InpRibbonMode, PRICE_CLOSE);
      if (handleRibbon5 < 0) {
         PrintFormat("Error creating handleRibbon5 indicator. retValue: %d, error: %d", handleRibbon5, GetLastError());
         return INIT_FAILED;
      }      
   }
   if (InpRibbon6Period > 0) {
      handleRibbon6 = iMA(InpSymbol, InpTimeframe, InpRibbon6Period, 0, InpRibbonMode, PRICE_CLOSE);
      if (handleRibbon6 < 0) {
         PrintFormat("Error creating handleRibbon6 indicator. retValue: %d, error: %d", handleRibbon6, GetLastError());
         return INIT_FAILED;
      }
   }
   if (InpRibbon7Period > 0) {
      handleRibbon7 = iMA(InpSymbol, InpTimeframe, InpRibbon7Period, 0, InpRibbonMode, PRICE_CLOSE);
      if (handleRibbon7 < 0) {
         PrintFormat("Error creating handleRibbon7 indicator. retValue: %d, error: %d", handleRibbon7, GetLastError());
         return INIT_FAILED;
      }
   }
   if (InpRibbon8Period > 0) {
      handleRibbon8 = iMA(InpSymbol, InpTimeframe, InpRibbon8Period, 0, InpRibbonMode, PRICE_CLOSE);
      if (handleRibbon8 < 0) {
         PrintFormat("Error creating handleRibbon8 indicator. retValue: %d, error: %d", handleRibbon8, GetLastError());
         return INIT_FAILED;
      }
   }

   return INIT_SUCCEEDED;
}

void RibbonFilter::Update() {
   util.m_symbol.RefreshRates();
   
   if (CopyBuffer(handleRibbon1, 0, 0, 3, bufferRibbon1) <= 0) {
      Print("Getting Ribbon1 is failed! Error ", GetLastError());
      return;
   }
   
   if (InpRibbon2Period > 0) {
      if (CopyBuffer(handleRibbon2, 0, 0, 3, bufferRibbon2) <= 0) {
         Print("Getting Ribbon2 is failed! Error ", GetLastError());
         return;
      }
   }
      
   if (InpRibbon3Period > 0) {
      if (CopyBuffer(handleRibbon3, 0, 0, 3, bufferRibbon3) <= 0) {
         Print("Getting Ribbon3 is failed! Error ", GetLastError());
         return;
      }
   }

   if (InpRibbon4Period > 0) {
      if (CopyBuffer(handleRibbon4, 0, 0, 3, bufferRibbon4) <= 0) {
         Print("Getting Ribbon4 is failed! Error ", GetLastError());
         return;
      }
   }

   if (InpRibbon5Period > 0) {
      if (CopyBuffer(handleRibbon5, 0, 0, 3, bufferRibbon5) <= 0) {
         Print("Getting Ribbon5 is failed! Error ", GetLastError());
         return;
      }
   }
   if (InpRibbon6Period > 0) {
         
      if (CopyBuffer(handleRibbon6, 0, 0, 3, bufferRibbon6) <= 0) {
         Print("Getting Ribbon6 is failed! Error ", GetLastError());
         return;
      }
   }      
   if (InpRibbon7Period > 0) {
      if (CopyBuffer(handleRibbon7, 0, 0, 3, bufferRibbon7) <= 0) {
         Print("Getting Ribbon7 is failed! Error ", GetLastError());
         return;
      }
   }      
   if (InpRibbon8Period > 0) {
      if (CopyBuffer(handleRibbon8, 0, 0, 3, bufferRibbon8) <= 0) {
         Print("Getting handleRibbon8 is failed! Error ", GetLastError());
         return;
      }   
   }
}

bool RibbonFilter::IsPriceAboveRibbon() {
   if ( 
      ((InpRibbon1Period > 0 && util.m_symbol.Ask() > bufferRibbon1[1]) || InpRibbon1Period < 0) &&
      ((InpRibbon2Period > 0 && util.m_symbol.Ask() > bufferRibbon2[1]) || InpRibbon2Period < 0) &&
      ((InpRibbon3Period > 0 && util.m_symbol.Ask() > bufferRibbon3[1]) || InpRibbon3Period < 0) &&
      ((InpRibbon4Period > 0 && util.m_symbol.Ask() > bufferRibbon4[1]) || InpRibbon4Period < 0) &&
      ((InpRibbon5Period > 0 && util.m_symbol.Ask() > bufferRibbon5[1]) || InpRibbon5Period < 0) &&
      ((InpRibbon6Period > 0 && util.m_symbol.Ask() > bufferRibbon6[1]) || InpRibbon6Period < 0) &&
      ((InpRibbon7Period > 0 && util.m_symbol.Ask() > bufferRibbon7[1]) || InpRibbon7Period < 0) &&
      ((InpRibbon8Period > 0 && util.m_symbol.Ask() > bufferRibbon8[1]) || InpRibbon8Period < 0)
   ) {
      return true;
   }
   
   return false;
}

bool RibbonFilter::IsPriceBelowRibbon() {
   if (
      ((InpRibbon1Period < 0 && util.m_symbol.Ask() > bufferRibbon1[1]) || InpRibbon1Period < 0) &&
      ((InpRibbon2Period < 0 && util.m_symbol.Ask() > bufferRibbon2[1]) || InpRibbon2Period < 0) &&
      ((InpRibbon3Period < 0 && util.m_symbol.Ask() > bufferRibbon3[1]) || InpRibbon3Period < 0) &&
      ((InpRibbon4Period < 0 && util.m_symbol.Ask() > bufferRibbon4[1]) || InpRibbon4Period < 0) &&
      ((InpRibbon5Period < 0 && util.m_symbol.Ask() > bufferRibbon5[1]) || InpRibbon5Period < 0) &&
      ((InpRibbon6Period < 0 && util.m_symbol.Ask() > bufferRibbon6[1]) || InpRibbon6Period < 0) &&
      ((InpRibbon7Period < 0 && util.m_symbol.Ask() > bufferRibbon7[1]) || InpRibbon7Period < 0) &&
      ((InpRibbon8Period < 0 && util.m_symbol.Ask() > bufferRibbon8[1]) || InpRibbon8Period < 0)   
   ) {
      return true;
   }
   
   return false;
}

bool RibbonFilter::IsRibbonStackedBullish(int offset = 1) {
   if (bufferRibbon1[offset] > bufferRibbon2[offset] &&
      bufferRibbon2[offset] > bufferRibbon3[offset] &&
      bufferRibbon3[offset] > bufferRibbon4[offset] &&
      bufferRibbon4[offset] > bufferRibbon5[offset] &&
      bufferRibbon5[offset] > bufferRibbon6[offset] &&
      bufferRibbon6[offset] > bufferRibbon7[offset] &&
      bufferRibbon7[offset] > bufferRibbon8[offset]
   ) {
      return true;
   }
   
   return false;
}

bool RibbonFilter::IsRibbonStackedBearish(int offset = 1) {
   if (bufferRibbon1[offset] < bufferRibbon2[offset] &&
      bufferRibbon2[offset] < bufferRibbon3[offset] &&
      bufferRibbon3[offset] < bufferRibbon4[offset] &&
      bufferRibbon4[offset] < bufferRibbon5[offset] &&
      bufferRibbon5[offset] < bufferRibbon6[offset] &&
      bufferRibbon6[offset] < bufferRibbon7[offset] &&
      bufferRibbon7[offset] < bufferRibbon8[offset]
   ) {
      return true;
   }
   
   return false;
}


bool RibbonFilter::IsRecentlyNotStacked(void) {
   if ((!IsRibbonStackedBullish(1) && IsRibbonStackedBullish(2)) ||
       (!IsRibbonStackedBearish(1) && IsRibbonStackedBearish(2))
   ) {
      return true;
   }
   
   return false;
}

double RibbonFilter::GetMA1() {
   return bufferRibbon1[1];
}


