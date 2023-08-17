//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
extern double Lots = 0.01;
extern int PipsCushion = 10; // Set to 0 for automatic calculation
extern int Risk = 10;
extern int MagicNumber = 999;
int slippage = 3; // Define slippage value here
color clrNone = clrNONE; // Define color value here
int OnInit() {
   if (!IsTesting()) {
      Print("This EA can only be run in the strategy tester.");
      return INIT_FAILED;
   }

   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
// Check if it's a new trading day
   if (TimeHour(TimeCurrent()) == 0 && TimeMinute(TimeCurrent()) == 0) {
      double H = High[1]; // Previous day's high
      double L = Low[1]; // Previous day's low
      double C = Close[1]; // Previous day's close
      double R4 = (H - L) * 1.1 / 2 + C;
      double R3 = (H - L) * 1.1 / 4 + C;
      double R2 = (H - L) * 1.1 / 6 + C;
      double R1 = (H - L) * 1.1 / 12 + C;
      double S1 = C - (H - L) * 1.1 / 12;
      double S2 = C - (H - L) * 1.1 / 6;
      double S3 = C - (H - L) * 1.1 / 4;
      double S4 = C - (H - L) * 1.1 / 2;
// Check if the current day's CPP lines are inside the previous day's CPP lines
      if (S4 > Low[1] && R4 < High[1]) {
// Buy Entry
         double buyEntryPrice = R3 + PipsCushion * Point;
         double stopLossBuy = Risk / 100.0 * AccountBalance() / (Lots * 100000.0);
         double takeProfitBuy = stopLossBuy * 2;
         OrderSend(Symbol(), OP_BUYSTOP, Lots, buyEntryPrice, 0, stopLossBuy, takeProfitBuy, "Buy Order", MagicNumber, 0, Blue);
      }
      if (R4 < High[1] && S4 > Low[1]) {
// Sell Entry
         double sellEntryPrice = S3 - PipsCushion * Point;
         double stopLossSell = Risk / 100.0 * AccountBalance() / (Lots * 100000.0);
         double takeProfitSell = stopLossSell * 2;
         OrderSend(Symbol(), OP_SELLSTOP, Lots, sellEntryPrice, 0, stopLossSell, takeProfitSell, "Sell Order", MagicNumber, 0, Red);
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
// Close any open orders when the strategy tester ends
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() == MagicNumber)
         OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), slippage, clrNone);
   }
}
//+------------------------------------------------------------------+
