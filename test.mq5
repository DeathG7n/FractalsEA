#include <Trade\Trade.mqh>

CTrade trade;
double stopLoss;
double takeProfit;
int handle_21;
int handle_200;
int rsiHandle;
int fractalHandle;
double currentPrice;
bool isUptrend;
bool isBull;
bool isBull2;
bool buySignal;
bool sellSignal;
float lotSize = 0.001;
int ticketArray[];
int totalPositions;
double upperFractal, lowerFractal;
  
int OnInit()
  {
   Trade();
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
  {
  }
  
void OnTick()
  {

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Trade(){
      while (true){
         double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         trade.SetExpertMagicNumber(123456);
         totalPositions = PositionsTotal();
         //Get Moving Average
         handle_21 = iMA(_Symbol,_Period,21,0,MODE_SMMA,PRICE_CLOSE);
         handle_200 = iMA(_Symbol,_Period,200,0,MODE_SMMA,PRICE_CLOSE);
         double ma_21[], ma_200[];
         CopyBuffer(handle_21,MAIN_LINE,0,3,ma_21);
         CopyBuffer(handle_200,MAIN_LINE,0,3,ma_200);
         double fastMa = ma_21[2];
         double slowMa = ma_200[2];
         //Get Fractals
         fractalHandle = iFractals(_Symbol, PERIOD_CURRENT);
         double fractal[], lower[];
         CopyBuffer(fractalHandle, UPPER_LINE, 2, 1, fractal);
         CopyBuffer(fractalHandle, LOWER_LINE, 2, 1, lower);
         //Get Current Candles
         double lastCandleOpen = iOpen(NULL,PERIOD_CURRENT,1);
         double lastCandleClose = iClose(NULL,PERIOD_CURRENT,1);
         double currentCandleOpen = iOpen(NULL,PERIOD_CURRENT,0);
         double currentCandleClose = iClose(NULL,PERIOD_CURRENT,0);
         datetime currentTime = TimeCurrent();
         string currentTimeString = TimeToString(currentTime, TIME_SECONDS);
         string seconds = StringSubstr(currentTimeString,6,-1);
         int timeLeft = 60 - StringToInteger(seconds) - 3 + "000";
         //Determine current trend
         if(fastMa > slowMa){
            isUptrend = true;
         } else{
            isUptrend = false;
         }
         if(lastCandleClose > lastCandleOpen){
            isBull2 = true;
         } else{
            isBull2 = false;
         }
         if (fractal[0] != DBL_MAX){
            sellSignal = true;
            upperFractal = fractal[0];
         } else {
            sellSignal = false;
         }
         if (lower[0] != DBL_MAX){
            buySignal = true;
            lowerFractal = lower[0];
         } else {
            buySignal = false;
         }
         Print(lowerFractal," " , lower[0], " 21 moving average: " , fastMa, " 200 moving average:  " , slowMa, " " , upperFractal, " " , fractal[0]);
         if (isUptrend == true){
            if(price > upperFractal){
               Sleep(timeLeft);
               rsiHandle = iRSI(_Symbol,PERIOD_CURRENT,14,PRICE_CLOSE);
               double rsi[];
               CopyBuffer(rsiHandle,MAIN_LINE,0,1,rsi);
               currentCandleClose = iClose(NULL,PERIOD_CURRENT,0);
               if(currentCandleClose > currentCandleOpen){
                  isBull = true;
               } else{
                  isBull = false;
               }
               if (isBull == true && totalPositions == 0){
                  if(lowerFractal < upperFractal){
                     Print("Buy and stop loss at :", stopLoss);
                     stopLoss = lowerFractal;
                     trade.Buy(lotSize,_Symbol,0.0,stopLoss,0.0);
                  }
               }
            }
         } else{
            if(price < lowerFractal){// Check if price is close to the 21 period moving average
               Sleep(timeLeft);
               rsiHandle = iRSI(_Symbol,PERIOD_CURRENT,14,PRICE_CLOSE);
               double rsi[];
               CopyBuffer(rsiHandle,MAIN_LINE,0,1,rsi);
               currentCandleClose = iClose(NULL,PERIOD_CURRENT,0);
               if(currentCandleClose > currentCandleOpen){
                  isBull = true;
               } else{
                  isBull = false;
               }
               if (isBull == false && totalPositions == 0){
                  if(upperFractal > lowerFractal){
                     stopLoss = upperFractal;
                     Print("Sell and stop loss at :", stopLoss);
                     trade.Sell(lotSize,_Symbol,0.0,stopLoss,0.0);
                  }
               }
            }
         }
         for (int i = 0; i < totalPositions; i++) {
            // Retrieve the ticket number of the position
            ulong ticket = PositionGetTicket(i);
            // Retrieve other position information using the ticket number
             double positionVolume = PositionGetDouble(POSITION_VOLUME);
             double positionPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
             double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
             double positionProfit = PositionGetDouble(POSITION_PROFIT);
             double pips = positionProfit/positionVolume;
             // Output the position information
             Print("Position ", i+1);
             Print("Ticket: ", ticket);
             Print("Volume: ", positionVolume);
             Print("Price: ", positionPrice);
             Print("Open Price: ", openPrice);
             Print("Profit: ", positionProfit);
             Print("Pips: ",  pips);
             Print("============================");
             if (isUptrend == true){
                if (pips >= 500){
                  Print("Trail Stop Loss");
                  trade.PositionModify(ticket,openPrice + 100,openPrice + 1000);
                }
             } else{
                 if (pips >= 500){
                  Print("Trail Stop Loss");
                  trade.PositionModify(ticket,openPrice - 100,openPrice - 1000);
                }
             }
         }
         Sleep(1000);
      }
  }
