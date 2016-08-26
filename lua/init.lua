function startup()
    if abort == true then
        print('startup aborted')
        return
    end
        print('started')
        -- dofile('wifiConfig.lua')
        dofile('readSensors.lua')
    end

abort = false
tmr.alarm(0,5000,tmr.ALARM_SINGLE,startup)
