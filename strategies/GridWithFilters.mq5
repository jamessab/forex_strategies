//+------------------------------------------------------------------+
#property copyright "Copyright 2023, James Sablatura"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description ""

#include "../include/Util.mqh"
#include "../include/MoneyManagement/Grid.mqh"
#include "../include/Filters/SpreadFilter.mqh"

input string InpSymbol = "EURUSD";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;
//input double InpLots = 0.01;

input int InpRSIPeriod = 14;
input int InpRSIThreshold = 20;

class GridWithFilters {

private:
   Util util;
   Grid grid;
   SpreadFilter spreadFilter;

   int handleRSI;
   double bufferRSI[], currRSI;

protected:

public:
   int HandleOnInit();
   void HandleOnTick();
   void UpdateIndicators();
};

GridWithFilters strategy;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GridWithFilters::HandleOnInit() {
   ArraySetAsSeries(bufferRSI, true);
   
   grid.SetRSIThreshold(InpRSIThreshold);
   
   handleRSI = iRSI(InpSymbol, InpTimeframe, InpRSIPeriod, PRICE_CLOSE);
   return INIT_SUCCEEDED;
}


void GridWithFilters::HandleOnTick() {

   util.m_symbol.RefreshRates();

   UpdateIndicators();

   if (PositionsTotal() > 0) {
      grid.HandleGrid();
      return;
   }

   if (!util.NewBar(InpTimeframe)) {
      return;
   }

   // If here, we haven't entered any trades
   if (currRSI <= InpRSIThreshold) {
      PrintFormat("BUYING: bid: %lf, ask: %lf", util.m_symbol.Bid(), util.m_symbol.Ask());
   
      double lots = grid.FindLotSize();
      if (!util.m_trade.Buy(lots, InpSymbol, util.m_symbol.Ask(), 0, 0 )) {
         PrintFormat("Invalid buy order: %d", GetLastError());
         return;
      }
      
      grid.originalLotSize = lots;

   } else if (currRSI >= 100 - InpRSIThreshold) {
      PrintFormat("SELLING: ask: %lf, ask: %lf", util.m_symbol.Ask(), util.m_symbol.Ask());
   
      double lots = grid.FindLotSize();
      if (!util.m_trade.Sell(lots, InpSymbol, util.m_symbol.Bid(), 0, 0)) {
         PrintFormat("Invalid sell order: %d", GetLastError());
         return;
      }
      grid.originalLotSize = lots;
   
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GridWithFilters::UpdateIndicators(void) {
   if (CopyBuffer(handleRSI, 0, 0, 2, bufferRSI) <= 0) {
      Print("Getting RSI is failed! Error ", GetLastError());
      return;
   }
   
   currRSI = bufferRSI[1];
   
   grid.SetCurrRSI(currRSI);
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
