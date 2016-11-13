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
    cnt = 8,
    app_id = '1dc64bd5b9c3f038eefed54905a1c416'
}

-------------------------------------------------------------------------------
--                                          weather update intervall in seconds
WEATHER_UPDATE_INTERVAL = 1800

-------------------------------------------------------------------------------
--                                             city update intervall in seconds
CITY_UPDATE_INTERVAL = 1800 * 4

-------------------------------------------------------------------------------
--                                                  position of the buttom line
FORECAST_BUTTOM_LINE = 345

-------------------------------------------------------------------------------
--                                                     position of the top line
FORECAST_TOP_LINE = 245

-------------------------------------------------------------------------------
--                                                                  print_table
-- print a table (debugging)
--
function print_table(t)
    for k,v in pairs(t) do
        print(k,v)
    end
end -- print_table


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
--                                                            math.roundToMulti
-- rounds 'num' so that the result is near to the multiple of 'x'
--
function math.roundToMulti(num, x)
    local n = math.round(tonumber(num), 0)
    local m = math.round(tonumber(x), 0)
    return m * math.round(n/m, 0)
end -- roundToMulti


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
--                                                        add_to_forecast_cache
-- add a value to the forecast_cache
--
function add_to_forecast_cache(name, value)
    if not forecast_cache then
        forecast_cache = {}
    end
    forecast_cache[name] = value
end -- add_to_forecast_cache

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
    print('fetch_current_weather() =>', output) --> {"coord":{"lon":10,"lat":53.55},"weather":[{"id":741,"main":"Fog","description":"Nebel","icon":"50d"}],"base":"stations","main":{"temp":-1.76,"pressure":1017,"humidity":81,"temp_min":-4,"temp_max":0},"visibility":6000,"wind":{"speed":1},"clouds":{"all":75},"dt":1478847000,"sys":{"type":1,"id":4883,"message":0.0049,"country":"DE","sunrise":1478846373,"sunset":1478878077},"id":2911298,"name":"Hamburg","cod":200}

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
--[=====[
    local url = string.format("http://api.openweathermap.org/data/%s/forecast?q=%s&units=%s&lang=%s&cnt=%s&APPID=%s",
        API_PARAMS['version'],
        city,
        API_PARAMS['units'],
        API_PARAMS['lang'],
        API_PARAMS['cnt'],
        API_PARAMS['app_id'])
    print('fetch_forecast() from', url)
    local file = io.popen(string.format('/usr/bin/curl "%s" -s -S -o -', url))
    local output = file:read('*all')
    file:close()
    print('fetch_forecast() =>', output) --> {"city":{"id":2911298,"name":"Hamburg","coord":{"lon":10,"lat":53.549999},"country":"DE","population":0,"sys":{"population":0}},"cod":"200","message":0.0052,"cnt":8,"list":[{"dt":1478854800,"main":{"temp":-4.59,"temp_min":-5.53,"temp_max":-4.59,"pressure":1027.75,"sea_level":1032.56,"grnd_level":1027.75,"humidity":81,"temp_kf":0.93},"weather":[{"id":800,"main":"Clear","description":"klarer Himmel","icon":"02d"}],"clouds":{"all":8},"wind":{"speed":1.39,"deg":23.5009},"rain":{},"snow":{},"sys":{"pod":"d"},"dt_txt":"2016-11-11 09:00:00"},{"dt":1478865600,"main":{"temp":-1.65,"temp_min":-2.35,"temp_max":-1.65,"pressure":1029.83,"sea_level":1034.54,"grnd_level":1029.83,"humidity":87,"temp_kf":0.7},"weather":[{"id":800,"main":"Clear","description":"klarer Himmel","icon":"01d"}],"clouds":{"all":0},"wind":{"speed":1.41,"deg":359.502},"rain":{},"snow":{},"sys":{"pod":"d"},"dt_txt":"2016-11-11 12:00:00"},{"dt":1478876400,"main":{"temp":-6.78,"temp_min":-7.25,"temp_max":-6.78,"pressure":1031.38,"sea_level":1036.08,"grnd_level":1031.38,"humidity":79,"temp_kf":0.47},"weather":[{"id":800,"main":"Clear","description":"klarer Himmel","icon":"01d"}],"clouds":{"all":0},"wind":{"speed":1.27,"deg":305.005},"rain":{},"snow":{},"sys":{"pod":"d"},"dt_txt":"2016-11-11 15:00:00"},{"dt":1478887200,"main":{"temp":-10.48,"temp_min":-10.71,"temp_max":-10.48,"pressure":1032.95,"sea_level":1037.84,"grnd_level":1032.95,"humidity":61,"temp_kf":0.23},"weather":[{"id":801,"main":"Clouds","description":"ein paar Wolken","icon":"02n"}],"clouds":{"all":12},"wind":{"speed":1.32,"deg":322.004},"rain":{},"snow":{},"sys":{"pod":"n"},"dt_txt":"2016-11-11 18:00:00"},{"dt":1478898000,"main":{"temp":-11.86,"temp_min":-11.86,"temp_max":-11.86,"pressure":1034.41,"sea_level":1039.29,"grnd_level":1034.41,"humidity":60,"temp_kf":0},"weather":[{"id":500,"main":"Rain","description":"leichter Regen","icon":"10n"}],"clouds":{"all":0},"wind":{"speed":1.31,"deg":349.501},"rain":{"3h":0.005},"snow":{},"sys":{"pod":"n"},"dt_txt":"2016-11-11 21:00:00"},{"dt":1478908800,"main":{"temp":-9.52,"temp_min":-9.52,"temp_max":-9.52,"pressure":1035.46,"sea_level":1040.38,"grnd_level":1035.46,"humidity":56,"temp_kf":0},"weather":[{"id":802,"main":"Clouds","description":"überwiegend bewölkt","icon":"03n"}],"clouds":{"all":44},"wind":{"speed":1.32,"deg":306.501},"rain":{},"snow":{},"sys":{"pod":"n"},"dt_txt":"2016-11-12 00:00:00"},{"dt":1478919600,"main":{"temp":-4.15,"temp_min":-4.15,"temp_max":-4.15,"pressure":1036.11,"sea_level":1040.86,"grnd_level":1036.11,"humidity":66,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"überwiegend bewölkt","icon":"04n"}],"clouds":{"all":68},"wind":{"speed":1.33,"deg":264.5},"rain":{},"snow":{},"sys":{"pod":"n"},"dt_txt":"2016-11-12 03:00:00"},{"dt":1478930400,"main":{"temp":-2.84,"temp_min":-2.84,"temp_max":-2.84,"pressure":1036.54,"sea_level":1041.34,"grnd_level":1036.54,"humidity":87,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"überwiegend bewölkt","icon":"04n"}],"clouds":{"all":64},"wind":{"speed":1.27,"deg":221.509},"rain":{},"snow":{},"sys":{"pod":"n"},"dt_txt":"2016-11-12 06:00:00"}]}
