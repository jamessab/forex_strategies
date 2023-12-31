//+------------------------------------------------------------------+
#property copyright "Copyright 2023, James Sablatura"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Using the Camarilla Pivot Points indicator to determine if an pair has compressed and due for a breakout"

/*
Description:
This is a strategy based on the one explained by FireScape in the forexfactory.com forum: https://www.forexfactory.com/thread/1230674-cpp-scalping-strategy
Camarilla description: https://www.babypips.com/forexpedia/camarilla-pivot-points

Timeframe: Any
Symbols: All

Indicators: 
   Camarills Pivot Point (built into this EA)

Buy Criteria:
   Entry: Price crosses above the R3 level
   Exit: Based on configuration

Sell Criteria:
   Entry: Price crosses below the S3 level
   Exit: Based on configuration

*/

#include "../include/Util.mqh"

input string symbol = "EURUSD";

input double InpLots = 0.01;

input double InpStoplossMultiplier = 2.0;  // TakeProfit RR Factor
input double InpTakeProfitMultiplier = 1.0; // Stoploss RR Factor

input bool InpUseCompression = true; // Use Compression
input int InpMinR4S4DistanceInPoints = 200; // Minimum distance from the R4 and S4 lines
input int InpMaxPositions = 1; // Max Positions to have open at a time.

#include "../include/Filters/SpreadFilter.mqh"

class CamarillaPivotPointsStrategy {

private:
   Util util;
   SpreadFilter spreadFilter;
   bool isTradingToday, hasTradedToday;

   
protected:
   double prevR4, prevR3, prevS3, prevS4, currR4, currR3, currS3, currS4;            

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

   if (PositionsTotal() >= InpMaxPositions) {
      // Max positions reached
      return;
   }
   
   util.m_symbol.RefreshRates();

   if (util.NewBar(PERIOD_D1)) {
      // We will only trade once per day, this resets that for the new day
      hasTradedToday = false;

      strategy.UpdateCppValues();
      PrintFormat("New days CPP: prevR4: %f, prevR3: %f, prevS3: %f, prevS4: %f, "
                  "currR4: %f, currR3: %f, currS3: %f, currS4: %f",
                  prevR4, prevR3, prevS4, prevS3, 
                  currR4, currR3, currS4, currS3
                 );

      if (InpUseCompression) {
         if (currR4 < prevR4 && currS4 > prevS4 && currR3 < prevR3 && currS3 > prevS3) {
            PrintFormat("Potential trade today. The CPP is compressed.");
            isTradingToday = true;
         }
         else {
            PrintFormat("Not trading today. The current days CPP is not compressed.");
            isTradingToday = false;
         }
      }
      else {
         isTradingToday = true;
      }
   }
   
   if (!isTradingToday || hasTradedToday) {
      return;
   }

   if (MathAbs(currR4 - currS4) < InpMinR4S4DistanceInPoints * Point()) {
      return;
   }
   
   if (util.m_symbol.Ask() > currR3 && util.m_symbol.Ask() < currR4 && spreadFilter.passes()) {
      // Buy criteria met

      double sl = 0, tp = 0;

      double diff = MathAbs(util.m_symbol.Ask() - currR4);
      tp = util.m_symbol.Bid() + (diff * InpTakeProfitMultiplier);
      sl = util.m_symbol.Bid() - (diff * InpStoplossMultiplier);
      
      PrintFormat("BUYING: bid: %lf, ask: %lf, spread: %lf, stoploss: %lf, takeProfit: %lf", util.m_symbol.Bid(), util.m_symbol.Ask(), (util.m_symbol.Ask() - util.m_symbol.Bid()), sl, tp);

      if (!util.m_trade.Buy(InpLots, symbol, util.m_symbol.Ask(), sl, tp )) {
         PrintFormat("Invalid buy order: %d", GetLastError());
         return;
      }
      
      hasTradedToday = true;
   }
   else if (util.m_symbol.Bid() < currS3 && util.m_symbol.Bid() > currS4 && spreadFilter.passes()) {
      // Sell criteria met

      double sl = 0, tp = 0;

      double diff = MathAbs(util.m_symbol.Bid() - currS4);
      tp = util.m_symbol.Ask() - (diff * InpTakeProfitMultiplier);
      sl = util.m_symbol.Ask() + (diff * InpStoplossMultiplier);
            
      PrintFormat("SELLING: bid: %lf, ask: %lf, spread: %lf, stoploss: %lf, takeProfit: %lf", util.m_symbol.Bid(), util.m_symbol.Ask(), (util.m_symbol.Ask() - util.m_symbol.Bid()), sl, tp);

      if (!util.m_trade.Sell(InpLots, symbol, util.m_symbol.Ask(), sl, tp )) {    
         PrintFormat("Invalid sell order: %d", GetLastError());
         return;
      }
      
      hasTradedToday = true;
   }
}

void CamarillaPivotPointsStrategy::UpdateCppValues(void) {
   double prevClose = iClose(symbol, PERIOD_D1, 2);
   double prevHigh = iHigh(symbol, PERIOD_D1, 2);
   double prevLow = iLow(symbol, PERIOD_D1, 2);
   prevR4 = (prevHigh - prevLow) * 1.1 / 2 + prevClose;
   prevR3 = (prevHigh - prevLow) * 1.1 / 4 + prevClose;
   prevS3 = prevClose - (prevHigh - prevLow) * 1.1 / 4;
   prevS4 = prevClose - (prevHigh - prevLow) * 1.1 / 2;

   double currClose = iClose(symbol, PERIOD_D1, 1);
   double currHigh = iHigh(symbol, PERIOD_D1, 1);
   double currLow = iLow(symbol, PERIOD_D1, 1);
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
