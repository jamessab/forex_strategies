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

   Util();   
   bool NewBar(ENUM_TIMEFRAMES timeframe);
   void CloseAllOrders();
   double ComputeStoploss(string symbol, ENUM_ORDER_TYPE direction, double stoplossInPoints);
   double ComputeTakeProfit(string symbol, ENUM_ORDER_TYPE direction, double takeProfitInPoints);
};


datetime ArrayTime[], LastTime;

Util::Util() {
   m_symbol.Name(InpSymbol); 
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

