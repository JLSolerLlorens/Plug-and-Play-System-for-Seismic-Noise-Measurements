/*Plug-and-Play Acquisition system is an Arduino program developed to 
 * record seismic noise with a low-cost system.
 * Last update: 11/06/2019
 * Email contact: juanjo@dfists.ua.es, jl.soler@ua.es*/

#include <TimeLib.h>
#include <SdFat.h>
#include <Wire.h>
#include "RTClib.h"

#define RECLOG 1
//#define DEBUG 1 //if you uncomment this line, you will see the debug messages by a serial monitor
//#ifdef DEBUG  #endif

#define BUF_SZ   400
char ser_req[BUF_SZ] = {0}; 
int req_index = 0; 

RTC_DS3231 rtc;

int segundo, minuto, hora, dia, mes;
long anio;
DateTime HoraFecha;
char monthsOfYear[12][4]= {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};


SdFat sd;

const char pc = ';';
volatile unsigned long preTime;
volatile unsigned long tnow;
volatile unsigned long ini;

int c;
int a;

int sampling_frequency;
int gain;
int muestras;
bool buzzerActive=false;

const int chipSelect = 4;

File configFile;
File dataFile;
File logFile;


char nomConFile[12] = "ConF.txt";
char nomDatFile[40] = "";//datetime+extension=21characters site max longitude is 19 characters //i.e. Pilar_dela_horadada

const size_t LINE_DIM = 100;
char line[LINE_DIM]="sample_rate,gain,voltge_gain,samples,ch1,ch2,ch3,ch4,ch5,ch6,ch7,ch8,ch9,ch10,ch11,ch12,site";

bool serialtimeout = false;
bool PcMode = false;
bool endAcquisition = false;
bool writeSD=false;
bool startAcquisition=false;


int pinspeaker = 9;

volatile float s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12 = 0;
byte ch1, ch2, ch3, ch4, ch5, ch6, ch7, ch8, ch9, ch10, ch11, ch12;
float voltage_gain;


void setup()
{
  Serial.begin(115200);
  sd.begin(chipSelect, SPI_HALF_SPEED);
  rtc.begin();

  pinMode(pinspeaker, OUTPUT);

  analogReadResolution (12);
  REG_ADC_MR= (REG_ADC_MR & 0xFF0FFFFF) | 0x00B00000;
  ADC->ADC_WPMR &= ~(1 << ADC_WPMR_WPEN); //Unblock register

  ADC->ADC_COR = 0x0000FFFF; //Set single ended mode and offset to all chanels
  #ifdef DEBUG  
    Serial.println("Wait 20 seconds before start automatic acquisition");
  #endif
  unsigned long tOutIni = millis();
  while (Serial.available() == 0 & !serialtimeout) {
    #ifdef DEBUG
      Serial.println("Waiting serial communication");
    #endif
    delay(100);
    if ((millis() - tOutIni) > 20000) //wait 20 seconds (20000 miliseconds) for serial communication, after that enter plug and play mode
      serialtimeout = true;
  }

  if (!serialtimeout) 
  {
    #ifdef DEBUG
      Serial.println("Enter PC configuration mode");
    #endif
    PcMode = true;
    if(Serial.available())
      while (Serial.available())  // While data is available to read, read it.
        char val = Serial.read();
 
  }
  else
  {
    #ifdef DEBUG
      Serial.println("Enter Plug and Play Mode");
    #endif
    //When Plug and Play mode is started, the system play a sound during 5 seconds.
    for(int i=0;i<500;i++)
    {        
      digitalWrite(pinspeaker,HIGH);
      delayMicroseconds(536);//1136
    
      digitalWrite(pinspeaker,LOW);
      delayMicroseconds(536);//1136
    
      digitalWrite(pinspeaker,HIGH);
      delayMicroseconds(1836);
    
      digitalWrite(pinspeaker,LOW);
      delayMicroseconds(1836);
    
    }
  }
}

