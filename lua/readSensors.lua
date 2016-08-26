require("sensors")
require("config")

tempDS18B20=0
tempDHT22=-1000
humiDHT22=-1000
tempBMP180=0
pressBMP180=0

function startWifi()
    wifi.setmode(wifi.STATION)
    wifi.sta.config(wifiSID,wifiPW)   
    wifi.sta.connect()
end

function readSensors()
    print('start readSensors')
    tempDS18B20 = getDS18B20Sensor(pinDS18B20)
    
    dhtReadCounter = 1
    while (((tempDHT22 == -1000) or (humiDHT22==-1000)) and dhtReadCounter < 10) do
        tmr.delay(1000000)
        print(dhtReadCounter)
        tempDHT22, humiDHT22 = readDhtSensor(pinDHT22)
        dhtReadCounter = dhtReadCounter+1
    end

    tempBMP180, pressBMP180 = readBmpSensor(pinBmpSda,pinBmpScl)
end    

function postThingSpeak(tempDS18B20, tempDHT22, humiDHT22, tempBMP180, pressBMP180)
    connout = nil
    connout = net.createConnection(net.TCP, 0)
 
    connout:on("receive", function(connout, payloadout)
        if (string.find(payloadout, "Status: 200 OK") ~= nil) then
            print("Posted OK");          
        end
    end)
 
    connout:on("connection", function(connout, payloadout)
 
        print ("Posting...");
 
        connout:send("GET /update?api_key="..WRITEKEY.."&field1="..tempDS18B20.."&field2="..tempDHT22.."&field3="..humiDHT22.."&field4="..tempBMP180.."&field5="..pressBMP180
        .. " HTTP/1.1\r\n"
        .. "Host: api.thingspeak.com\r\n"
        .. "Connection: close\r\n"
        .. "Accept: */*\r\n"
        .. "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n"
        .. "\r\n")
    end)
 
    connout:on("disconnection", function(connout, payloadout)
        connout:close();
        collectgarbage();
        tmr.stop(1)
        gotoDeepSleep()
    end)
    
    connout:connect(80,'api.thingspeak.com')
end

function startTimeOutToSleep() 
    tmr.alarm(1,15000,tmr.ALARM_SINGLE,
        function()
            print('timeout to deepsleep')
            gotoDeepSleep()
        end
    )
end

function gotoDeepSleep()
    print('go to deepsleep')
    resetDhtForDeepsleep(pinDHT22)
    node.dsleep(sleepIntervall);
end

startWifi()
readSensors()
postThingSpeak(tempDS18B20, tempDHT22, humiDHT22, tempBMP180, pressBMP180)
startTimeOutToSleep()

