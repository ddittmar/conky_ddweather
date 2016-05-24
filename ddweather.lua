--==============================================================================
--                            ddweather.lua
--
--  Author  : Dirk Dittmar
--  License : Distributed under the terms of GNU GPL version 2 or later
--
--==============================================================================
-- TODO <div>Icons made by <a href="http://www.flaticon.com/authors/madebyoliver" title="Madebyoliver">Madebyoliver</a> from <a href="http://www.flaticon.com" title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>


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
--                                                  update intervall in seconds
UPDATE_INTERVAL = 1800

-------------------------------------------------------------------------------
--                                                  position of the buttom line
FORECAST_BUTTOM_LINE = 345


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
-- add a value to the cache
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
        local cnt = tonumber(get_forecast_value('cnt'))
        for i = 1, cnt do
            local temp = tonumber(get_forecast_value('list', i, 'main', 'temp'))
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
--                                                forecast_min_max_temp_rounded
-- find min and max temp values in the forecast
--
function forecast_min_max_temp_rounded()
    local min_temp, max_temp = forecast_min_max_temp()
    return math.roundToMulti(min_temp, 5) - 5, math.roundToMulti(max_temp, 5) + 5
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

-- TODO doc
function forecast_max_wind()
    local max = 0
    for wind in ipairs(forecast_wind_values()) do
        if wind > max then
            max = wind
        end
    end
    return max
end

-- TODO doc
function forecast_max_wind_rounded()
    return math.roundToMulti(forecast_max_wind(), 5)
end

-- TODO doc
function conky_forecast_max_wind()
    if (get_forecast_value('cnt')) then
        return forecast_max_wind_rounded()
    else
        return 'NA'
    end
end

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
    cairo_move_to(cr, 105, 245)
    cairo_line_to(cr, 490, 245)
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
        return FORECAST_BUTTOM_LINE - (temp * 100 / max_temp)
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
    local function calc_y(wind, max_wind)
        return FORECAST_BUTTOM_LINE - wind * 100 / max_wind
    end

    cairo_set_line_width(cr, 1);
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
    cairo_set_dash(cr, {5, 3}, 0, 1)
    cairo_set_source_rgba(cr, rgb_to_r_g_b(0x1081e0, 1))

    local max_wind = forecast_max_wind_rounded()
    local prev_p = {}
    local point = { x = 122, y = FORECAST_BUTTOM_LINE }
    for _, wind in ipairs(forecast_wind_values()) do
        point.y = calc_y(wind, max_wind)
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
--                                                                draw_forecast
-- draw the forecast data
--
function draw_forecast(cr)
    draw_temp_grid(cr)
    draw_temp_graph(cr)
    draw_wind_graph(cr)
    -- TODO draw the rain graph
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
        if not last_call_time then
            last_call_time = call_time
        end

        local fetch = ((call_time - last_call_time) % UPDATE_INTERVAL) == 0
        if fetch or not current_weather then
            local fetch_city = ((call_time - last_call_time) % (UPDATE_INTERVAL * 4)) == 0
            if fetch_city or not city then
                city = fetch_current_city()
            end
            fetch_current_weather()
            fetch_forecast()
        end
        draw_forecast(cr)

        cairo_surface_destroy(surface)
        cairo_destroy(cr)

        last_call_time = call_time
    end
end -- conky_fetch_weather