void loop() 
{
  if (!endAcquisition)
  {
    if (PcMode)
    {
      c=0;
      #ifdef DEBUG
        Serial.println("PCMODE");
      #endif
      for( int i = 0; i < sizeof(nomDatFile);  ++i )
        nomDatFile[i] = (char)0;
      delay(100);
      while (Serial.available() == 0) {
        delay(10);
        //wait for a serial configuration parameters: 100 1 Site_date_time;
        //100 1 0.00080566 600 1 1 1 0 0 0 0 0 0 0 0 0 0 1Petrer_16May2019_105024;
        //sample_rate   gain  voltge_gain   samples   Active:ch1...ch12 WriteSD     Start Acquisition     FileName    
        //100           1     3.3/4096      600       1 1 ... 0 0     1 Yes:1/No:0  Yes:1/No:0            Site_date_time;
      }
      if (Serial.available() > 0)
      {
        // look for the next valid integer in the incoming serial stream:
        sampling_frequency = Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(sampling_frequency, DEC);
        #endif
        gain = Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(gain, DEC);
        #endif
        voltage_gain=Serial.parseFloat();
        #ifdef DEBUG  
          Serial.println(voltage_gain,8);
        #endif
        muestras = Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(muestras, DEC);
        #endif
        ch1=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch1);
        #endif
        ch2=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch2);
        #endif
        ch3=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch3);
        #endif
        ch4=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch4);
        #endif
        ch5=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch5);
        #endif
        ch6=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch6);
        #endif
        ch7=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch7);
        #endif
        ch8=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch8);
        #endif
        ch9=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch9);
        #endif
        ch10=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch10);
        #endif
        ch11=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch11); 
        #endif
        ch12=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(ch12);
        #endif
        writeSD=Serial.parseInt();
        #ifdef DEBUG  
          Serial.println(writeSD);
        #endif
        startAcquisition=Serial.parseInt();
        Serial.readBytesUntil(';', nomDatFile, 39);
        #ifdef DEBUG
          Serial.println(nomDatFile);
        #endif
        sprintf(nomDatFile,"%s%s",nomDatFile,".saf");
        #ifdef DEBUG
          Serial.println(startAcquisition);   
          Serial.println(nomDatFile);
        #endif
        #ifdef RECLOG            
          SdFile::dateTimeCallback(dateTime);
          logFile=sd.open("log.txt", O_CREAT | O_WRITE | O_EXCL);
          logFile.println(sampling_frequency, DEC);
          logFile.println(gain, DEC);
          logFile.println(voltage_gain,8);
          logFile.println(muestras, DEC);
          logFile.println(ch1);
          logFile.println(ch2);
          logFile.println(ch3);
          logFile.println(ch4);
          logFile.println(ch5);
          logFile.println(ch6);
          logFile.println(ch7);
          logFile.println(ch8);
          logFile.println(ch9);
          logFile.println(ch10);
          logFile.println(ch11);
          logFile.println(ch12);
          logFile.println(writeSD);
          logFile.println(startAcquisition);   
          logFile.println(nomDatFile);
          logFile.close();
        #endif
        delay(100);
        Serial.read();
        delay(100);
        if (Serial.read() == -1)
        {
          Serial.println(sampling_frequency, DEC);
          writeConfigFile();
          if(startAcquisition)
          {       
            #ifdef DEBUG
              Serial.println("startAcquisition");
            #endif
            if(writeSD)
              createDataFile();
            recordData();
            if(writeSD)
              dataFile.close();
          }
        }
      }
    }
    else //if PcMode is false, acquisition may be done by configuration file
    {
      sprintf(nomDatFile,"%s","");
      if (sd.exists(nomConFile))
      {
        #ifdef DEBUG
          Serial.println("File exists");
        #endif
        configFile = sd.open("ConF.txt", FILE_READ);

        if (configFile)//if configFile is available, read it
        {
          #ifdef DEBUG
            Serial.println("File is available to read");
          #endif
          while (configFile.available())
          {
            //Read header line //sample_rate,gain,voltge_gain,samples,ch1,ch2,ch3,ch4,ch5,ch6,ch7,ch8,ch9,ch10,ch11,ch12,WriteSD
            configFile.fgets(line, sizeof(line));
            Serial.write(line);

            sampling_frequency = configFile.readStringUntil(',').toInt();
            gain = configFile.readStringUntil(',').toInt();
            voltage_gain=configFile.readStringUntil(',').toFloat();
            muestras = configFile.readStringUntil(',').toInt();
            ch1=configFile.readStringUntil(',').toInt();
            ch2=configFile.readStringUntil(',').toInt();
            ch3=configFile.readStringUntil(',').toInt();
            ch4=configFile.readStringUntil(',').toInt();
            ch5=configFile.readStringUntil(',').toInt();
            ch6=configFile.readStringUntil(',').toInt();
            ch7=configFile.readStringUntil(',').toInt();
            ch8=configFile.readStringUntil(',').toInt();
            ch9=configFile.readStringUntil(',').toInt();
            ch10=configFile.readStringUntil(',').toInt();
            ch11=configFile.readStringUntil(',').toInt();
            ch12=configFile.readStringUntil(',').toInt();
            configFile.readBytesUntil('\r', nomDatFile, 40);
            SetNomDateTime();
            writeSD=1;
            #ifdef DEBUG
              Serial.println(nomDatFile);
              Serial.println(sampling_frequency, DEC);
              Serial.println(gain, DEC);
              Serial.println(voltage_gain,8);
              Serial.println(muestras, DEC);
              Serial.println(ch1);
              Serial.println(ch2);
              Serial.println(ch3);
              Serial.println(ch4);
              Serial.println(ch5);
              Serial.println(ch6);
              Serial.println(ch7);
              Serial.println(ch8);
              Serial.println(ch9);
              Serial.println(ch10);
              Serial.println(ch11);
              Serial.println(ch12);
              Serial.println(nomDatFile);
            #endif
            
          }
        }
        configFile.close();
        createDataFile();
        if (dataFile)
        {
          #ifdef DEBUG
            Serial.println("Go to record data");
          #endif
          recordData();
          dataFile.close();
          #ifdef DEBUG
            Serial.println("Data file saved succesfully");
          #endif
        }
        else
        {
          #ifdef DEBUG
            Serial.println("Error open file for record data");
          #endif
        }
        endAcquisition = true;
        writeSD=0;
      }
      else
      {
        #ifdef DEBUG
          Serial.println("File does not exist");
        #endif
      }

    }
    if (c > muestras)
    {
      #ifdef DEBUG  
        Serial.println("C>muestras");
      #endif
      endAcquisition = true;
    }
  }//end if (endAcquisition)
  else
  {
    buzzer();
  }
}//end loop