--]=====]
    local output = '{"city":{"id":2911298,"name":"Hamburg","coord":{"lon":10,"lat":53.549999},"country":"DE","population":0,"sys":{"population":0}},"cod":"200","message":0.0052,"cnt":8,"list":[{"dt":1478854800,"main":{"temp":-4.59,"temp_min":-5.53,"temp_max":-4.59,"pressure":1027.75,"sea_level":1032.56,"grnd_level":1027.75,"humidity":81,"temp_kf":0.93},"weather":[{"id":800,"main":"Clear","description":"klarer Himmel","icon":"02d"}],"clouds":{"all":8},"wind":{"speed":1.39,"deg":23.5009},"rain":{},"snow":{},"sys":{"pod":"d"},"dt_txt":"2016-11-11 09:00:00"},{"dt":1478865600,"main":{"temp":-1.65,"temp_min":-2.35,"temp_max":-1.65,"pressure":1029.83,"sea_level":1034.54,"grnd_level":1029.83,"humidity":87,"temp_kf":0.7},"weather":[{"id":800,"main":"Clear","description":"klarer Himmel","icon":"01d"}],"clouds":{"all":0},"wind":{"speed":1.41,"deg":359.502},"rain":{},"snow":{},"sys":{"pod":"d"},"dt_txt":"2016-11-11 12:00:00"},{"dt":1478876400,"main":{"temp":-6.78,"temp_min":-7.25,"temp_max":-6.78,"pressure":1031.38,"sea_level":1036.08,"grnd_level":1031.38,"humidity":79,"temp_kf":0.47},"weather":[{"id":800,"main":"Clear","description":"klarer Himmel","icon":"01d"}],"clouds":{"all":0},"wind":{"speed":1.27,"deg":305.005},"rain":{},"snow":{},"sys":{"pod":"d"},"dt_txt":"2016-11-11 15:00:00"},{"dt":1478887200,"main":{"temp":-10.48,"temp_min":-10.71,"temp_max":-10.48,"pressure":1032.95,"sea_level":1037.84,"grnd_level":1032.95,"humidity":61,"temp_kf":0.23},"weather":[{"id":801,"main":"Clouds","description":"ein paar Wolken","icon":"02n"}],"clouds":{"all":12},"wind":{"speed":1.32,"deg":322.004},"rain":{},"snow":{},"sys":{"pod":"n"},"dt_txt":"2016-11-11 18:00:00"},{"dt":1478898000,"main":{"temp":-11.86,"temp_min":-11.86,"temp_max":-11.86,"pressure":1034.41,"sea_level":1039.29,"grnd_level":1034.41,"humidity":60,"temp_kf":0},"weather":[{"id":500,"main":"Rain","description":"leichter Regen","icon":"10n"}],"clouds":{"all":0},"wind":{"speed":1.31,"deg":349.501},"rain":{"3h":0.005},"snow":{},"sys":{"pod":"n"},"dt_txt":"2016-11-11 21:00:00"},{"dt":1478908800,"main":{"temp":-9.52,"temp_min":-9.52,"temp_max":-9.52,"pressure":1035.46,"sea_level":1040.38,"grnd_level":1035.46,"humidity":56,"temp_kf":0},"weather":[{"id":802,"main":"Clouds","description":"überwiegend bewölkt","icon":"03n"}],"clouds":{"all":44},"wind":{"speed":1.32,"deg":306.501},"rain":{},"snow":{},"sys":{"pod":"n"},"dt_txt":"2016-11-12 00:00:00"},{"dt":1478919600,"main":{"temp":-4.15,"temp_min":-4.15,"temp_max":-4.15,"pressure":1036.11,"sea_level":1040.86,"grnd_level":1036.11,"humidity":66,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"überwiegend bewölkt","icon":"04n"}],"clouds":{"all":68},"wind":{"speed":1.33,"deg":264.5},"rain":{},"snow":{},"sys":{"pod":"n"},"dt_txt":"2016-11-12 03:00:00"},{"dt":1478930400,"main":{"temp":-2.84,"temp_min":-2.84,"temp_max":-2.84,"pressure":1036.54,"sea_level":1041.34,"grnd_level":1036.54,"humidity":87,"temp_kf":0},"weather":[{"id":803,"main":"Clouds","description":"überwiegend bewölkt","icon":"04n"}],"clouds":{"all":64},"wind":{"speed":1.27,"deg":221.509},"rain":{},"snow":{},"sys":{"pod":"n"},"dt_txt":"2016-11-12 06:00:00"}]}'
    forecast = nil
    if (output:starts_with('{')) then
        local obj, pos, err = JSON.decode (output, 1, nil)
        if err then
            print ("Error:", err)
        else
            forecast = obj
        end
    end

    forecast_cache = nil
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
    return string.format("${image ./img/%s.png -p 65,60 -s 128x128}", value)
