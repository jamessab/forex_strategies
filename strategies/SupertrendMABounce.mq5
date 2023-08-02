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
Timeframe: Any
Symbols: All

Indicators: 
   Supertrend(10, 3)
   EMA(20)

Buy Criteria:
   Supertrend is bullish
   Price drops down and touches the EMA

Sell Criteria:
   Supertrend is bearish
   Price rises and touches the EMA

Exit Criteria:
   Stoploss set to the Supertrend value at the time of the order
   TakeProfit set to the 2x the stoploss
*/

#include "../include/Util.mqh"

input string InpSymbol = "EURUSD";
input ENUM_TIMEFRAMES InpTimeFrame = PERIOD_CURRENT;

input double InpLots = 0.01;

input int InpMAPeriod = 20;
input int InpSupertrendPeriod1 = 10;
input int InpSupertrendMultiplier1 = 3;
input int InpSupertrendPeriod2 = 10;
input int InpSupertrendMultiplier2 = 6;

input bool InpUseSupertrendMADistanceFilter = true;
input int InpSupertrendMADistanceFilterInPoints = 100;

input double InpStoplossMultipler = 1.0;
input double InpTakeProfitMultipler = 3.0;

class SupertrendMABounce {

private:
   int handleMA, handleSupertrend1, handleSupertrend2;
   double bufferMA[], bufferSupertrend1[], bufferSupertrend2[];
   Util util;
   
public:
   int HandleOnInit();
   void HandleOnTick();
   void CopyBuffers();
};

SupertrendMABounce strategy;

int SupertrendMABounce::HandleOnInit() {
   ArraySetAsSeries(bufferMA, true);
   ArraySetAsSeries(bufferSupertrend1, true);
   ArraySetAsSeries(bufferSupertrend2, true);
   
   handleMA = iMA(InpSymbol, InpTimeFrame, InpMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if (handleMA == INVALID_HANDLE) {
      printf("Error creating handleMA indicator. Error: %d", GetLastError());
      return false;
   }

   handleSupertrend1 = iCustom(InpSymbol, InpTimeFrame, "Market/Supertrend Line", InpSupertrendPeriod1, InpSupertrendMultiplier1);
   if (handleSupertrend1 == INVALID_HANDLE) {
      printf("Error creating handleSupertrend indicator. Error: %d", GetLastError());
      return false;
   }

   handleSupertrend2 = iCustom(InpSymbol, InpTimeFrame, "Market/Supertrend Line", InpSupertrendPeriod2, InpSupertrendMultiplier2);
   if (handleSupertrend2 == INVALID_HANDLE) {
      printf("Error creating handleSupertrend indicator. Error: %d", GetLastError());
      return false;
   }
   
   return INIT_SUCCEEDED;
}

void SupertrendMABounce::HandleOnTick() {
   if (PositionsTotal() > 0) {
      return;
   }

   CopyBuffers();
      
   if (InpUseSupertrendMADistanceFilter && 
      (MathAbs(util.m_symbol.Bid() - bufferSupertrend1[1]) < InpSupertrendMADistanceFilterInPoints * Point() ||
      MathAbs(bufferMA[0] - bufferSupertrend1[1]) < InpSupertrendMADistanceFilterInPoints * Point())
   ) {
      return;
   }

   if (util.m_symbol.Ask() > bufferSupertrend1[1] && util.m_symbol.Ask() > bufferSupertrend2[1]) {

      if (util.m_symbol.Ask() < bufferMA[0] && iClose(InpSymbol, InpTimeFrame, 1) > bufferMA[1]) {

         PrintFormat("buying. bid: %f, low: %f, MA: %f, supertrend: %f, distance: %f", util.m_symbol.Bid(), iLow(InpSymbol, InpTimeFrame, 0), bufferMA[1], bufferSupertrend1[1], MathAbs(util.m_symbol.Bid()  - bufferSupertrend1[1]));
         double diff = util.m_symbol.Ask() - bufferSupertrend1[1];
         double sl = util.m_symbol.Ask() - (diff * InpStoplossMultipler);
         double tp = util.m_symbol.Ask() + (diff * InpTakeProfitMultipler);
      
         util.m_trade.Buy(
            InpLots, 
            InpSymbol, 
            util.m_symbol.Ask(), 
            sl, 
            tp
         );
      }
   }
   else if (util.m_symbol.Bid() < bufferSupertrend1[1] && util.m_symbol.Bid() < bufferSupertrend2[1]) {
   
      if (util.m_symbol.Bid() > bufferMA[0] && iClose(InpSymbol, InpTimeFrame, 1) < bufferMA[1]) {

         PrintFormat("selling. bid: %f, high: %f, MA: %f, supertrend: %f, distance: %f", util.m_symbol.Bid(), iHigh(InpSymbol, InpTimeFrame, 0), bufferMA[1], bufferSupertrend1[1], MathAbs(util.m_symbol.Bid()  - bufferSupertrend1[1]));
         double diff = bufferSupertrend1[1] - util.m_symbol.Bid();
         double sl = util.m_symbol.Bid() + (diff * InpStoplossMultipler);
         double tp = util.m_symbol.Bid() - (diff * InpTakeProfitMultipler);
      
         util.m_trade.Sell(
            InpLots, 
            InpSymbol, 
            util.m_symbol.Bid(), 
            sl, 
            tp
         );
      }
   }
}

void SupertrendMABounce::CopyBuffers(void) {
   util.m_symbol.RefreshRates();

   if (CopyBuffer(handleMA, 0, 0, 3, bufferMA) != 3) {
      printf("Error getting bufferMA");
      return;
   }
   
   if (CopyBuffer(handleSupertrend1, 0, 0, 15, bufferSupertrend1) != 15) {
      printf("Error getting bufferSupertrend1");
      return;
   }
   
   if (CopyBuffer(handleSupertrend2, 0, 0, 15, bufferSupertrend2) != 15) {
      printf("Error getting bufferSupertrend2");
      return;
   }   
}

int OnInit() {
   return strategy.HandleOnInit();
}

void OnTick() {
   strategy.HandleOnTick();
}
