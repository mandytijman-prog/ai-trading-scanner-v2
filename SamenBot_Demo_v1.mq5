//+------------------------------------------------------------------+
//| SamenBot_Demo_v1.mq5                                             |
//| Educational, demo-only EA. EMA pullback with closed-bar confirm.  |
//| No promise of profitability. Backtest before paper trading.       |
//+------------------------------------------------------------------+
#property strict
#property version "1.00"
#include <Trade/Trade.mqh>
CTrade trade;

input bool   EnableDemoOrders      = false;  // Starts in signal-only mode
input double RiskPerTradeEUR       = 10.0;   // Max planned risk in deposit currency (EUR account)
input double DailyLossLimitEUR     = 30.0;   // Stop new entries after this equity decline
input double MaxSpreadPoints       = 80.0;   // Broker-dependent, check XAUUSD specification
input int    FastEMA               = 20;
input int    SlowEMA               = 50;
input int    ATRPeriod             = 14;
input double ATRStopMultiplier     = 1.5;
input double TargetRR              = 2.0;
input ulong  MagicNumber           = 26112501;
input int    SlippagePoints        = 20;

int fastHandle=INVALID_HANDLE,slowHandle=INVALID_HANDLE,atrHandle=INVALID_HANDLE;
datetime lastClosedBar=0;
double dayStartEquity=0.0;
int dayStamp=-1;

int DateStamp(datetime dt)
{
   MqlDateTime s; TimeToStruct(dt,s);
   return s.year*10000+s.mon*100+s.day;
}

void RefreshDay()
{
   datetime now=TimeTradeServer();
   if(now<=0) now=TimeCurrent();
   int today=DateStamp(now);
   if(today!=dayStamp)
   {
      dayStamp=today;
      // Conservative for current EA uptime, NOT full FTMO day loss accounting.
      dayStartEquity=AccountInfoDouble(ACCOUNT_EQUITY);
      Print("New broker day. Baseline equity=",DoubleToString(dayStartEquity,2),
            ". This EA safety limit does not replace prop firm rules.");
   }
}

bool HasSymbolPosition()
{
   // Block all positions on this symbol, including manually opened trades.
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0 && PositionGetString(POSITION_SYMBOL)==_Symbol)
         return true;
   }
   return false;
}

bool DemoOnly()
{
   return (AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_DEMO);
}

