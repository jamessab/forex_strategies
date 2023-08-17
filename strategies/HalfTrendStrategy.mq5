//+------------------------------------------------------------------+
#property copyright "Copyright 2023, James Sablatura"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description ""

#include "../include/Util.mqh"
#include "../include/Filters/SpreadFilter.mqh"

input string symbol = "EURUSD";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;
input double InpLots = 0.01;
input int InpAmplitude = 2;

class HalfTrendStrategy {

private:
   Util util;
   SpreadFilter spreadFilter;
   int handleHalfTrend;
   double bufferHalfTrendUp[], bufferHalfTrendDown[];
   
protected:

public:
   int HandleOnInit();
   void HandleOnTick();
   void UpdateIndicators();
};

HalfTrendStrategy strategy;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int HalfTrendStrategy::HandleOnInit() {
   ArraySetAsSeries(bufferHalfTrendUp, true);
   ArraySetAsSeries(bufferHalfTrendDown, true);

   handleHalfTrend = iCustom(symbol, InpTimeframe, "half-trend-buy-sell-indicator", InpAmplitude);
   if (handleHalfTrend < 0) {
      PrintFormat("Error initializing the handleHalfTrend in the GridWithFilters strategy. Exiting.");
      ExpertRemove();
   }
      
   if (spreadFilter.HandleOnInit() != INIT_SUCCEEDED) {
      PrintFormat("Error initializing the spreadFilter in the GridWithFilters strategy. Exiting.");
      ExpertRemove();
   }
   
   return INIT_SUCCEEDED;
}


void HalfTrendStrategy::HandleOnTick() {

   util.m_symbol.RefreshRates();

   if (!util.NewBar(InpTimeframe)) {
      return;
   }

   UpdateIndicators();

   if (bufferHalfTrendUp[1] != EMPTY_VALUE && bufferHalfTrendUp[1] != 0.0) {
      util.CloseAllOrders();

      if (!util.m_trade.Buy(InpLots, symbol, util.m_symbol.Ask(), 0, 0 )) {
         PrintFormat("Invalid buy order: %d", GetLastError());
         return;
      }
   }
   else if (bufferHalfTrendDown[1] != EMPTY_VALUE && bufferHalfTrendDown[1] != 0.0) {
      util.CloseAllOrders();

      if (!util.m_trade.Sell(InpLots, symbol, util.m_symbol.Bid(), 0, 0)) {
         PrintFormat("Invalid sell order: %d", GetLastError());
         return;
      }
   
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HalfTrendStrategy::UpdateIndicators(void) {
   if (CopyBuffer(handleHalfTrend, 5, 0, 2, bufferHalfTrendUp) <= 0) {
      Print("Getting bufferHalfTrendUp is failed! Error ", GetLastError());
      return;
   }

   if (CopyBuffer(handleHalfTrend, 6, 0, 2, bufferHalfTrendDown) <= 0) {
      Print("Getting bufferHalfTrendDown is failed! Error ", GetLastError());
      return;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   return strategy.HandleOnInit();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   strategy.HandleOnTick();
}
//+------------------------------------------------------------------+