end -- conky_weather_icon


-------------------------------------------------------------------------------
--                                                  conky_forecast_weather_icon
-- returns the weather icon conky format string
--
function conky_forecast_weather_icon(idx, px, py)
    local value = get_forecast_value('list', tonumber(idx), 'weather', 1, 'icon')
    value = value and value or "na"
    return string.format("${image ./img/%s.png -p %s,%s -s 32x32}", value, px, py)
end -- conky_forecast_weather_icon


-------------------------------------------------------------------------------
--                                                  conky_forecast_weather_icon
-- returns the weather icon conky format string
--
function conky_forecast_wind_icon(idx, px, py)
    local value = get_forecast_value('list', tonumber(idx), 'wind', 'deg')
    local pic_name = 'n'
    if value then
        if value > 0 and value <= 22.5 then
            pic_name = 'n'
        elseif value > 22.5 and value <= 67.5 then
            pic_name = 'ne'
        elseif value > 67.5 and value <= 112.5 then
            pic_name = 'e'
        elseif value > 112.5 and value <= 157.5 then
            pic_name = 'se'
        elseif value > 157.5 and value <= 202.5 then
            pic_name = 's'
        elseif value > 202.5 and value <= 247.5 then
            pic_name = 'sw'
        elseif value > 247.5 and value <= 292.5 then
            pic_name = 'w'
        elseif value > 292.5 and value <= 337.5 then
            pic_name = 'nw'
        else
            pic_name = 'n'
        end
    end
    return string.format("${image ./img/%s.png -p %s,%s -s 16x16}", pic_name, px, py)
