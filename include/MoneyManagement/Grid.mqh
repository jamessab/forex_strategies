//+------------------------------------------------------------------+
//|                                                Grid.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../Filters/RSIFilter.mqh"
#include "../Filters/StochFilter.mqh"
#include "../Filters/RibbonFilter.mqh"

input bool InpUseGrid = false;

enum ENUM_INITIALLOT_METHOD {
   INITIALLOT_PERCENTAGE = 0,
   INITIALLOT_FIXED = 1
};
input ENUM_INITIALLOT_METHOD InpInitialLotMethod = 1;
input double InpInitialLotPercentageOfBalance = 1.0;
input double InpInitialLot = 0.01;

enum ENUM_TAKEPROFIT_METHOD {
   TAKEPROFIT_PERCENTAGE = 0,
   TAKEPROFIT_FIXED = 1
};
input ENUM_TAKEPROFIT_METHOD InpTakeProfitMethod = 1;
input double InpTakeProfitInPercentageOfBalance = 0;
input int InpTakeProfitInPoints = 100;

input double InpStoplossInPercentageOfBalance = 0.25;
input int InpMaxPositions = 10;

enum ENUM_DISTANCE_METHOD {
   DISTANCE_FIXED = 0,
   DISTANCE_MULTIPLIER = 1,
   DISTANCE_SEQUENCE = 2
};
input ENUM_DISTANCE_METHOD InpGridDistanceMethod = DISTANCE_FIXED;
input int InpGridDistanceInPoints = 100;
input double InpGridMultiplierDistance = 1.5;
input string InpGridSequenceDistanceInPoints = "700,1200,1500,2000,2000,2000,2000";

input double InpMultiplier = 1.5;

class Grid {

private:
   Util util;
   RSIFilter rsiFilter;
   StochFilter stochFilter;
   RibbonFilter ribbonFilter;
   
   string distanceSequence[];
  
public:
   double originalLotSize;
   double takeProfit;
   double stoploss;
      
   void HandleGrid();
   double FindLotSize();
   void Update();
   
   int HandleOnInit();
   int FindGridDistance();
   
   bool gridStarted;
   
};

int Grid::HandleOnInit() {
   if (InpUseRSIFilter && rsiFilter.HandleOnInit() < 0) {
      return -1;
   }
   
   if (InpUseStochFilter && stochFilter.HandleOnInit() < 0) {
      return -1;
   }


   if (InpUseRibbonPriceOutsideRibbonFilter && ribbonFilter.HandleOnInit() < 0) {
      return -1;
   }
   
   ArrayResize(distanceSequence, InpMaxPositions);
   StringSplit(InpGridSequenceDistanceInPoints, ',', distanceSequence);
   
   originalLotSize = -1;
   
   return INIT_SUCCEEDED;
}

