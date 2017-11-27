#property copyright "Copyright 2017, SoeHoe.id"
#property link      "https://SoeHoe.id"
#property version   "1.00"
#property strict

enum pilihan {
  a=0, //Apple
  b=1, //Beat
  c=2  //Carrot
};

extern pilihan  NamaVariable      = 1;
extern int      TakeProfit        = 50;
input  int      StopLoss          = 100;
input  double   RiskPerOrder      = 0.1; //Risk Percent per Order
input  double   Lots              = 0.15;
input  double   Multiplier        = 1.2;
input  bool     UseFilterTime     = False;
extern string   EAComment         = "EA Jago";
input  color    Warna_Buy         = clrBlue;
input  color    Warna_Sell        = clrRed;
extern int      MA_Period         = 20;
input  int      ZZ_Depth          = 12;
input  int      ZZ_Deviation      = 5;
input  int      ZZ_BackStep       = 3;

ENUM_MA_METHOD      MA_Method         = MODE_EMA;
ENUM_APPLIED_PRICE  MA_Applied        = 0;

datetime MasaBerlaku       = D'2017.12.31 00:00:00';

//check SAR di atas atau di bawah
//jika SAR di atas maka hasil    = 2
//jika SAR di bawah maka hasil   = 1
int QnSAR(int shift=0){
   int result=0;
   double pSAR = iSAR(NULL,0,0.02,0.2,shift);
   if(pSAR<=Low[shift]) result = 1;
   if(pSAR>=High[shift]) result = 2;
return(result);}

//check harga ZZ berdasarkan posisi candle
double QnZZ(int shift=0){
   double result=iCustom(NULL,0,"ZigZag",ZZ_Depth,ZZ_Deviation,ZZ_BackStep,0,shift);
return(result);}

//mengetahui arah garis zz
//Jika arah garis ke atas maka hasil = 2
//Jika arah garis ke bawah maka hasil = 1
int QnSignalZZ(){
   int result  = 0;
   int cnt     = 0;
   double pZZ1 = 0;
   
   for(int i=0; i<Bars; i++){
      double pZZ = QnZZ(i);
      if(pZZ==0) continue;
      cnt++;
      if(cnt==1){
         pZZ1 = pZZ;
      }
      if(cnt==2){ //check di sini arah garis ZZ
         if(pZZ1>pZZ) result = 2; else result = 1;
         break;
      }
   }
return(result);}

//check posisi fractals terakhir
//Jika di atas maka hasil = 2
//Jika di bawah maka hasil = 1
int QnFractals(){
   int result = 0;
   for(int i=0; i<Bars; i++){
      double pFractalsAtas  = iFractals(Symbol(),0,1,i);
      double pFractalsBawah = iFractals(Symbol(),0,2,i);
      if(pFractalsAtas>0)  result = 2;
      if(pFractalsBawah>0) result = 1;
   }
return(result);}

//check warna AO
//jika merah = 2
//jika hijau = 1
int QnAO(int shift=0){
   int result = 0;
   double pAO0 = iAO(Symbol(),0,shift);
   double pAO1 = iAO(Symbol(),0,shift+1);
   if(pAO0>pAO1) result = 1; else result=2;
return(result);}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   //Alert(" ============ ");
   //QnMA();
    double totalLots = QnTotalLots("EURUSD");
    //Alert(totalLots);
    
    /*
    c = a + b
    Jika a = 5, dan b = 10, maka berapakah c?
    c = 5 + 10 = 15
    
    */
   int c=0;
   int a=5;
   int b=10;
   
   c = a + b;
   
   /*
   / bagi
   * kali
   - kurang
   + tambah
   % sisa bagi
   ++ tambah 1
   -- kurang 1
   */
   
   
   double pLow    = Low[1];
   double pHigh   = High[1];
   int    Size    = int((pHigh-pLow)/Point); //0.00001
   
   //Alert(Size);
   
   
//---
   return(INIT_SUCCEEDED);
  }



//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Comment("");
   
  }




//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   /*
   == sama dengan
   >  lebih besar
   <  lebih kecil
   >= lebih besar atau sama dengan
   <= lebih kecil atau sama dengan
   != tidak sama dengan
   || atau
   && dan
   ! tidak
   */
   
   QnDaftarLot();
   //QnComment();
   
   if( Volume[0]>1 ) return; //return = kembali, kembali ke awal. perintah di bawah tidak akan dieksekusi lagi
   //artinya perintah di bagian bawah ini hanya dieksekusi pada pembukaan candle saja
   
   if( Open[1]>Close[1]) Alert("Bearish");
   if( Open[1]<Close[1]) Alert("Bullsih");
   
   int signal = QnSignal();
   if(signal==0) return;
   //1 untuk buy, 2 untuk sell
   
   //OP_BUY    = 0
   //OP_SELL   = 1
   //OP_BUY_LIMIT = 2
   
   double pRSI = iRSI(NULL,0,20,PRICE_CLOSE,1);
   if(signal==1 && pRSI>50) return;
   if(signal==2 && pRSI<50) return;
   
   
   QnOrder(signal-1);
   
   
  }
