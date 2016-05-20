--==============================================================================
--                            ddweather.lua
--
--  Author  : Dirk Dittmar
--  License : Distributed under the terms of GNU GPL version 2 or later
--
--==============================================================================


require 'cairo'
JSON = require ("dkjson")


-------------------------------------------------------------------------------
--                                                openweathermap.org api params
API_PARAMS = {
    version = '2.5',
    city = 'Hamburg,de',
    units = 'metric',
    lang = 'de',
    app_id = '1dc64bd5b9c3f038eefed54905a1c416'
}

-------------------------------------------------------------------------------
--                                                  update intervall in seconds
UPDATE_INTERVAL = 1800


-------------------------------------------------------------------------------
--                                                           string:starts_with
-- checks if a string starts with another string
--
function string:starts_with(starts_with)
    return self.sub(self, 1, string.len(starts_with)) == starts_with
end -- string:starts_with


-------------------------------------------------------------------------------
--                                                                   math.round
-- rounds 'num' to (optional) 'idp' decimal places
--
function math.round(num, idp)
    if idp and idp>0 then
        local mult = 10^idp
        return math.floor(num * mult + 0.5) / mult
    end
    return math.floor(num + 0.5)
end -- math.round


-------------------------------------------------------------------------------
--                                                                  round_value
-- a guard function ... rounds 'value' to (optional) 'idp' decimal places
--
function round_value(value, idp)
    -- idp string guard
    if (idp and type(idp) == 'string') then
        idp = tonumber(idp)
    end
    -- value string guard
    if (idp and value and (type(value) == 'number')) then
        return math.round(value, idp)
    end
    return value --> no rounding
end -- round_value


-------------------------------------------------------------------------------
--                                                           fetch_current_city
-- fetches the current location and returns a openweathermap city string
--
function fetch_current_city()
    local url = "http://conky-ddweather-location.appspot.com"
    print('fetch_current_city() from', url)
    local file = io.popen(string.format('/usr/bin/curl "%s" -s -S -o -', url))
    local output = file:read('*all')
    file:close()
    print('fetch_current_city() =>', output) --> debug

    local current_location = nil
    if (output:starts_with('{')) then
        local obj, pos, err = JSON.decode (output, 1, nil) -- parse json
        if err then
            print ("Error:", err)
        else
            current_location = obj
        end
    end

    if (current_location) then --> if we have data
        return string.format("%s,%s", current_location['city'], current_location['country'])
    end

    return nil --> nothing
end


-------------------------------------------------------------------------------
--                                                        fetch_current_weather
-- fetches the current weather conditions into a global table
--
function fetch_current_weather()
    if city == nil then
        city = API_PARAMS['city']
    end

    local url = string.format("http://api.openweathermap.org/data/%s/weather?q=%s&units=%s&lang=%s&APPID=%s",
        API_PARAMS['version'],
        city,
        API_PARAMS['units'],
        API_PARAMS['lang'],
        API_PARAMS['app_id'])
    print('fetch_current_weather() from', url)
    local file = io.popen(string.format('/usr/bin/curl "%s" -s -S -o -', url))
    local output = file:read('*all')
    file:close()
    print('fetch_current_weather() =>', output) --> debug

    current_weather = nil
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
--                                                               fetch_forecast
-- fetches the weather forecast into a global table
--
function fetch_forecast()
    if city == nil then
        city = API_PARAMS['city']
    end

    local url = string.format("http://api.openweathermap.org/data/%s/forecast?q=%s&units=%s&lang=%s&APPID=%s",
        API_PARAMS['version'],
        city,
        API_PARAMS['units'],
        API_PARAMS['lang'],
        API_PARAMS['app_id'])
    print('fetch_forecast() from', url)
    local file = io.popen(string.format('/usr/bin/curl "%s" -s -S -o -', url))
    local output = file:read('*all')
    file:close()
    print('fetch_forecast() =>', output) --> debug

    forecast = nil
    if (output:starts_with('{')) then
        local obj, pos, err = JSON.decode (output, 1, nil)
        if err then
            print ("Error:", err)
        else
            forecast = obj
        end
    end
end -- fetch_forecast


-------------------------------------------------------------------------------
--                                                    get_current_weather_value
-- helper function to navigate the current_weather table
--
function get_current_weather_value( ... )
    local result = current_weather
    for _,v in ipairs(arg) do
        if (result) then
            result = result[v]
        end
    end
    return result
end -- get_current_weather_value


-------------------------------------------------------------------------------
--                                                           get_forecast_value
-- helper function to navigate the forecast table
--
function get_forecast_value( ... )
    local result = forecast
    for _,v in ipairs(arg) do
        if (result) then
            result = result[v]
        end
    end
    return result
end -- get_forecast_value


-------------------------------------------------------------------------------
--                                                                   conky_city
-- returns the city
--
function conky_city()
    local value = get_current_weather_value('name')
    value = value and value or "NA"
    return value
end -- conky_city


-------------------------------------------------------------------------------
--                                                                   conky_main
-- returns one of the main attributes
--
function conky_main(param, idp)
    local value = get_current_weather_value('main', param)
    value = value and round_value(value, idp) or "NA"
    return value
end -- conky_main


-------------------------------------------------------------------------------
--                                                                conky_weather
-- returns one of the weather attributes
--
function conky_weather(param, idp)
    local value = get_current_weather_value('weather', 1, param)
    value = value and round_value(value, idp) or "NA"
    return value
end -- conky_weather


-------------------------------------------------------------------------------
--                                                                   conky_wind
-- returns one of the wind attributes
--
function conky_wind(param, idp)
    local value = get_current_weather_value('wind', param)
    value = value and round_value(value, idp) or "NA"
    return value
end -- conky_wind


-------------------------------------------------------------------------------
--                                                                 conky_clouds
-- returns the clouds value
--
function conky_clouds()
    local value = get_current_weather_value('clouds', 'all')
    value = value and value or "NA"
    return value
end -- conky_clouds


-------------------------------------------------------------------------------
--                                                           conky_weather_icon
-- returns the weather icon conky format string
--
function conky_weather_icon()
    local value = get_current_weather_value('weather', 1, 'icon')
    value = value and value or "na"
    return string.format("${image ./img/%s.png -p 65,60 -s 128x128 -n}", value)
end -- conky_weather_icon


-------------------------------------------------------------------------------
--                                                                draw_forecast
-- draw the forecast data
--
function draw_forecast()
    print "draw_forecast()"
    local cnt = get_forecast_value('cnt')
    for i = 1, cnt do
        -- local dt = 1get_forecast_value('list', i, 'dt')
        -- TODO go on here
    end
end -- draw_forecast


-------------------------------------------------------------------------------
--                                                          conky_fetch_weather
function conky_fetch_weather()
    if conky_window == nil then
        return
    end

    local surface = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local context = cairo_create(cs)

    local updates = tonumber(conky_parse('${updates}'))
    if updates >= 5 then
        local fetch = ((updates - 5) % UPDATE_INTERVAL) == 0
        if fetch or not current_weather then
            local fetch_city = ((updates - 5) % (UPDATE_INTERVAL * 4)) == 0
            if fetch_city or not city then
                city = fetch_current_city()
            end
            fetch_current_weather()
            fetch_forecast()
            draw_forecast()
        end
    end

    cairo_surface_destroy(surface)
    cairo_destroy(context)

end -- conky_fetch_weather