void serialEvent() 
{
  char val = Serial.read();
  ser_req[req_index] = val;          // save Serial request character
  req_index++;
  while (val!='\n')  // If data is available to read.
  { 
    if(Serial.available())
    {
      val = Serial.read();
      if(val!='\n')
      {
        ser_req[req_index] = val;          // save Serial request character
        req_index++; 
      }
    }
  }
  Serial.flush();
  #ifdef DEBUG
    Serial.println("Received data: ");
    Serial.println(ser_req);  
  #endif
  if(StrContains(ser_req, "1"))  
  {
    #ifdef DEBUG
      Serial.println("Received 1");
    #endif
    buzzerActive=false;
    if (!endAcquisition)
    {
      c=muestras+1; //Stop acquisition
      endAcquisition=true;
    }
  }
  else
  {
    if(StrContains(ser_req,"USB"))
    {
      #ifdef DEBUG
        Serial.println("Received USB");
      #endif
      PcMode = true;
      endAcquisition=false;
      buzzerActive=false;
    }
  }
  req_index=0;
  StrClear(ser_req, BUF_SZ);
}
void writeConfigFile()
{
    #ifdef DEBUG
      Serial.println("writeConfigFile");
      Serial.println("File conf will be overwrited");
    #endif
    sd.remove(nomConFile);
    SdFile::dateTimeCallback(dateTime);
    configFile=sd.open("ConF.txt", O_CREAT | O_WRITE | O_EXCL);
    
    if (configFile)//if configFile is created, write parameters on it
    {
      #ifdef DEBUG
        Serial.println("ConfigFile has been created successfully");
      #endif
      configFile.println(line);
      configFile.print(String(sampling_frequency) + "," + String(gain) + "," + String(voltage_gain,8) + "," + String(muestras)+ "," +String(ch1)+"," +String(ch2)+"," +String(ch3)+"," +String(ch4)+"," +String(ch5)+"," +String(ch6)+"," +String(ch7)+"," +String(ch8)+"," +String(ch9)+"," +String(ch10)+"," +String(ch11)+"," +String(ch12)+",");
      for (int i=0;i<sizeof(nomDatFile)-17;i++)
      {
        if (nomDatFile[i]!='_')
          configFile.print(nomDatFile[i]);
        else  
          i=sizeof(nomDatFile);
      }
      configFile.print('\r');
    }
    configFile.close();
    #ifdef DEBUG
      Serial.println("ConfigFile was closed");
    #endif
}