end -- conky_forecast_weather_icon


-------------------------------------------------------------------------------
--                                                        forecast_min_max_temp
-- find min and max temp values in the forecast
--
function forecast_min_max_temp()
    local min, max
    if (forecast_cache and forecast_cache.min_temp and forecast_cache.max_temp) then
        min = forecast_cache.min_temp
        max = forecast_cache.max_temp
    else
        for _, temp in ipairs(forecast_temp_values()) do
            if not min or temp < min then
                min = temp
            end
            if not max or temp > max then
                max = temp
            end
        end
        add_to_forecast_cache('min_temp', min)
        add_to_forecast_cache('max_temp', max)
    end
    return min, max
end -- forecast_min_max_temp


-------------------------------------------------------------------------------
--                                                         forecast_temp_values
-- find all temp values in the forecast
--
function forecast_temp_values()
    local res = {}
    if forecast_cache and forecast_cache.temp_values then
        res = forecast_cache.temp_values
    else
        local cnt = tonumber(get_forecast_value('cnt'))
        for i = 1, cnt do
            res[i] = tonumber(get_forecast_value('list', i, 'main', 'temp'))
        end
        add_to_forecast_cache('temp_values', res)
    end
    return res
end -- forecast_temp_values


-------------------------------------------------------------------------------
--                                                         forecast_wind_values
-- find all wind speed values in the forecast
--
function forecast_wind_values()
    local res = {}
    if forecast_cache and forecast_cache.wind_values then
        res = forecast_cache.wind_values
    else
        local cnt = tonumber(get_forecast_value('cnt'))
        for i = 1, cnt do
            res[i] = tonumber(get_forecast_value('list', i, 'wind', 'speed'))
        end
        add_to_forecast_cache('wind_values', res)
    end
    return res
end -- forecast_wind_values


-------------------------------------------------------------------------------
--                                                         forecast_rain_values
-- find all rain values in the forecast
--
function forecast_rain_values()
    local res = {}
    if forecast_cache and forecast_cache.rain_values then
        res = forecast_cache.rain_values
    else
        local cnt = tonumber(get_forecast_value('cnt'))
        for i = 1, cnt do
            res[i] = tonumber(get_forecast_value('list', i, 'rain', '3h')) or 0
        end
        add_to_forecast_cache('rain_values', res)
    end
    return res
end -- forecast_rain_values


-------------------------------------------------------------------------------
--                                                forecast_min_max_temp_rounded
-- find min and max temp values in the forecast
--
function forecast_min_max_temp_rounded()
    local min_temp, max_temp = forecast_min_max_temp()
    local min_rounded = math.roundToMulti(min_temp, 5) - 5
    local max_rounded = math.roundToMulti(max_temp, 5) + 5
    return min_rounded, max_rounded
end -- forecast_min_max_temp_rounded


-------------------------------------------------------------------------------
--                                                                  conky_hours
-- return the hour value at the index as string
--
function conky_forecast_hours(idx)
    local dt = get_forecast_value('list', tonumber(idx), 'dt')
    return dt and os.date("%H", dt) or 'NA'
end -- conky_hours


-------------------------------------------------------------------------------
--                                                      conky_forecast_min_temp
-- returns the min temp label for conky
--
function conky_forecast_min_temp()
    if get_forecast_value('cnt') then
        local min_temp, _ = forecast_min_max_temp_rounded()
        return min_temp
    else
        return 'NA'
    end
end -- conky_forecast_min_temp


-------------------------------------------------------------------------------
--                                                            forecast_max_wind
-- returns the max wind speed (m/s) from the forcast
--
function forecast_max_wind()
    local max = 0
    for wind in ipairs(forecast_wind_values()) do
        if wind > max then
            max = wind
        end
    end
    return max