//+------------------------------------------------------------------+
//=============================================================
//Jika garis MA berpotongan dengan ekor candle Bulish, maka BUY pada candle berikutnya.
//SL = Low candle perpotongan.
double QnMA(int shift){
   double result;
   result = iMA(Symbol(),0,MA_Period,0,MA_Method,MA_Applied,shift);
return(result);}
//=============================================================
//fungsi check candle bullish/bearsih
//jika bulish maka hasil = 1
//jika bearish maka hasil = 2
int QnBB(int shift=0){
   int result=0;
   if( Open[shift] < Close[shift]) result=1;
   if( Open[shift] > Close[shift]) result=2;
return(result);}
//=============================================================
//untuk check garis MA memotong ekor atau tidak
//Jika memotong ekor bawah & candle bulish maka hasil = 1
//Jika memotong ekor atas & candle bearish maka hasil = 2
int QnSignal(int shift=1){
   int result =false;
   int arah = QnBB(shift);
   double pMA = QnMA(shift);
   if(arah==1){
      if(pMA<=Open[shift] && pMA>=Low[shift]) result=1; //apakah MA cross ekor
   }
   if(arah==2){
      if(pMA>=Open[shift] && pMA<=High[shift]) result=2;
   }
return(result);}
//=============================================================
void QnOrder(int cmd){
   int ticket = OrderSend(Symbol(),cmd,Lots,0,0,0,0);
   //Alert(ticket," error: ",GetLastError());
}
//=============================================================
int QnPips(double n1, double n2 ){
   //sekumpulan perintah
   int result =  int(MathRound((n1-n2)/Point()));
   return(result);
}
//=============================================================
double QnTotalLots(string mySym){
   double result=0;
   for(int i=OrdersTotal()-1; i>=0; i--){
      if(   !OrderSelect(i,SELECT_BY_POS)
         || OrderSymbol()!= mySym
         || OrderMagicNumber()!=168) continue; //continue = lanjut ke urutan berikutnya
      result+=OrderLots();
   }
return(result);}
//=============================================================
void QnDaftarLot(){
   //Alert("Oninit");
   Comment("\n\nGBPUSD : ",QnTotalLots("GBPUSD"),
            "\nEURUSD : ",QnTotalLots("EURUSD"),
            "\nUSDJPY : ",QnTotalLots("USDJPY"),
            "\nEURJPY : ",QnTotalLots("EURJPY"),
            "\nUSDCHF : ",QnTotalLots("USDCHF"));
}
//=============================================================
void QnComment(){
   //Alert("Oninit");
   Comment("\n\nVolume :  ",Volume[0],
            "\nAccount : ",AccountNumber(),
            "\nAccount : ",AccountServer(),
            "\nAccount : ",AccountNumber(),
            "\nAccount : ",AccountNumber(),
            "\nBalance : ",AccountBalance());
}
//=============================================================
//Tugas
//buat SL = harga Low/High dari candle sebelumnya
//Tentukan lot berdasarkan risk reward. Max risk = 0.1% per 1 kali order. Reward = 1%.

void QnOrder2(int mycomm) {
   double modal=AccountEquity();
   double p_high_1=High[1];
   double p_low_1=Low[1];
   
   if(mycomm==OP_BUY){
      double mySL=p_low_1;
      //hitung berapa pips risk
      int    SLPoint     = QnPips(Ask,p_low_1);
      double SLMoney     = MarketInfo(Symbol(),MODE_TICKVALUE)*SLPoint;
      double Risk_Money  = (RiskPerOrder/100)*modal;
      double mylot        = Risk_Money/SLMoney;
      mylot=NormalizeDouble(mylot,2);
      Alert(mylot);
      
      
      double reward=(0.01*modal)/mylot*10;
      double myTP=Ask+(reward*Point);
      myTP=NormalizeDouble(myTP,Digits);
      int tiket=OrderSend(NULL,mycomm,mylot,Ask,3,mySL,myTP,"tugas",123,0,clrNONE);
   }
   
   if(mycomm==OP_SELL){
   double mySL=p_high_1;
   double mylot=(0.001*modal)/(((p_high_1-Bid)/Point)*10);
   mylot=NormalizeDouble(mylot,2);
   double reward=(0.01*modal)/mylot*10;
   double myTP=Bid-(reward*Point);
   myTP=NormalizeDouble(myTP,Digits);
   int tiket=OrderSend(NULL,mycomm,mylot,Bid,3,mySL,myTP,"tugas",123,0,clrNONE);
   
   }
} ///*///