void createDataFile()
{
  if (sd.exists(nomDatFile))
  {
    sd.remove(nomDatFile);
  }
  SdFile::dateTimeCallback(dateTime);
  dataFile.open(nomDatFile, O_CREAT | O_WRITE | O_EXCL);
  
  dataFile.println("SESAME ASCII data format (saf) v. 1   (this line must not  be modified)");
  dataFile.println("SAMP_FREQ = " + String(sampling_frequency));
  dataFile.println("NDAT = " + String(muestras));
  dataFile.println("VOLTAGE GAIN = " + String(voltage_gain,8)); //  VOLTAGE GAIN = 0.00080566
  dataFile.print("START_TIME = ");
  dataFile.println(nomDatFile); //  START_TIME = 20May2019_131046 (example)
  dataFile.println("UNITS = volts");
  dataFile.print("Recording channels : ");
  if(ch1)
    dataFile.print(" 1 ");
  if(ch2)
    dataFile.print(" 2 ");
  if(ch3)
    dataFile.print(" 3 ");
  if(ch4)
    dataFile.print(" 4 ");
  if(ch5)
    dataFile.print(" 5 ");
  if(ch6)
    dataFile.print(" 6 ");
  if(ch7)
    dataFile.print(" 7 ");  
  if(ch8)
    dataFile.print(" 8 ");
  if(ch9)
    dataFile.print(" 9 ");
  if(ch10)
    dataFile.print(" 10 ");
  if(ch11)
    dataFile.print(" 11 ");
  if(ch12)
    dataFile.print(" 12 ");
  dataFile.print("\r\n");  
  //dataFile.println("CH0_ID = S Z");
  //dataFile.println("CH1_ID = S N");
  //dataFile.println("CH2_ID = S E");
  dataFile.println("####------------------------------------------- ");  
}

void recordData()
{
  setGain();
  c = 1;
  preTime = 0;
  ini = millis ();
  String serialData="";
  while (c <= muestras)
  {
    tnow = millis () - ini;
    if (tnow - preTime >= 1000 / sampling_frequency)
    {
      preTime = preTime + 1000/sampling_frequency;
      Serial.print (tnow);
      //serialData=tnow;
      
      if(ch1)
      {
        s1 = analogRead (A0)*voltage_gain;
        if(writeSD)
          dataFile.print("\t" + String(s1,5));
        //serialData=serialData+pc+String(s1,5);
        serialData="\t"+String(s1,5);
      }
      if(ch2)
      {
        s2 = analogRead (A1)*voltage_gain;
        if(writeSD)
          dataFile.print("\t" + String(s2,5));
        //serialData=serialData+pc+String(s2,5);
        serialData="\t"+String(s2,5);
 
      }
      if(ch3)
      {
        s3 = analogRead (A2)*voltage_gain;
        if(writeSD)
         dataFile.print("\t" + String(s3,5));
        serialData="\t"+String(s3,5);
      }
      if(ch4)
      {
        s4 = analogRead (A3)*voltage_gain;
        if(writeSD)
         dataFile.print("\t" + String(s4,5));
        serialData="\t"+String(s4,5);
      }
      if(ch5)
      {
        s5 = analogRead (A4)*voltage_gain;
        if(writeSD)
          dataFile.print("\t" + String(s5,5));
        serialData="\t"+String(s5,5);
      }
      if(ch6)
      {
        s6 = analogRead (A5)*voltage_gain;
        if(writeSD)
          dataFile.print("\t" + String(s6,5));
        serialData="\t"+String(s6,5);
      }
      if(ch7)
      {
        s7 = analogRead (A6)*voltage_gain;
        if(writeSD)
          dataFile.print("\t" + String(s7,5));
        serialData="\t"+String(s7,5);
      }
      if(ch8)
      {  
        s8 = analogRead (A7)*voltage_gain;
        if(writeSD)
          dataFile.print("\t" + String(s8,5));
        serialData="\t"+String(s8,5);
      }
      if(ch9)
      {
        s9 = analogRead (A8)*voltage_gain;
        if(writeSD)
          dataFile.print("\t" + String(s9,5));       
        serialData="\t"+String(s9,5);
      }
      if(ch10)
      {
        s10 = analogRead (A9)*voltage_gain;
        if(writeSD)
          dataFile.print("\t" + String(s10,5));
        serialData="\t"+String(s10,5);
      }
      if(ch11)
      {
        s11 = analogRead (A10)*voltage_gain;
        if(writeSD)
          dataFile.print("\t" + String(s11,5));
        serialData="\t"+String(s11,5);
      }
      if(ch12)
      {
        s12 = analogRead (A11)*voltage_gain;
        if(writeSD)
          dataFile.print("\t" + String(s12,5));
        serialData="\t"+String(s12,5);
      }
      if(writeSD)
        dataFile.print("\r\n");
      Serial.println(serialData);
      c = c + 1;
    }
    if (Serial.available() > 0) // If data is available to read.
    { 
      serialEvent();
    }
  }
  buzzerActive=true;
}

