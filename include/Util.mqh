//+------------------------------------------------------------------+
//|                                                         Util.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

class Util {

private:
   
protected:

public:
   CTrade            m_trade;
   CSymbolInfo       m_symbol;
   CPositionInfo     m_position;
   COrderInfo        m_order;
   CAccountInfo      m_account;

   double pricePerPip;
   
   Util();   
   void SetSymbol(string sym);
   bool NewBar(ENUM_TIMEFRAMES timeframe);
   bool NewBar2(ENUM_TIMEFRAMES timeframe);
   void CloseAllOrders();
   double ComputeStoploss(string symbol, ENUM_ORDER_TYPE direction, double stoplossInPoints);
   double ComputeTakeProfit(string symbol, ENUM_ORDER_TYPE direction, double takeProfitInPoints);
   double GetPLInMoney();
   double GetPLInPoints();
   //double ConvertPointsToMoney(string symbol, double points);
   //double ConvertMoneyToPoints(string symbol, double money);
};


datetime ArrayTime[], LastTime;
datetime ArrayTime2[], LastTime2;

Util::Util() {
   m_symbol.Name(InpSymbol); 

   double tickValue = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_VALUE);
   long digits = SymbolInfoInteger(InpSymbol, SYMBOL_DIGITS);
   double points = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);
   double pipModifier = MathPow(10, digits == 3 || digits == 5);
   pricePerPip = pipModifier * tickValue;
}

bool Util::NewBar(ENUM_TIMEFRAMES timeframe) {

   bool firstRun = false, newBar = false;

   ArraySetAsSeries(ArrayTime, true);
   CopyTime(Symbol(), timeframe, 0, 2, ArrayTime);

   if(LastTime == 0) firstRun = true;
   if(ArrayTime[0] > LastTime) {
      if(firstRun == false) newBar = true;
      LastTime = ArrayTime[0];
   }
   return newBar;
}

bool Util::NewBar2(ENUM_TIMEFRAMES timeframe) {

   bool firstRun = false, newBar = false;

   ArraySetAsSeries(ArrayTime2, true);
   CopyTime(Symbol(), timeframe, 0, 2, ArrayTime2);

   if(LastTime2 == 0) firstRun = true;
   if(ArrayTime2[0] > LastTime2) {
      if(firstRun == false) newBar = true;
      LastTime2 = ArrayTime2[0];
   }
   return newBar;
}


void Util::CloseAllOrders() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i)) { 
         PrintFormat("Closing all position: %ld", m_position.Ticket());
         m_trade.PositionClose(m_position.Ticket());
      }
   }
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(m_order.SelectByIndex(i)) {
         PrintFormat("Closing all order: %ld", m_order.Ticket());
         m_trade.OrderDelete(m_order.Ticket());
      }
   }
}


double Util::ComputeStoploss(string symbol, ENUM_ORDER_TYPE direction, double sl) {

   if (direction == ORDER_TYPE_BUY) {
      return NormalizeDouble(m_symbol.Bid() - sl * m_symbol.Point(), m_symbol.Digits());
   }
   else if (direction == ORDER_TYPE_SELL) {
      return NormalizeDouble(m_symbol.Ask() + sl * m_symbol.Point(), m_symbol.Digits());
   }
   else {
      return -1;
   }
}

double Util::ComputeTakeProfit(string symbol, ENUM_ORDER_TYPE direction, double tp) {

   if (direction == ORDER_TYPE_BUY) {
      return NormalizeDouble(m_symbol.Ask() + tp * m_symbol.Point(), m_symbol.Digits());
   }
   else if (direction == ORDER_TYPE_SELL) {
      return NormalizeDouble(m_symbol.Bid() - tp * m_symbol.Point(), m_symbol.Digits());
   }
   else {
      return -1;
   }
}


double Util::GetPLInMoney() {
   double pl = 0;

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (!PositionSelectByTicket(ticket)) {
         continue;
      }

      pl = pl + m_position.Profit() - MathAbs(m_position.Commission()) - MathAbs(m_position.Swap());
   }
   return pl;
}

double Util::GetPLInPoints() {
   double pl = 0;

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (!PositionSelectByTicket(ticket)) {
         continue;
      }

      if (m_position.PositionType() == POSITION_TYPE_BUY) {
         pl = pl + m_position.PriceCurrent() - m_position.PriceOpen();
      }
      else if (m_position.PositionType() == POSITION_TYPE_SELL) {
         pl = pl + m_position.PriceOpen() - m_position.PriceCurrent();
      }
   }
   return pl;
}

void Util::SetSymbol(string sym) {
   m_symbol.Name(sym); 
}


/*
double Util::ConvertPointsToMoney(string symbol, double points) {
   double pricePerPip = GetPricePerPip(symbol);
   
   return pricePerPip * (points / Point());
}

double Util::ConvertMoneyToPoints(string symbol, double money) {
   double pricePerPip = pricePerPip;
   return money / pricePerPip *  Point();
}
*/