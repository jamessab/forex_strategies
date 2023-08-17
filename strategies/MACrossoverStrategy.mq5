//+------------------------------------------------------------------+
//|                                                  MACrossover.mqh |
//|                                  Copyright 2023, James Sablatura |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, James Sablatura"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "A simple MA crossover strategy"

// When the faster MA crosses above the slower MA then buy. When the faster MA moves below the slower MA then sell/

#include "../include/Util.mqh"

input string symbol = "EURUSD";
input ENUM_TIMEFRAMES InpTimeFrame = PERIOD_CURRENT;
input int InpStoplossInPoints = 100;
input int InpTakeProfitInPoints = 100;

input double InpLots = 0.01;

input int InpMAPeriod1 = 12;
input ENUM_MA_METHOD InpMAMode1 = MODE_EMA;
input int InpMAPeriod2 = 24;
input ENUM_MA_METHOD InpMAMode2 = MODE_EMA;

class MACrossoverStrategy {

private:
   int handleMA1, handleMA2;
   double bufferMA1[], bufferMA2[]; 
   Util util;
   
public:
   int HandleOnInit();
   void HandleOnTick();
   void CopyBuffers();
};

MACrossoverStrategy strategy;

int MACrossoverStrategy::HandleOnInit() {
   ArraySetAsSeries(bufferMA1, true);
   ArraySetAsSeries(bufferMA2, true);
   
   handleMA1 = iMA(symbol, InpTimeFrame, InpMAPeriod1, 1, InpMAMode1, PRICE_CLOSE);
   if (handleMA1 == INVALID_HANDLE) {
      printf("Error creating handleMA1 indicator. Error: %d", GetLastError());
      return false;
   }

   handleMA2 = iMA(symbol, InpTimeFrame, InpMAPeriod2, 1, InpMAMode2, PRICE_CLOSE);
   if (handleMA2 == INVALID_HANDLE) {
      printf("Error creating handleMA2 indicator. Error: %d", GetLastError());
      return false;
   }

   return INIT_SUCCEEDED;
}

void MACrossoverStrategy::HandleOnTick() {
   if (!util.NewBar(InpTimeFrame)) {
      return;
   }
   
   CopyBuffers();

   if (bufferMA1[1] < bufferMA2[1] &&
       bufferMA1[0] > bufferMA2[0])
   {
      util.m_trade.Buy(
         InpLots, 
         symbol, 
         util.m_symbol.Ask(), 
         util.ComputeStoploss(symbol, ORDER_TYPE_BUY, InpStoplossInPoints), 
         util.ComputeTakeProfit(symbol, ORDER_TYPE_BUY, InpTakeProfitInPoints)
      );
   }
   else if (bufferMA1[1] > bufferMA2[1] &&
       bufferMA1[0] < bufferMA2[0])
   {
      util.m_trade.Sell(
         InpLots, 
         symbol, 
         util.m_symbol.Bid(), 
         util.ComputeStoploss(symbol, ORDER_TYPE_SELL, InpStoplossInPoints), 
         util.ComputeTakeProfit(symbol, ORDER_TYPE_SELL, InpTakeProfitInPoints)
      );
   }
}

void MACrossoverStrategy::CopyBuffers(void) {
   util.m_symbol.RefreshRates();

   if (CopyBuffer(handleMA1, 0, 0, 3, bufferMA1) != 3) {
      printf("Error getting bufferMA1");
      return;
   }
   
   if (CopyBuffer(handleMA2, 0, 0, 3, bufferMA2) != 3) {
      printf("Error getting bufferMA2");
      return;
   }
}

int OnInit() {
   return strategy.HandleOnInit();
}

void OnTick() {
   strategy.HandleOnTick();
}
