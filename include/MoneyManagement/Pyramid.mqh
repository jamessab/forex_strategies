//+------------------------------------------------------------------+
//|                                                Pyramid.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#include "../Filters/RSIFilter.mqh"
#include "../Filters/StochFilter.mqh"
#include "../Filters/SpreadFilter.mqh"
#include "../Filters/SupertrendFilter.mqh"

input bool InpUsePyramid = true;
input int InpPyramidMaxPositions = 10;
input double InpPyramidLotPercentageOfBalance = 1.0;
input int InpPyramidInitialStoplossInPoints = 300;
input double InpPyramidDistanceInPoints = 300;

class Pyramid {

private:
   Util util;
   RSIFilter rsiFilter;
   StochFilter stochFilter;
   SpreadFilter spreadFilter;
   SupertrendFilter supertrendFilter;
   double stoploss;
   
public:

   void HandlePyramid();
   double FindLotSize(int direction);
   int HandleOnInit();
   void Update();
   
   bool pyramidStarted;
};

int Pyramid::HandleOnInit() {
   if (rsiFilter.HandleOnInit() < 0) {
      return -1;
   }
   if (stochFilter.HandleOnInit() < 0) {
      return -1;
   }
   
   if (spreadFilter.HandleOnInit() < 0) {
      return -1;
   }

   if (supertrendFilter.HandleOnInit() < 0) {
      return -1;
   }
   return INIT_SUCCEEDED;
}

void Pyramid::HandlePyramid() {
   if (PositionsTotal() == 0) {
      return;
   }

   util.m_symbol.RefreshRates();
   
   rsiFilter.Update();
   stochFilter.Update();
   supertrendFilter.Update();
   

   util.m_position.SelectByIndex(PositionsTotal() - 1);
   
   if (pyramidStarted && util.m_position.PositionType() == POSITION_TYPE_BUY && util.m_symbol.Bid() <= stoploss) {
      util.CloseAllOrders();
      pyramidStarted = false;
      return;
   }
   else if (pyramidStarted && util.m_position.PositionType() == POSITION_TYPE_SELL && util.m_symbol.Ask() >= stoploss) {
      util.CloseAllOrders();
      pyramidStarted = false;
      return;
   }

   if (util.m_position.PositionType() == POSITION_TYPE_BUY && PositionsTotal() < InpPyramidMaxPositions) {
      if (util.m_symbol.Ask() > util.m_position.PriceOpen() + InpPyramidDistanceInPoints * Point() + 0.0001 && 
         ((InpUseSupertrendFilter && supertrendFilter.isBullish()) || !InpUseSupertrendFilter) && 
         ((InpUseRSIFilter && rsiFilter.isOversold()) || !InpUseRSIFilter) &&
         ((InpUseStochFilter && stochFilter.isOversold()) || !InpUseStochFilter) &&
         spreadFilter.passes()) 
      {
         double priceopen = util.m_position.PriceOpen();
         double ask = util.m_symbol.Ask();
         double point = Point();
         PrintFormat("adding to buy. priceOpen: %f, ask: %f, InpDistance: %f, point: %f", util.m_position.PriceOpen(), util.m_symbol.Ask(), InpPyramidDistanceInPoints, Point());
      
         // open another order
         double lots = FindLotSize(POSITION_TYPE_BUY);
         if (!util.m_trade.Buy(lots, symbol, util.m_symbol.Ask(), 0, 0)) {
            PrintFormat("Invalid buy order: %d", GetLastError());
            return;
         }
         
         Print("Pyramid started");
         pyramidStarted = true;
      }
   }
   else if (util.m_position.PositionType() == POSITION_TYPE_SELL && PositionsTotal() < InpPyramidMaxPositions) {
      if (util.m_symbol.Bid() < util.m_position.PriceOpen() - InpPyramidDistanceInPoints * Point() - 0.0001 && 
          ((InpUseSupertrendFilter && supertrendFilter.isBearish()) || !InpUseSupertrendFilter) &&
          ((InpUseRSIFilter && rsiFilter.isOverbought()) || !InpUseRSIFilter) &&
          ((InpUseStochFilter && stochFilter.isOverbought()) || !InpUseStochFilter) &&      
          spreadFilter.passes()) 
      {
         PrintFormat("adding to sell. priceOpen: %f, bid: %f, InpDistance: %f, point: %f", util.m_position.PriceOpen(), util.m_symbol.Bid(), InpPyramidDistanceInPoints, Point());
         // open another order
         double lots = FindLotSize(POSITION_TYPE_SELL);
         if (!util.m_trade.Sell(lots, symbol, util.m_symbol.Bid(), 0, 0)) {
            PrintFormat("Invalid sell order: %d", GetLastError());
            return;
         }
         
         Print("Pyramid started");
         pyramidStarted = true;
      }
   }
   
   util.m_position.SelectByIndex(PositionsTotal() - 1);
  
   if (PositionsTotal() >= 2) {
      // if here, then see if we need to adjust the stoploss (trailing)
      if (util.m_position.PositionType() == POSITION_TYPE_BUY && 
         util.m_symbol.Bid() - InpPyramidDistanceInPoints * Point() > stoploss) {
            double b = util.m_symbol.Bid();
            double s = InpPyramidDistanceInPoints * Point();
            stoploss = util.m_symbol.Bid() - (InpPyramidDistanceInPoints / 2) * Point() + 0.0001;
      } 
      else if (util.m_position.PositionType() == POSITION_TYPE_SELL && 
         util.m_symbol.Ask() + InpPyramidDistanceInPoints * Point() < stoploss) {
            stoploss = util.m_symbol.Ask() + (InpPyramidDistanceInPoints / 2) * Point() - 0.0001;
      }
   }
}



double Pyramid::FindLotSize(int direction) {

   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lotSize = (accountBalance * (InpPyramidLotPercentageOfBalance / 100) ) / ( (util.m_symbol.TickValue() * 10) / 0.01);
   
   if (PositionsTotal() == 0) {
      if (direction == POSITION_TYPE_BUY) {
         stoploss = util.m_symbol.Bid() - InpPyramidInitialStoplossInPoints * Point();
      } else {
         stoploss = util.m_symbol.Ask() + InpPyramidInitialStoplossInPoints * Point();
      }
   }
   
   if (lotSize > 0.1) {
      Print("A");
   }
   
   return NormalizeDouble(lotSize, 2);
}

void Pyramid::Update() {
   util.m_symbol.RefreshRates();
}

