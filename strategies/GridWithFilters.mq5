//+------------------------------------------------------------------+
#property copyright "Copyright 2023, James Sablatura"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description ""

#include "../include/Util.mqh"
#include "../include/MoneyManagement/Grid.mqh"
#include "../include/MoneyManagement/Pyramid.mqh"
#include "../include/Filters/SpreadFilter.mqh"
#include "../include/Filters/RSIFilter.mqh"
#include "../include/Filters/StochFilter.mqh"
#include "../include/Filters/SupertrendFilter.mqh"

input string InpSymbol = "EURUSD";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT;

class GridWithFilters {

private:
   Util util;
   Grid grid;
   Pyramid pyramid;
   SpreadFilter spreadFilter;
   RSIFilter rsiFilter;
   StochFilter stochFilter;
   SupertrendFilter supertrendFilter;
   int gridPyramidMode;
   
public:
   int HandleOnInit();
   void HandleOnTick();
   void Update();
};

GridWithFilters strategy;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GridWithFilters::HandleOnInit() {
   if (rsiFilter.HandleOnInit() != INIT_SUCCEEDED) {
      PrintFormat("Error initializing the rsiFilter in the GridWithFilters strategy. Exiting.");
      ExpertRemove();
   }
   
   if (stochFilter.HandleOnInit() != INIT_SUCCEEDED) {
      PrintFormat("Error initializing the stochFilter in the GridWithFilters strategy. Exiting.");
      ExpertRemove();
   }
   
   if (supertrendFilter.HandleOnInit() != INIT_SUCCEEDED) {
      PrintFormat("Error initializing the supertrend in the GridWithFilters strategy. Exiting.");
      ExpertRemove();
   }
      
   if (spreadFilter.HandleOnInit() != INIT_SUCCEEDED) {
      PrintFormat("Error initializing the spreadFilter in the GridWithFilters strategy. Exiting.");
      ExpertRemove();
   }

   if (grid.HandleOnInit() != INIT_SUCCEEDED) {
      PrintFormat("Error initializing the grid in the GridWithFilters strategy. Exiting.");
      ExpertRemove();
   }

   if (pyramid.HandleOnInit() != INIT_SUCCEEDED) {
      PrintFormat("Error initializing the pyramid in the GridWithFilters strategy. Exiting.");
      ExpertRemove();
   }
   
   return INIT_SUCCEEDED;
}


void GridWithFilters::HandleOnTick() {

   util.m_symbol.RefreshRates();

   Update();

   if (PositionsTotal() > 0) {
      if (!pyramid.pyramidStarted) {
         grid.HandleGrid();
      }
      if (!grid.gridStarted) {
         pyramid.HandlePyramid();
      }
      return;
   }

   if (!util.NewBar(InpTimeframe)) {
      return;
   }

   // If here, we haven't entered any trades
   if ( 
        ((InpUseSupertrendFilter && supertrendFilter.isBullish()) || !InpUseSupertrendFilter) && 
        ((InpUseRSIFilter && rsiFilter.isOversold()) || !InpUseRSIFilter) &&
        ((InpUseStochFilter && stochFilter.isOversold()) || !InpUseStochFilter) &&
         spreadFilter.passes()) {
      PrintFormat("BUYING: bid: %lf, ask: %lf", util.m_symbol.Bid(), util.m_symbol.Ask());
   
      double lots = grid.FindLotSize();
//      double lots = pyramid.FindLotSize(POSITION_TYPE_BUY);
      
      if (!util.m_trade.Buy(lots, InpSymbol, util.m_symbol.Ask(), 0, 0 )) {
         PrintFormat("Invalid buy order: %d", GetLastError());
         return;
      }

      grid.originalLotSize = lots;
   } 
   else if ( 
             ((InpUseSupertrendFilter && supertrendFilter.isBearish()) || !InpUseSupertrendFilter) &&
             ((InpUseRSIFilter && rsiFilter.isOverbought()) || !InpUseRSIFilter) &&
             ((InpUseStochFilter && stochFilter.isOverbought()) || !InpUseStochFilter) &&
             spreadFilter.passes()) {
      PrintFormat("SELLING: ask: %lf, ask: %lf", util.m_symbol.Ask(), util.m_symbol.Ask());
   
      double lots = grid.FindLotSize();
      //double lots = pyramid.FindLotSize(POSITION_TYPE_SELL);
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
void GridWithFilters::Update(void) {
   rsiFilter.Update();
   stochFilter.Update();
   supertrendFilter.Update();
   
   pyramid.Update();
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