end -- forecast_max_wind


-------------------------------------------------------------------------------
--                                                    forecast_max_wind_rounded
-- return the max wind speed (m/s) from the forcast rounded to a multiple of 5
--
function forecast_max_wind_rounded()
    return math.roundToMulti(forecast_max_wind(), 5)
end -- forecast_max_wind_rounded


-------------------------------------------------------------------------------
--                                                      conky_forecast_max_wind
-- returns the max wind speed (m/s) from the forcast rounded to a multiple of 5
-- or 'NA' if the forcast is not loaded yet
--
function conky_forecast_max_wind()
    if (get_forecast_value('cnt')) then
        return forecast_max_wind_rounded()
    else
        return 'NA'
    end
end -- conky_forecast_max_wind


-------------------------------------------------------------------------------
--                                                      conky_forecast_max_temp
-- returns the max temp label for conky
--
function conky_forecast_max_temp()
    if get_forecast_value('cnt') then
        local _, max_temp = forecast_min_max_temp_rounded()
        return max_temp
    else
        return 'NA'
    end
end -- conky_forecast_max_temp


-------------------------------------------------------------------------------
--                                                                 rgb_to_r_g_b
-- converts color in hexa to decimal
--
function rgb_to_r_g_b(colour, alpha)
    return ((colour / 0x10000) % 0x100) / 255., ((colour / 0x100) % 0x100) / 255., (colour % 0x100) / 255., alpha
end -- rgb_to_r_g_b


-------------------------------------------------------------------------------
--                                                               draw_temp_grid
-- draw the forecast data grid
--
function draw_temp_grid(cr)
    cairo_set_line_width(cr, 1);
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
    cairo_set_source_rgba(cr, rgb_to_r_g_b(0xEF5A29, 1))

    -- top line
    cairo_move_to(cr, 105, FORECAST_TOP_LINE)
    cairo_line_to(cr, 490, FORECAST_TOP_LINE)
    -- bottom line
    cairo_move_to(cr, 105, FORECAST_BUTTOM_LINE)
    cairo_line_to(cr, 490, FORECAST_BUTTOM_LINE)

    cairo_stroke(cr)

    local min, max = forecast_min_max_temp_rounded()
    local diff = max - min
    local num_lines = (diff / 5) - 1
    local px_diff = 100 / (diff / 5)

    cairo_set_dash(cr, {5, 3}, 1, 1)
    cairo_set_source_rgba(cr, rgb_to_r_g_b(0xEF5A29, 0.5))
    for i = 1, num_lines do
        cairo_move_to(cr, 105, FORECAST_BUTTOM_LINE - i * px_diff)
        cairo_line_to(cr, 490, FORECAST_BUTTOM_LINE - i * px_diff)
    end

    cairo_stroke(cr)
end -- draw_temp_grid


-------------------------------------------------------------------------------
--                                                               draw_cairo_dot
-- draw a dot at the given position
--
function draw_cairo_dot(cr, x, y, r)
    cairo_set_line_width(cr, r*2);
    cairo_move_to(cr, x, y)
    cairo_line_to(cr, x, y)
    cairo_stroke(cr)
end -- draw_cairo_dot


-------------------------------------------------------------------------------
--                                                              draw_temp_graph
-- draw the temp graph from the forecast data
--
function draw_temp_graph(cr)
    local function calc_y(temp, max_temp)
        -- TODO
        -- 1. Wie viel Grad ist das mehr als min_temp?
        -- 2. Das dann auf die Scale von 0 bis 100 bringen (100px sind die Linien auseinander)
        return FORECAST_BUTTOM_LINE - math.round(temp * (FORECAST_BUTTOM_LINE - FORECAST_TOP_LINE) / max_temp)
    end

    cairo_set_line_width(cr, 1);
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
    cairo_set_dash(cr, {5, 3}, 0, 1)
    cairo_set_source_rgba(cr, rgb_to_r_g_b(0xEF5A29, 1))

    local _, max_temp = forecast_min_max_temp_rounded()
    local prev_p = {}
    local point = { x = 122, y = FORECAST_BUTTOM_LINE }
    for _, temp in ipairs(forecast_temp_values()) do
        point.y = calc_y(temp, max_temp)
        draw_cairo_dot(cr, point.x, point.y, 3)
        if prev_p.x and prev_p.y then
            cairo_set_line_width(cr, 1);
            cairo_move_to(cr, prev_p.x, prev_p.y)
            cairo_line_to(cr, point.x, point.y)
            cairo_stroke(cr)
        end
        prev_p = { x = point.x, y = point.y }
        point.x = point.x + 50
    end