void Grid::HandleGrid() {
   if (PositionsTotal() == 0) {
      return;
   }
   Update();
   
   double pl = util.GetPLInMoney();
   if (util.GetPLInMoney() >= takeProfit) {
      util.CloseAllOrders();
      gridStarted = false;
      return;
   }
   
   if (util.GetPLInMoney() <= stoploss) {
      util.CloseAllOrders();
      gridStarted = false;
      originalLotSize = -1;
      return;
   }
   
   if (PositionsTotal() >= InpMaxPositions) {
      // Max positions reached
      return;
   }
   
   util.m_position.SelectByIndex(PositionsTotal() - 1);
   
   double a = util.m_position.PriceOpen();
   int b = FindGridDistance();
   double c = util.m_symbol.Ask();
   
   if (util.m_position.PositionType() == POSITION_TYPE_BUY) {
      if (util.m_symbol.Ask() < util.m_position.PriceOpen() - FindGridDistance() * Point() && 
         ((InpUseRSIFilter && rsiFilter.isOversold(1)) || !InpUseRSIFilter) &&
         ((InpUseStochFilter && stochFilter.isOversold()) || !InpUseStochFilter) &&
         ((InpUseRibbonPriceOutsideRibbonFilter && ribbonFilter.IsPriceBelowRibbon()) || !InpUseRibbonPriceOutsideRibbonFilter)
      ) 
      {
         double priceopen = util.m_position.PriceOpen();
         double ask = util.m_symbol.Ask();
         double point = Point();
         PrintFormat("adding BUYING: bid: %lf, ask: %lf", util.m_symbol.Bid(), util.m_symbol.Ask());

         // open another order
         double lots = FindLotSize();
         if (!util.m_trade.Buy(lots, InpSymbol, util.m_symbol.Ask(), 0, 0)) {
            PrintFormat("Invalid buy order: %d", GetLastError());
            return;
         }
         
         gridStarted = true;
      }
   }
   else if (util.m_position.PositionType() == POSITION_TYPE_SELL) {
      if (util.m_symbol.Bid() > util.m_position.PriceOpen() + FindGridDistance() * Point() && 
          ((InpUseRSIFilter && rsiFilter.isOverbought(1)) || !InpUseRSIFilter) &&
          ((InpUseStochFilter && stochFilter.isOverbought()) || !InpUseStochFilter) &&   
          ((InpUseRibbonPriceOutsideRibbonFilter && ribbonFilter.IsPriceAboveRibbon()) || !InpUseRibbonPriceOutsideRibbonFilter)
      ) 
      {
         PrintFormat("adding SELLING: ask: %lf, ask: %lf", util.m_symbol.Ask(), util.m_symbol.Ask());

         // open another order
         double lots = FindLotSize();
         if (!util.m_trade.Sell(lots, InpSymbol, util.m_symbol.Bid(), 0, 0)) {
            PrintFormat("Invalid sell order: %d", GetLastError());
            return;
         }
         
         gridStarted = true;
      }
   }
}


double Grid::FindLotSize() {

   double lotSize = -1;

   if (PositionsTotal() == 0) {
      // initial lot
      double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      
      if (InpInitialLotMethod == INITIALLOT_PERCENTAGE) {
         lotSize = (accountBalance * (InpInitialLotPercentageOfBalance / 100) ) / ( (util.m_symbol.TickValue() * 10) / 0.01);
      }
      else {
         lotSize = InpInitialLot;
      }
      
      if (InpTakeProfitMethod == TAKEPROFIT_PERCENTAGE) {
         takeProfit = accountBalance * (InpTakeProfitInPercentageOfBalance / 100);
      }
      else if (InpTakeProfitMethod == TAKEPROFIT_FIXED) {
         if (originalLotSize > 0) {
            takeProfit = (InpTakeProfitInPoints / 10) * util.pricePerPip * originalLotSize;
         }
         else {
            takeProfit = (InpTakeProfitInPoints / 10) * util.pricePerPip * lotSize;
         }
      }
      
      stoploss = -(accountBalance * (InpStoplossInPercentageOfBalance / 100));

   } else {
      if (!util.m_position.SelectByIndex(PositionsTotal() - 1)) {
         return -1;
      }
      
      lotSize = util.m_position.Volume() * InpMultiplier;
   }
   
   if (lotSize < util.m_symbol.LotsMin()) {
      lotSize = util.m_symbol.LotsMin();
   }
   
   return NormalizeDouble(lotSize, 2);
}

void Grid::Update() {

   util.m_symbol.RefreshRates();
   
   if (InpUseRSIFilter) {
      rsiFilter.Update();
   }
   
   if (InpUseStochFilter) {
      stochFilter.Update();
   }

   if (InpUseRibbonPriceOutsideRibbonFilter) {
      ribbonFilter.Update();
   }
}

int Grid::FindGridDistance() {
   if (InpGridDistanceMethod == DISTANCE_FIXED) {
      return InpGridDistanceInPoints;
   }
   else if (InpGridDistanceMethod == DISTANCE_MULTIPLIER) {
      int sum = 0;
      for (int x = 1; x <= PositionsTotal(); x++) {
         sum += int(InpGridDistanceInPoints * InpGridMultiplierDistance);
      }
      return sum;
   }
   else if (InpGridDistanceMethod == DISTANCE_SEQUENCE) {
      return (int)distanceSequence[PositionsTotal() - 1];
   }
   
   return 0;
}

