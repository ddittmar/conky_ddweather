--==============================================================================
--                            ddweather.lua
--
--  Author  : Dirk Dittmar
--  License : Distributed under the terms of GNU GPL version 2 or later
--
--==============================================================================


JSON = require ("dkjson")


-------------------------------------------------------------------------------
--                                                           string:starts_with
-- checks if a string starts with another string
--
function string:starts_with(starts_with)
    return self.sub(self, 1, string.len(starts_with)) == starts_with
end -- string:starts_with


-------------------------------------------------------------------------------
--                                                        fetch_current_weather
-- fetches the current weather conditions into a global table
--
function fetch_current_weather() 
    local file = io.popen('/usr/bin/curl "http://api.openweathermap.org/data/2.5/weather?q=Hamburg,de&units=metric&lang=de&APPID=1dc64bd5b9c3f038eefed54905a1c416" -s -S -o -')
    local output = file:read('*all')
    file:close()
    print(output) --> debug
    if (output:starts_with('{')) then
        local obj, pos, err = JSON.decode (output, 1, nil) -- parse json
        if err then
          print ("Error:", err)
        else
          current_weather = obj
        end
    end
end -- fetch_current_weather


-------------------------------------------------------------------------------
--                                                    conky_weather_description
-- returns the weather description
--
function conky_weather_description()
    if (current_weather) then
        return current_weather['weather'][1]['description']
    else
        return "NA"
    end
end

-------------------------------------------------------------------------------
--                                                                   conky_city
-- returns the city
--
function conky_city()
    if (current_weather) then
        return current_weather['name']
    else
        return "NA"
    end
end


-------------------------------------------------------------------------------
--                                                                   conky_main
-- returns one of the main attributes
--
function conky_main(param)
    if (current_weather) then
        return current_weather['main'][param]
    else
        return "NA"
    end
end


-------------------------------------------------------------------------------
--                                                                conky_weather
-- returns one of the weather attributes
--
function conky_weather(param)
    if (current_weather and current_weather['weather']) then
        return current_weather['weather'][1][param]
    else
        return "NA"
    end
end


-------------------------------------------------------------------------------
--                                                                   conky_wind
-- returns one of the wind attributes
--
function conky_wind(param)
    if (current_weather) then
        return current_weather['wind'][param]
    else
        return "NA"
    end
end


-------------------------------------------------------------------------------
--                                                                 conky_clouds
-- returns the clouds value
--
function conky_clouds(param)
    if (current_weather) then
        return current_weather['clouds']['all']
    else
        return "NA"
    end
end


-------------------------------------------------------------------------------
--                                                           conky_weather_icon
-- returns the weather icon conky format string
--
function conky_weather_icon()
    if (current_weather and current_weather['weather']) then
        return string.format("${image ./img/%s.png -p 65,50 -s 128x128 -n}", current_weather['weather'][1]['icon'])
    else
        return "${image ./img/na.png -p 65,50 -s 128x128 -n}"
    end
end


-------------------------------------------------------------------------------
--                                                  conky_fetch_current_weather
function conky_fetch_current_weather()
    if conky_window == nil then 
        return
    end
    
    local updates = tonumber(conky_parse('${updates}'))
    if updates >= 5 then
        local fetch = ((updates - 5) % 1800) == 0
        if fetch or not current_weather then
            fetch_current_weather()
        end
    end

end -- conky_fetch_current_weather