void setGain()
{
  switch (gain)
  {
    case 1:
      ADC->ADC_CGR = 0x00000000; // gain 1
      break;
    case 2:
      ADC->ADC_CGR = 0xAAAAAAAA; // gain 2
      break;
    case 4:
      ADC->ADC_CGR = 0xFFFFFFFF; // gain 4
      break;
    default:
      ADC->ADC_CGR = 0x00000000; // gain 1
      break;
  }

  /*set STARTUP time ADC to a smaller number,*/
  unsigned long reg;
  REG_ADC_MR = (REG_ADC_MR & 0xFFF0FFFF) | 0x00020000;
  reg = REG_ADC_MR;
}
void buzzer()
{
    if (buzzerActive)
    {
      #ifdef DEBUG
        Serial.println("BuzzerActive");
      #endif
      digitalWrite(pinspeaker,HIGH);
      delayMicroseconds(1136);
      digitalWrite(pinspeaker,LOW);
      delayMicroseconds(1136);
      if (Serial.available() > 0) // If data is available to read.
      { 
        serialEvent();
      }
    }
}
void SetNomDateTime () 
{
  HoraFecha = rtc.now();
  segundo = HoraFecha.second();
  minuto = HoraFecha.minute();
  hora = HoraFecha.hour();
  dia = HoraFecha.day();
  mes = HoraFecha.month();
  anio = HoraFecha.year();
  //If system is in plug and play mode, set date and time values to construct file name
  if(!PcMode)
  {
    String Sdia="00";
    String Shora="00";
    String Sminuto="00";
    String Ssegundo="00";
    if (dia<10)
      Sdia="0"+String(dia);
    else
      Sdia=String(dia);
    if (hora<10)
      Shora="0"+String(hora);
    else
      Shora=String(hora);
    if (minuto<10)
      Sminuto="0"+String(minuto);
    else
      Sminuto=String(minuto);
    if (segundo<10)
      Ssegundo="0"+String(segundo);
    else
      Ssegundo=String(segundo);
      
    String FileDateHour=String(nomDatFile)+"_"+Sdia+String(monthsOfYear[mes-1])+String(anio)+"_"+Shora+Sminuto+Ssegundo+".saf";
    #ifdef DEBUG
      Serial.println(FileDateHour);
    #endif
    FileDateHour.toCharArray(nomDatFile, sizeof(nomDatFile)); //Do that: nomDatFile=FileDateHour;
  }
}


void dateTime(uint16_t* date, uint16_t* time) {
    DateTime now = rtc.now();
  // return date using FAT_DATE macro to format fields
  *date = FAT_DATE(now.year(), now.month(), now.day());
  // return time using FAT_TIME macro to format fields
  *time = FAT_TIME(now.hour(), now.minute(), now.second());
}

// StrContains searches for the string sfind in the string str
// Returns 1 string found
// Returns 0 string not found
char StrContains(char *str, char *sfind)
{
    char found = 0;
    char index = 0;
    char len;

    len = strlen(str);
    
    if (strlen(sfind) > len) {
        return 0;
    }
    while (index < len) {
        if (str[index] == sfind[found]) {
            found++;
            if (strlen(sfind) == found) {
                return 1;
            }
        }
        else {
            found = 0;
        }
        index++;
    }

    return 0;
}
void StrClear(char *str, char length)
{
  
    for (int i = 0; i < length; i++) {
        str[i] = 0;
    }
}
void serialEventRun(void) {
  if (Serial.available())
          serialEvent();
}
