//+------------------------------------------------------------------+
#property copyright "Copyright 2023, James Sablatura"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Using the Camarilla Pivot Points indicator to determine if an pair has compressed and due for a breakout"

/*
Description:
This is a strategy explained by FireScape in the forexfactory.com forum: https://www.forexfactory.com/thread/1230674-cpp-scalping-strategy
Camarilla description: https://www.babypips.com/forexpedia/camarilla-pivot-points

On any pair we're looking for the current days CPP lines to be completely inside the previous days CPP lines meaning current days S4 and S3
should be higher than previous days S4 and S3, and current days R4 and R3 should be lower than previous days R4 and R3. Within this compressed state
we will look for entries.

Timeframe: Any
Symbols: All

Indicators: 
   Camarills Pivot Point (built into this EA)

Buy Criteria:
   Today's R4 is lower than the previous day's R4
   Today's S4 is higher than the previous day's S4
   Entry: Price crosses above R3 level (and pip cushion) to trigger buy stop.
   Take Profit: Price touches R4 level

Sell Criteria:
   Today's R4 is lower than the previous day's R4
   Today's S4 is higher than the previous day's S4
   Entry: Price crosses below S3 level (and pip cushion) to trigger sell stop
   Take Profit: Price touches S4 level

Exit Criteria:
   TakeProfit is the current R4 or S4 level.
   Fixed RR. The author recommends a 2:1 RR but this is configurable in this EA.
*/

#include "../include/Util.mqh"

input string InpSymbol = "EURUSD";
input ENUM_TIMEFRAMES InpTimeFrame = PERIOD_CURRENT;

input double InpLots = 0.01;

input double InpStoplossMultipler = 2.0;
input double InpTakeProfitMultipler = 1.0;

class CamarillaPivotPointsStrategy {

private:
   Util util;
   bool isTradingToday, hasTradedToday;
   
protected:
   double prevR4;
   double prevR3;
   double prevS3;   
   double prevS4;
   double currR4;
   double currR3;
   double currS3;
   double currS4;            

public:
   int HandleOnInit();
   void HandleOnTick();
   void UpdateCppValues();
};

CamarillaPivotPointsStrategy strategy;

int CamarillaPivotPointsStrategy::HandleOnInit() {
   isTradingToday = false;
   hasTradedToday = false;

   return INIT_SUCCEEDED;
}

void CamarillaPivotPointsStrategy::HandleOnTick() {
   util.m_symbol.RefreshRates();

   if (util.NewBar(PERIOD_D1) || currR4 == 0.0 || currR3 == 0.0) {
      // We will only trade once per day, this resets that criteria
      hasTradedToday = false;

      // New day, or the previous calculation of CPP was invalid, so calculate the Camarilla points
      strategy.UpdateCppValues();
      PrintFormat("New days CPP: prevR4: %f, currR4: %f, prevS3: %f, currS3: %f", prevR4, currR4, prevS3, currS3);

      if (currR3 == 0.0 || currR3 == 0.0) { 
         Print("Invalid CPP values. Trying again on the next tick.");
         return;
      }
      
      // Valid CPP values at this point
      if (currR4 < prevR4 && currS4 > prevS4 && currR3 < prevR3 && currS3 > prevS3) {
         PrintFormat("We have a potential trade today. The CPP is compressed.");
         isTradingToday = true;
      }
      else {
         PrintFormat("We will not trade today. The current days CPP is not compressed.");
         isTradingToday = false;
      }
   }
   
   if (!isTradingToday || hasTradedToday) {
      return;
   }
   
   if (util.m_symbol.Ask() > currR3) {
      // Buy criteria met
      double diff = MathAbs(util.m_symbol.Ask() - currR4);
      double sl = util.m_symbol.Ask() - (diff * InpStoplossMultipler);
      double tp = util.m_symbol.Ask() + (diff * InpTakeProfitMultipler);
      
      PrintFormat("BUYING: ask: %lf, currR3: %lf, stoploss: %lf, takeProfit: %lf", util.m_symbol.Ask(), currR3, sl, tp);

      util.m_trade.Buy(
         InpLots, 
         InpSymbol, 
         util.m_symbol.Ask(), 
         sl, 
         tp
      );
      
      hasTradedToday = true;
   }
   else if (util.m_symbol.Bid() < currS3) {
      // Sell criteria met
      double diff = MathAbs(util.m_symbol.Bid() - currS4);
      double sl = util.m_symbol.Bid() + (diff * InpStoplossMultipler);
      double tp = util.m_symbol.Bid() - (diff * InpTakeProfitMultipler);
      
      PrintFormat("SELLING: bid: %lf, currS3: %lf, stoploss: %lf, takeProfit: %lf", util.m_symbol.Bid(), currS3, sl, tp);

      util.m_trade.Sell(
         InpLots, 
         InpSymbol, 
         util.m_symbol.Ask(), 
         sl, 
         tp
      );
      
      hasTradedToday = true;
   }
}

void CamarillaPivotPointsStrategy::UpdateCppValues(void) {
   double prevClose = iClose(InpSymbol, PERIOD_D1, 2);
   double prevHigh = iHigh(InpSymbol, PERIOD_D1, 2);
   double prevLow = iLow(InpSymbol, PERIOD_D1, 2);
   prevR4 = (prevHigh - prevLow) * 1.1 / 2 + prevClose;
   prevR3 = (prevHigh - prevLow) * 1.1 / 4 + prevClose;
   prevS3 = prevClose - (prevHigh - prevLow) * 1.1 / 4;
   prevS4 = prevClose - (prevHigh - prevLow) * 1.1 / 2;

   double currClose = iClose(InpSymbol, PERIOD_D1, 1);
   double currHigh = iHigh(InpSymbol, PERIOD_D1, 1);
   double currLow = iLow(InpSymbol, PERIOD_D1, 1);
   currR4 = (currHigh - currLow) * 1.1 / 2 + currClose;
   currR3 = (currHigh - currLow) * 1.1 / 4 + currClose;
   currS3 = currClose - (currHigh - currLow) * 1.1 / 4;
   currS4 = currClose - (currHigh - currLow) * 1.1 / 2;

}

int OnInit() {
   return strategy.HandleOnInit();
}

void OnTick() {
   strategy.HandleOnTick();
}
