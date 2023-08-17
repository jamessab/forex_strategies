//+------------------------------------------------------------------+
//|                                           SupertrendMABounce.mqh |
//|                                  Copyright 2023, James Sablatura |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, James Sablatura"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "The supertrend indicator for trend, the MA bounce for signal. Other indicators can provide the filter"

/*
When the supertrend is bullish, and the price goes down and touches the MA, we assume it will bounce back up so BUY. The opposite for SELL
20 ema
10-3 supertrend
*/

#include "../include/Util.mqh"

input string symbol = "EURUSD";
input ENUM_TIMEFRAMES InpTimeFrame = PERIOD_CURRENT;

input double InpLots = 0.01;

input int InpSupertrendPeriod1 = 10;
input int InpSupertrendMultiplier1 = 1;
input int InpSupertrendPeriod2 = 20;
input int InpSupertrendMultiplier2 = 2;
input int InpSupertrendPeriod3 = 50;
input int InpSupertrendMultiplier3 = 3;

int buySell = -1;

class SupertrendMABounce {

private:
   int handleSupertrend1, handleSupertrend2, handleSupertrend3;
   double bufferSupertrend1[], bufferSupertrend2[], bufferSupertrend3[] ;
   Util util;
   
public:
   int HandleOnInit();
   void HandleOnTick();
   void CopyBuffers();
};

SupertrendMABounce strategy;

int SupertrendMABounce::HandleOnInit() {
   ArraySetAsSeries(bufferSupertrend1, true);
   ArraySetAsSeries(bufferSupertrend2, true);
   ArraySetAsSeries(bufferSupertrend3, true);
   
   handleSupertrend1 = iCustom(symbol, InpTimeFrame, "Market/Supertrend Line", InpSupertrendPeriod1, InpSupertrendMultiplier1);
   if (handleSupertrend1 == INVALID_HANDLE) {
      printf("Error creating handleSupertrend1 indicator. Error: %d", GetLastError());
      return false;
   }
   
   handleSupertrend2 = iCustom(symbol, InpTimeFrame, "Market/Supertrend Line", InpSupertrendPeriod2, InpSupertrendMultiplier2);
   if (handleSupertrend2 == INVALID_HANDLE) {
      printf("Error creating handleSupertrend2 indicator. Error: %d", GetLastError());
      return false;
   }
   
   handleSupertrend3 = iCustom(symbol, InpTimeFrame, "Market/Supertrend Line", InpSupertrendPeriod3, InpSupertrendMultiplier3);
   if (handleSupertrend3 == INVALID_HANDLE) {
      printf("Error creating handleSupertrend3 indicator. Error: %d", GetLastError());
      return false;
   }

   return INIT_SUCCEEDED;
}

void SupertrendMABounce::HandleOnTick() {
   if (!util.NewBar(InpTimeFrame)) {
      return;
   }
   
   CopyBuffers();

   if (PositionsTotal() > 0 && buySell == -1) {
      // problem closing order, try again
      util.CloseAllOrders();
   }
   if (buySell == 0) {
      if (util.m_symbol.Bid() < bufferSupertrend1[2] || util.m_symbol.Bid() < bufferSupertrend2[2] || util.m_symbol.Bid() < bufferSupertrend3[2]) {
         util.CloseAllOrders();
         buySell = -1;
         return;
      }
   }
   if (buySell == 1) {
      if (util.m_symbol.Bid() > bufferSupertrend1[2] || util.m_symbol.Bid() > bufferSupertrend2[2] || util.m_symbol.Bid() > bufferSupertrend3[2]) {
         util.CloseAllOrders();
         buySell = -1;
         return;
      }
   }
   
   if (PositionsTotal() > 0) {
      return;
   }
   
   if (util.m_symbol.Bid() > bufferSupertrend1[1] && util.m_symbol.Bid() > bufferSupertrend2[1] && util.m_symbol.Bid() > bufferSupertrend3[1]) {
   
      util.m_trade.Buy(
         InpLots, 
         symbol, 
         util.m_symbol.Ask(), 
         0, 
         0
      );
      
      buySell = 0;
      
   }
   else if (util.m_symbol.Ask() < bufferSupertrend1[1] && util.m_symbol.Ask() < bufferSupertrend2[1] && util.m_symbol.Ask() < bufferSupertrend3[1]) {

        
      util.m_trade.Sell(
         InpLots, 
         symbol, 
         util.m_symbol.Bid(), 
         0, 
         0
      );
      
      buySell = 1;
      
   }
}

void SupertrendMABounce::CopyBuffers(void) {
   util.m_symbol.RefreshRates();
 
   if (CopyBuffer(handleSupertrend1, 0, 0, 3, bufferSupertrend1) != 3) {
      printf("Error getting bufferSupertrend1");
      return;
   }
   
   if (CopyBuffer(handleSupertrend2, 0, 0, 3, bufferSupertrend2) != 3) {
      printf("Error getting bufferSupertrend2");
      return;
   }
   
   if (CopyBuffer(handleSupertrend3, 0, 0, 3, bufferSupertrend3) != 3) {
      printf("Error getting bufferSupertrend3");
      return;
   }
    
}

int OnInit() {
   return strategy.HandleOnInit();
}

void OnTick() {
   strategy.HandleOnTick();
}