end -- draw_temp_graph


-------------------------------------------------------------------------------
--                                                              draw_wind_graph
-- draw the wind graph from the forecast data
--
function draw_wind_graph(cr)
    local function calc_y(wind)
        local max_wind = forecast_max_wind_rounded()
        return FORECAST_BUTTOM_LINE - math.round(wind * (FORECAST_BUTTOM_LINE - FORECAST_TOP_LINE) / max_wind)
    end

    cairo_set_line_width(cr, 1);
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
    cairo_set_dash(cr, {5, 3}, 0, 1)
    cairo_set_source_rgba(cr, rgb_to_r_g_b(0x1081e0, 1))

    local prev_p = {}
    local point = { x = 122, y = FORECAST_BUTTOM_LINE }
    for _, wind in ipairs(forecast_wind_values()) do
        point.y = calc_y(wind)
        draw_cairo_dot(cr, point.x, point.y, 3)
        if prev_p.x and prev_p.y then
            cairo_set_line_width(cr, 1);
            cairo_move_to(cr, prev_p.x, prev_p.y)
            cairo_line_to(cr, point.x, point.y)
            cairo_stroke(cr)
        end
        prev_p = { x = point.x, y = point.y }
        point.x = point.x + 50
    end
end


-------------------------------------------------------------------------------
--                                                              draw_rain_graph
-- draw the rain forecast data
--
function draw_rain_graph(cr)
    local function calc_y(rain)
        -- TODO vielleicht besser 1px pro mm Regen?
        local _, max_rain = forecast_max_wind_rounded()
        return FORECAST_BUTTOM_LINE - math.round(rain * (FORECAST_BUTTOM_LINE - FORECAST_TOP_LINE) / 10)
    end

    cairo_set_line_width(cr, 26);
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_BUTT)
    cairo_set_dash(cr, {5, 3}, 0, 1)
    cairo_set_source_rgba(cr, rgb_to_r_g_b(0x1081e0, 0.4))

    local point_x = 122
    for _, rain in ipairs(forecast_rain_values()) do
        if rain >= 0 then
            cairo_move_to(cr, point_x, FORECAST_BUTTOM_LINE)
            cairo_line_to(cr, point_x, calc_y(rain))
        end
        point_x = point_x + 50
    end
    cairo_stroke(cr)
end -- draw_rain_graph


-------------------------------------------------------------------------------
--                                                                draw_forecast
-- draw the forecast data
--
function draw_forecast(cr)
    draw_temp_grid(cr)
    draw_temp_graph(cr)
    draw_wind_graph(cr)
    draw_rain_graph(cr)
end -- draw_forecast


-------------------------------------------------------------------------------
--                                                          conky_fetch_weather
function conky_fetch_weather()
    if conky_window == nil then
        return
    end

    local updates = tonumber(conky_parse('${updates}'))
    if updates >= 5 then
        local surface = cairo_xlib_surface_create(
            conky_window.display,
            conky_window.drawable,
            conky_window.visual,
            conky_window.width,
            conky_window.height)
        local cr = cairo_create(surface)

        call_time = os.time()
        if not last_city_fetch_time then
            last_city_fetch_time = call_time
        end
        if not last_weather_fetch_time then
            last_weather_fetch_time = call_time
        end

        local fetch_city = ((call_time - last_city_fetch_time) >= CITY_UPDATE_INTERVAL)
        if fetch_city or not city then
            city = fetch_current_city()
            last_city_fetch_time = call_time
        end

        --print(call_time - last_weather_fetch_time)
        local fetch_weather = ((call_time - last_weather_fetch_time) >= WEATHER_UPDATE_INTERVAL)
        if fetch_weather or not current_weather then
            fetch_current_weather()
            fetch_forecast()
            last_weather_fetch_time = call_time
        end
        draw_forecast(cr)

        cairo_surface_destroy(surface)
        cairo_destroy(cr)
    end
end -- conky_fetch_weather
