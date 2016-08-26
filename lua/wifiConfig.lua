ssid = nil
pw = nil

function createAP() 
    
    -- Wifi Connection Settings
    -- Access Point With Password
    ipcfg = {}
    ipcfg.ip = "192.168.1.100"
    ipcfg.netmask = "255.255.255.0"
    ipcfg.gateway = "192.168.1.100"
    
    wifi.ap.setip(ipcfg)
    cfg = {}
    cfg.ssid="nodeIOT"
    cfg.pwd="12345678"
    wifi.ap.config(cfg)
    wifi.setmode(wifi.SOFTAP)
    -- End of Wifi Connection Settings
    print(wifi.ap.getip())

end

function connectToAp() 
    local counter = 0
    print("connectToAp2")
    wifi.setmode(wifi.STATION)
    wifi.sta.config(ssid, pw)
    -- wifi.sta.connect
    tmr.alarm(0, 1000, 1, function()
       if (wifi.sta.getip()) == nil then
          print("Connecting to AP...\n")
          counter = counter + 1
          if (counter >= 10) then
            ssid = nil
            pw = nil
            tmr.stop(0)
            createAP()
          end
       else
          ip, nm, gw=wifi.sta.getip()
          print("IP Info: \nIP Address: ",ip)
          print("Netmask: ",nm)
          print("Gateway Addr: ",gw,'\n')
          tmr.stop(0)
       end
    end)
end


function startServer()
        -- Create a server object with 30 second timeout
    srv = net.createServer(net.TCP, 30)
    
    -- server listen on 80, 
    -- if data received, print data to console,
    -- then serve up a sweet little website
    srv:listen(80,function(conn)
        conn:on("receive", function(conn, payload)
            -- CREATE WEBSITE --
            print(payload)

            buf = 'HTTP/1.1 200 OK\n\n';
            buf = buf..'<!DOCTYPE HTML>\n'           
            buf = buf..'<html>\n';
            buf = buf..'<head><meta  content="text/html; charset=utf-8">\n'
            buf = buf..'<title>Wifi Configuration</title></head>\n'
            buf = buf..'<body><h1>Wifi Configuration</h1>\n'


            local data = parseFormData(payload)
            if (data.ssid and data.password) then      
                print(data.ssid)
                print(data.password)   
                ssid = data.ssid
                pw = data.password 
                buf = buf..'Die Daten werden nun getestet'                     
            else
                buf = buf..'<p>Bitte geben Sie SSID/Name und Passwort ihres WLAN-Netzes ein.</p><br>'           
                buf = buf..'<form action="" method="POST">\n'
                buf = buf..'<input type="hidden" name="hidden"/>'
                buf = buf..'<input type="text" name="ssid"/>'
                buf = buf..'<input type="password" name="password"/>'
                buf = buf..'<input type="submit" name="mcu_do" value="Save data">\n'                
            end

            buf = buf..'</body></html>\n'
          
            conn:send(buf)
            
            conn:on("sent", 
                function(conn)                                         
                    conn:close()
                    if (ssid and pw) then                          
                        connectToAp()
                    end
                end)
        end)
    end)
end

function parseFormData(body)
   local data = {}
   --print("Parsing Form Data")
   for kv in body.gmatch(body, "%s*&?([^=]+=[^&]+)") do
      local key, value = string.match(kv, "(.*)=(.*)")
      print("Parsed: " .. key .. " => " .. value)
      data[key] = uri_decode(value)
   end
   return data
end

-- not working
function uri_decode(input)
  return input:gsub("%+", " "):gsub("%%(%x%x)", hex_to_char)
end

function hex_to_char(x)
  return string.char(tonumber(x, 16))
end

createAP()
startServer()
