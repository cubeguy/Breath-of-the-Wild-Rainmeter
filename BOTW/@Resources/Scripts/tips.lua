function Initialize()
  dofile(SKIN:GetVariable('@') .. "Scripts\\JSON.lua")
  dofile(SKIN:GetVariable('@') .. "Scripts\\gametips.lua")
  previous_links = {}
  weather_index = 0
  tip_sequence = 0
  first_run = true
  math.randomseed(os.time())
  math.random()
end

function Update()
  -- Set all relevant meters and variables to default
  SKIN:Bang('!SetOption', 'MeterTitle', 'Text', "")
  SKIN:Bang('!SetOption', 'MeterTip', 'Text', "")
  SKIN:Bang('!SetOption', 'MeterBackdrop', 'LeftMouseDownAction', "")
  SKIN:Bang('!SetVariable', 'CurrentTip', '-1')

  -- Decide which tip to show
  if first_run then
    first_run = false
    SourceIngameTip()
    return
  end

  local tip_choices = {}

  if SKIN:GetVariable('RedditTips') ~= '0' then tip_choices[#tip_choices + 1] = SourceRedditForTip end
  if SKIN:GetVariable('WeatherTips') ~= '0' then tip_choices[#tip_choices + 1] = SourceWeatherForTip end
  if SKIN:GetVariable('GameTips') ~= '0' then tip_choices[#tip_choices + 1] = SourceIngameTip end
  if #tip_choices > 0 then
    if SKIN:GetVariable('SequentialTips') ~= '0' then
      tip_sequence = tip_sequence + 1
      if tip_sequence > #tip_choices then
        tip_sequence = 1
      end
      tip_choices[tip_sequence]()
    else
      local choice = math.random(#tip_choices)
      tip_choices[choice]()
    end
  end
end

function SourceIngameTip()
  local chosen_tip = math.random(#tip_titles)
  local tip_override = tonumber(SKIN:GetVariable('GameTipOverride'))
  if tip_override > 0 then
    if tip_override > #tip_titles then
      SKIN:Bang('!SetOption', 'MeterTitle', 'Text', 'Override Error')
      SKIN:Bang('!SetOption', 'MeterTip', 'Text', 'There are only ' .. tostring(#tip_titles) .. " tips to display, your override is too high.")
      return
    else
      chosen_tip = tip_override
    end
  end
  SKIN:Bang('!SetOption', 'MeterTitle', 'Text', tip_titles[chosen_tip])
  SKIN:Bang('!SetOption', 'MeterTip', 'Text', tip_text[chosen_tip])
  SKIN:Bang('!SetOption', 'MeterBackdrop', 'LeftMouseDownAction', "")
  SKIN:Bang('!SetVariable', 'CurrentTip', chosen_tip)
end

function SourceWeatherForTip()
  local unit = string.upper(SKIN:GetVariable('WeatherUnit'))
  local page_raw = SKIN:GetMeasure('WeatherFetchWebparser'):GetStringValue()
  local page = decode_json(page_raw)
  if page == nil then return end
  if page.query == nil then return end
  local weather_info = page.query.results.channel

  if weather_index == 0 then -- Display today's weather first
    SKIN:Bang('!SetOption', 'MeterTitle', 'Text', "Today's Weather")
    local tip_text = weather_info.item.condition.temp .. " °" .. unit .. ", " .. weather_info.item.condition.text .. ". "
    tip_text = tip_text .. "Wind speeds of " .. weather_info.wind.speed .. weather_info.units.speed
    tip_text = tip_text .. " and " .. weather_info.atmosphere.humidity .. "% humidity."
    SKIN:Bang('!SetOption', 'MeterTip', 'Text', tip_text)
  elseif weather_index == 1 then -- Then tomorrow's next
    SKIN:Bang('!SetOption', 'MeterTitle', 'Text', "Tomorrow's Forecast")
    local tomorrow = weather_info.item.forecast[1]
    local tip_text = tomorrow.text .. "; highs of " .. tomorrow.high .. " °" .. unit .. " and lows of " .. tomorrow.low .. " °" .. unit .. "."
    SKIN:Bang('!SetOption', 'MeterTip', 'Text', tip_text)
  elseif weather_index == 2 then -- do a 5-day forecast third
    SKIN:Bang('!SetOption', 'MeterTitle', 'Text', "Five-day Forecast")
    local tip_text = ""
    for i=1,5 do
      local day_weather = weather_info.item.forecast[i]
      tip_text = tip_text .. day_weather.day .. ": " .. day_weather.high .. " °" .. unit .. ", " .. day_weather.text .. ".  "
    end
    SKIN:Bang('!SetOption', 'MeterTip', 'Text', tip_text)
  elseif weather_index == 3 then -- and an abridged 10-day forecast fourth
    SKIN:Bang('!SetOption', 'MeterTitle', 'Text', "Ten-day Forecast")
    local tip_text = ""
    for i=1,10 do
      local day_weather = weather_info.item.forecast[i]
      tip_text = tip_text .. day_weather.day .. ": " .. day_weather.text .. ".  "
    end
    SKIN:Bang('!SetOption', 'MeterTip', 'Text', tip_text)
  end
  weather_index = (weather_index + 1) % 4
end

function SourceRedditForTip()
  local page_raw = SKIN:GetMeasure('MeasureRedditJson'):GetStringValue()
  local page = decode_json(page_raw)
  local tip_title = "Stasis"
  local tip_text = "Attacking objects stopped by Stasis will make them build up energy. This energy will then be released once the time-halting effect ends."
  local tip_link = ""
  local tip_has_link = false
  if page ~= nil then
    for i=1,#page.data.children do
      local item_data = page.data.children[i].data
      if item_data ~= nil then
        local is_previous_link = false
        for l=1,#previous_links do
          if previous_links[l] == item_data.id then
            is_previous_link = true
            break
          end
        end
        if not is_previous_link then
          tip_title = "Posted by /u/" .. item_data.author .. " on /" .. item_data.subreddit_name_prefixed
          tip_text = item_data.title
          tip_link = "https://www.reddit.com" .. item_data.permalink
          tip_has_link = true
          previous_links[#previous_links + 1] = item_data.id
          break
        end
      end
    end
  end
  SKIN:Bang('!SetOption', 'MeterTitle', 'Text', tip_title)
  SKIN:Bang('!SetOption', 'MeterTip', 'Text', tip_text)
  if tip_has_link then
    SKIN:Bang('!SetOption', 'MeterBackdrop', 'LeftMouseDownAction', "["..tip_link.."][Play #@#/Audio/SheikahSlateOpen.wav]")
    return true
  else
    SKIN:Bang('!SetOption', 'MeterBackdrop', 'LeftMouseDownAction', "")
    previous_links = {}
    return false
  end
end