bool CanOpenTrade()
{
   if(!EnableDemoOrders) { Print("SIGNAL ONLY: EnableDemoOrders=false"); return false; }
   if(!DemoOnly()) { Print("BLOCKED: demo accounts only"); return false; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
   { Print("Trading not enabled in terminal/EA settings"); return false; }
   if(AccountInfoString(ACCOUNT_CURRENCY)!="EUR")
   { Print("BLOCKED: RiskPerTradeEUR expects EUR deposit currency"); return false; }
   if(dayStartEquity-AccountInfoDouble(ACCOUNT_EQUITY)>=DailyLossLimitEUR)
   { Print("Daily equity stop triggered - no new entries"); return false; }
   if(HasSymbolPosition()) return false;
   double spread=(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;
   if(spread<0 || spread>MaxSpreadPoints)
   { Print("Spread too wide: ",spread," points"); return false; }
   return true;
}

double SizeForRisk(ENUM_ORDER_TYPE type,double openPrice,double sl)
{
   double lossAtOneLot=0.0;
   if(!OrderCalcProfit(type,_Symbol,1.0,openPrice,sl,lossAtOneLot))
   { Print("OrderCalcProfit failed: ",GetLastError()); return 0.0; }
   if(lossAtOneLot>=0) return 0.0;
   double desiredLots=RiskPerTradeEUR/(-lossAtOneLot);
   double minVol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxVol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0 || minVol<=0) return 0;
   double lots=MathFloor((desiredLots+1e-12)/step)*step;
   if(lots<minVol) { Print("Trade skipped: minimum lot exceeds planned risk"); return 0; }
   lots=MathMin(lots,maxVol);
   lots=NormalizeDouble(lots,8);
   double actualLoss=0.0;
   if(!OrderCalcProfit(type,_Symbol,lots,openPrice,sl,actualLoss)) return 0;
   if(actualLoss>=0 || -actualLoss>RiskPerTradeEUR+0.01) return 0;
   return lots;
}

int OnInit()
{
   if(FastEMA<=1 || SlowEMA<=FastEMA || ATRPeriod<=1 || ATRStopMultiplier<=0 || TargetRR<1 ||
      RiskPerTradeEUR<=0 || DailyLossLimitEUR<=0 || MaxSpreadPoints<=0)
      return INIT_PARAMETERS_INCORRECT;
   fastHandle=iMA(_Symbol,PERIOD_M15,FastEMA,0,MODE_EMA,PRICE_CLOSE);
   slowHandle=iMA(_Symbol,PERIOD_M15,SlowEMA,0,MODE_EMA,PRICE_CLOSE);
   atrHandle=iATR(_Symbol,PERIOD_M15,ATRPeriod);
   if(fastHandle==INVALID_HANDLE || slowHandle==INVALID_HANDLE || atrHandle==INVALID_HANDLE)
      return INIT_FAILED;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(SlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   RefreshDay();
   Print("SamenBot demo started; orders enabled=",EnableDemoOrders,". Attach to XAUUSD, M15.");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(fastHandle!=INVALID_HANDLE) IndicatorRelease(fastHandle);
   if(slowHandle!=INVALID_HANDLE) IndicatorRelease(slowHandle);
   if(atrHandle!=INVALID_HANDLE) IndicatorRelease(atrHandle);
}

void OnTick()
{
   RefreshDay();
   if(_Period!=PERIOD_M15) return;
   datetime closedTime=iTime(_Symbol,PERIOD_M15,1);
   if(closedTime<=0 || closedTime==lastClosedBar) return;
   lastClosedBar=closedTime;

   double fast[3],slow[3],atr[3];
   // CopyBuffer with count=3 stores oldest at index 0; index 1 = closed bar.
   if(CopyBuffer(fastHandle,0,0,3,fast)<3 || CopyBuffer(slowHandle,0,0,3,slow)<3 ||
      CopyBuffer(atrHandle,0,0,3,atr)<3) return;
   double f=fast[1], s=slow[1], a=atr[1];
   if(a<=0) return;
   double c1=iClose(_Symbol,PERIOD_M15,1),o1=iOpen(_Symbol,PERIOD_M15,1);
   double h2=iHigh(_Symbol,PERIOD_M15,2),l2=iLow(_Symbol,PERIOD_M15,2);
   double c2=iClose(_Symbol,PERIOD_M15,2);
   // Pullback: previous bar tested EMA20 area; confirmation close crosses previous high/low.
   bool testedEMA=(l2<=fast[0] && h2>=fast[0]);
   bool buy=(f>s && testedEMA && c2<=fast[0] && c1>h2 && c1>o1);
   bool sell=(f<s && testedEMA && c2>=fast[0] && c1<l2 && c1<o1);
   if(!buy && !sell) return;
   ENUM_ORDER_TYPE type=buy?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   Print("Signal ",buy?"BUY":"SELL"," at ",TimeToString(closedTime)," price ",DoubleToString(c1,_Digits));
   if(!CanOpenTrade()) return;

   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double openPrice=buy?ask:bid;
   double minStop=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point;
   double dist=MathMax(a*ATRStopMultiplier,minStop+2*_Point);
   double sl=NormalizeDouble(buy?openPrice-dist:openPrice+dist,_Digits);
   double tp=NormalizeDouble(buy?openPrice+dist*TargetRR:openPrice-dist*TargetRR,_Digits);
   double lots=SizeForRisk(type,openPrice,sl);
   if(lots<=0) return;
   double margin=0;
   if(!OrderCalcMargin(type,_Symbol,lots,openPrice,margin) ||
      margin>AccountInfoDouble(ACCOUNT_MARGIN_FREE))
   { Print("Insufficient free margin"); return; }
   bool placed=buy?trade.Buy(lots,_Symbol,0,sl,tp,"SamenBot demo"):
                  trade.Sell(lots,_Symbol,0,sl,tp,"SamenBot demo");
   if(!placed) Print("Trade failed: ",trade.ResultRetcode()," ",trade.ResultRetcodeDescription());
}
