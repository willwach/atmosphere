function readBmpSensor(sdaPin, sclPin)
        
    bmp085.init(sdaPin, sclPin)
        
    local t = bmp085.temperature(1)
    print(string.format("Temperature: %s.%s degrees C", t / 10, t % 10))
    
    local p = bmp085.pressure(1)
    print(string.format("Pressure: %s.%s mbar", p / 100, p % 100))

    tempBMP180=string.format("%s.%s", t / 10, t % 10)
    pressBMP180=string.format("%s.%s", p / 100, p % 100)

    return tempBMP180, pressBMP180

end


function readDhtSensor(pin)
    dht=require("dht")
    tempDHT22 = -1000
    humiDHT22 = -1000
    status, temp, humi, temp_dec, humi_dec = dht.read(pin)
    if status == dht.OK then
        -- Integer firmware using this example
        local data = string.format("DHT Temperature:%d.%03d;Humidity:%d.%03d\r\n",
              math.floor(temp),
              temp_dec,
              math.floor(humi),
              humi_dec
        )       

        tempDHT22 = string.format("%d.%03d",math.floor(temp),temp_dec)
        humiDHT22 = string.format("%d.%03d", math.floor(humi),humi_dec)
        
        print(data)
        
    elseif status == dht.ERROR_CHECKSUM then
        print( "DHT Checksum error." )       
    elseif status == dht.ERROR_TIMEOUT then
        print( "DHT timed out." )       
    end
    
    -- Release module
    dht=nil
    package.loaded["dht"]=nil
    return tempDHT22, humiDHT22
end

function resetDhtForDeepsleep(pin)
    gpio.mode(pin,gpio.OUTPUT)
    gpio.write(pin,gpio.LOW)
end

function getDS18B20Sensor(pin)
    local sensors = {}
    local addr = nil
    local count = 0
    ow.setup(pin)
    repeat
        count = count + 1
        addr = ow.reset_search(pin)
        addr = ow.search(pin)
        table.insert(sensors, addr)
        tmr.wdclr()
    until((addr ~= nil) or (count > 100))
    print("Sensors:", #sensors)
    if (addr == nil) then
        print('DS18B20 not found')
    end
    local s = string.format("Addr:%02X-%02X-%02X-%02X-%02X-%02X-%02X-%02X", 
        addr:byte(1), addr:byte(2), addr:byte(3), addr:byte(4), 
        addr:byte(5), addr:byte(6), addr:byte(7), addr:byte(8))
    print(s)
    crc = ow.crc8(string.sub(addr, 1, 7))
    if (crc ~= addr:byte(8)) then
        print('DS18B20 Addr CRC failed');
    end
    if not((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
        print('DS18B20 not found')
    end
    ow.reset(pin)
    ow.select(pin, addr)
    ow.write(pin, 0x44, 1)
    tmr.delay(1000000)
    present = ow.reset(pin)
    if present ~= 1 then
        print('DS18B20 not present')
    end
    ow.select(pin, addr)
    
    ow.write(pin, 0xBE, 1)
    local data = nil
    data = string.char(ow.read(pin))
    for i = 1, 8 do
        data = data .. string.char(ow.read(pin))
    end
    s = string.format("Data:%02X-%02X-%02X-%02X-%02X-%02X-%02X-%02X", 
        data:byte(1), data:byte(2), data:byte(3), data:byte(4),
        data:byte(5), data:byte(6), data:byte(7), data:byte(8))
    print(s)
    crc = ow.crc8(string.sub(data, 1, 8))
    if (crc ~= data:byte(9)) then
        print('DS18B20 data CRC failed')
    end
    local t0 = (data:byte(1) + data:byte(2) * 256)
    if (t0 > 32767) then
        t0 = t0 - 65536
    end
    t0 = t0 * 625
    temperature = (t0 / 10000) .. "." .. (t0 % 10000)
    print(string.format("Temperature: %s C", temperature))    
    return temperature
end