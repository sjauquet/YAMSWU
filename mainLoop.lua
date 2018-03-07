-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- WU WeatherData - Fetch weather data from wunderground.com. Multilanguage support!
-- Original Code by Jonny Larsson 2015 http://forum.fibaro.com/index.php?/topic/19810-wu-weatherdata-version-202-2015-10-25/
-- forked by Sébastien Jauquet 11/2015
-- Inspired by GEA(steven), stevenvd, Krikroff and many other users.
-- Source - forum.fibaro.com, domotique-fibaro.fr and worldwideweb
--
-- Version 3.7
--
-- PWS = Personal Weather Station
-- LOCID = Public station
-- 
-- 2014-03-22 - Permissions granted from Krikroff 
-- 2014-03-23 - Added rain and forecast, Added FR language. 
-- 2014-03-23 - Language variable changed to get the translation from wunderground.com in forcast
-- 2014-03-24 - Added PL language
-- 2014-03-24 - Select between PWS or LOCID to download weather data
-- 2015-10-23 - New source code.

-- 2015-11-13 - V3.0 - Fork Code by Sebastien Jauquet (3 days forecast, rain in mm)
-- 2015-11-14 - V3.1 - Compatibilty with GEA, French translation
-- 2015-11-14 - V3.2 - Catch rain errors (-999mm null empty etc.)
-- 2015-11-14 - V3.3 - Catch json decode error (was stopping main loop) with pcall (can be extended to other jdon datas if needed)
-- 2015-11-16 - V3.4 - Generate HTML and non HTML version (for compatibility with mobiles)
-- 2015-11-18 - V3.5 - Fixed bug not updating Meteo_Day becaus WU.now was only updated at first launch
-- 2015-11-18 - V3.6 - Merged some changes from jompa new version
-- 2015-11-18 - 		Added autmatic creation of Global Variables if not existing
-- 2015-11-19 - V3.7 - Modify schedule management and CleanUp code
-- Look for nearest station here: http://www.wunderground.com

-------------------------------------------------------------------------------------------
-- MAIN CODE --
-------------------------------------------------------------------------------------------
WU = {}
-- WU settings
WU.APIkey = "xxxxxxxxxxxxxxx"		        -- Put your WU api key here
WU.PWS = "IGVLEBOR5" 				-- The PWS location to get data for (Personal Weather Station)
WU.LOCID = "SWXX0076" 				-- The location ID to get data for (City location)
WU.station = "PWS" 				-- PWS or LOCID
-- Other settings
WU.translation = {true}
WU.language = "FR";				-- EN, FR, SW, PL (default is en)
WU.smartphoneID = 1347				-- your smartphone ID
WU.sendPush = true				-- send forecast as push message
WU.push_fcst1 = "07:00"				-- time when forecast for today will be pushed to smartphone
WU.push_fcst2 = "18:15"				-- time when forecast for tonight will be pushed to smartphone
WU.GEA = true					-- subst % with %% when storing in the VG's (because gea bug with % in push messages)
WU.CreateVG = true				-- will atomaticaly create global variables at first run if = true
updateEvery = 30				-- get data every xx minutes
WU.startTime = os.time()
WU.scheduler = os.time()+60*updateEvery
WU.currentDate = os.date("*t");
WU.now = os.date("%H:%M");
DoNotRecheckBefore = os.time()
WU.selfId = fibaro:getSelfId()
WU.version = "3.7"

WU.translation["EN"] = {
	Push_forecast = "Push forecast",
	Exiting_loop_slider = "Exiting loop earlier (Slider Changed)",
	Exiting_loop_push = "Exiting loop earlier (For push)",
	Last_updated = "Last updated",
	Temperature = "Temperature",
	Humidity = "Humidity",
	Pressure = "Pressure",
	Wind = "Wind",
	Rain = "Rain",
	Forecast = "Forecast",
	Station = "Station",
	Fetched = "Fetched",
	Data_processed = "Data processed",
	Update_interval = "Next update will be in (min)",
	No_data_fetched = "No data fetched",
	NO_STATIONID_FOUND = "No stationID found",
	NO_DATA_FOUND = "No data found"
	}
WU.translation["FR"] = {
	Push_forecast = "Push des prévisions",
	Exiting_loop_slider = "Sortie de boucle (Slider Changé)",
	Exiting_loop_push = "Sortie de boucle (Pour Push)",
	Last_updated = "Mise à  jour",
	Temperature = "Actuellement",
	Humidity = "Hum",
	Pressure = "Pression",
	Wind = "Vent",
	Rain = "Pluie",
	Forecast = "Prévisions pour ce",
	Station = "Station",
	Fetched = "Données Reçues",
	Data_processed = "Données mises à  jour",
	Update_interval = "Prochaine Mise à  jour prévue dans (min)",
	No_data_fetched = "Pas de données reçues !!",
	NO_STATIONID_FOUND = "StationID non trouvée !!",
	NO_DATA_FOUND = "Pas de données disponibles !!"
	}
WU.translation["SW"] = {
	Push_forecast = "Push forecast",
	Exiting_loop_slider = "Exiting loop earlier (Slider Changed)",
	Exiting_loop_push = "Exiting loop earlier (For push)",
	Last_updated = "Last updated",
	Temperature = "Temperatur",
	Humidity = "Fuktighet",
	Pressure = "Barometer",
	Wind = "Vind",
	Rain = "Regn",
	Forecast = "Prognos",
	Station = "Station",
	Fetched = "Hà¤mtat",
	Data_processed = "All data processat",
	Update_interval = "Nà¤sta uppdatering à¤r om (min)",
	No_data_fetched = "Inget data hà¤mtat",
	NO_STATIONID_FOUND = "StationID ej funnet",
	NO_DATA_FOUND = "Ingen data hos WU"
	}
WU.translation["PL"] = {
	Push_forecast = "Push prognoza",
	Exiting_loop_slider = "Exiting loop earlier (Slider Changed)",
	Exiting_loop_push = "Exiting loop earlier (For push)",
	Last_updated = "Last updated",
	Temperature = "Temperatura",
	Humidity = "Wilgotnosc",
	Pressure = "Pressure",
	Wind = "Wiatr",
	Rain = "Rain",
	Forecast = "Forecast",
	Station = "Station",
	Fetched = "Fetched",
	Data_processed = "Data processed",
	No_data_fetched = "No data fetched",
	Update_interval = "Next update will be in (min)",
	NO_STATIONID_FOUND = "No stationID found",
	NO_DATA_FOUND = "No data found"
	}
WU.translation["NL"] = {
	Push_forecast = "Push verwachting",
	Exiting_loop_slider = "Exiting loop earlier (Slider Changed)",
	Exiting_loop_push = "Exiting loop earlier (For push)",
	Last_updated = "Last updated",
	Temperature = "Temperatuur",
	Humidity = "Vochtigheid",
	Pressure = "Druk",
	Wind = "Wind",
	Rain = "Regen",
	Forecast = "Verwachting",
	Station = "Weerstation",
	Fetched = "Ontvangen",
	Data_processed = "Gegevens verwerkt",
	Update_interval = "Volgende update in (min)",
	No_data_fetched = "Geen gegevens ontvangen",
	NO_STATIONID_FOUND = "Geen stationID gevonden",
	NO_DATA_FOUND = "Geen gegevens gevonden"
	}
WU.translation["DE"] = {
	Push_forecast = "Push vorhersage",
	Exiting_loop_slider = "Exiting loop earlier (Slider Changed)",
	Exiting_loop_push = "Exiting loop earlier (For push)",
	Last_updated = "Last updated",
	Temperature = "Temperatur",
	Humidity = "Luftfeuchtigkeit",
	Pressure = "Luftdruck",
	Wind = "Wind",
	Rain = "Regen",
	Forecast = "Vorhersage",
	Station = "Station",
	Fetched = "Abgerufen",
	Data_processed = "Daten verarbeitet",
	No_data_fetched = "Keine Daten abgerufen",
	Update_interval = "Das nà¤chste Update in (min)",
	NO_STATIONID_FOUND = "Keine stationID gefunden",
	NO_DATA_FOUND = "Keine Daten gefunden"
	}

Debug = function ( color, message )
	fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span"));
end
WU.createGlobalIfNotExists = function (varName, defaultValue)
	if (fibaro:getGlobal(varName) == "") then
		Debug("red", "Global Var: "..varName.." HAS BEEN CREATED")
		newVar = {}
		newVar.name = varName
		HC2 = Net.FHttp("127.0.0.1", 11111)
		HC2:POST("/api/globalVariables", json.encode(newVar))
	end
end
WU.substPercent = function(doublePercentSymbol)
	if 	WU.GEA then
		doublePercentSymbol = string.gsub(doublePercentSymbol, "%%.", "%%%%")
	end
	return doublePercentSymbol
end
WU.cleanJson = function(jsontocheck,returnIfTrue)
	if jsontocheck == "-999.00" or jsontocheck == "--" or jsontocheck == json.null then
	jsontocheck = returnIfTrue
	end
		local ok = pcall(function()
			testConcatenate = "Test Concatenate: " .. jsontocheck -- test for non concatenate value
			end )
		if (not ok) then
			decode_error = true
			Debug( "red", "decode raised an error")
			fibaro:call(WU.smartphoneID , "sendPush", "decode error in WU Meteo")
		end
	return jsontocheck
end
WU.HtmlColor = function(StringToColor,color)
	if MobileDisplay == false then 
	StringToColor= "<font color=\""..color.."\"> "..StringToColor.."</font>"
	end
	return StringToColor
end
WU.IconOrText = function(icon,txt)
	if MobileDisplay == false then 
	IconOrText = "<img src="..icon.."\>"
	else
	IconOrText = txt
	end
	return IconOrText
end
WU.getSlider = function()
	ValeurSliderfunct = fibaro:getValue(WU.selfId , "ui.WebOrMobile.value")
	return tonumber(ValeurSliderfunct)
end
WU.setSlider = function(position)
	fibaro:call(WU.selfId , "setProperty", "ui.WebOrMobile.value", position)
	return WU.getSlider()
end
WU.checkMobileOrWeb = function()
	ValeurSliderSleep = WU.getSlider() -- check slider value at first run
	if ValeurSliderSleep <= 50 then 
		if ValeurSliderSleep == 1 then
		MobileDisplay = false
		else
		MobileDisplay = false
		WU.runDirect = 1
		sleepAndcheckslider = 20*updateEvery -- exit wait loop
		Debug("orange", WU.translation[WU.language]["Exiting_loop_slider"]);
		end
		WU.setSlider(1) -- désactive le run immediat lors du prochain test
	end
	if ValeurSliderSleep >= 50 then
		if ValeurSliderSleep == 98 then
		else
		MobileDisplay = true		
		WU.runDirect = 1
		sleepAndcheckslider = 20*updateEvery -- exit wait loop
		Debug("orange", WU.translation[WU.language]["Exiting_loop_slider"]);
		end
		WU.setSlider(98) -- désactive le run immediat lors du prochain test
	end 
  return WU.getSlider()
end
WU.fetchWU = function()
decode_error = false
WU.checkMobileOrWeb()
local WGROUND = Net.FHttp("api.wunderground.com",80);
local response ,status, err = WGROUND:GET("/api/"..WU.APIkey.."/conditions/forecast/lang:"..WU.language.."/q/"..WU.station..":"..locationID..".json");
if (tonumber(status) == 200 and tonumber(err)==0) then
	Debug( "cyan", WU.translation[WU.language]["Fetched"])
	if (response ~= nil) then
		WU.now = os.date("%H:%M")
		jsonTable = json.decode(response);
		if jsonTable.response.error ~= nil then
			Debug( "red", WU.translation[WU.language]["NO_DATA_FOUND"])
        	fibaro:sleep(15*1000)
		return
		end
		stationID = jsonTable.current_observation.station_id;
		humidity = jsonTable.current_observation.relative_humidity
		temperature = jsonTable.current_observation.temp_c
		pression = jsonTable.current_observation.pressure_mb
		wind = jsonTable.current_observation.wind_kph
		rain = WU.cleanJson(jsonTable.current_observation.precip_today_metric,"0")
		weathericon = jsonTable.current_observation.icon_url
		fcstday1 = jsonTable.forecast.txt_forecast.forecastday[1].title -- Day meteo
			fcst1 = jsonTable.forecast.txt_forecast.forecastday[1].fcttext_metric
			fcst1icon = jsonTable.forecast.txt_forecast.forecastday[1].icon_url
			fcst1SmallTxt = jsonTable.forecast.simpleforecast.forecastday[1].conditions
			fcst1Tmax = jsonTable.forecast.simpleforecast.forecastday[1].high.celsius
			fcst1Tmin = jsonTable.forecast.simpleforecast.forecastday[1].low.celsius
			fcst1avewind =jsonTable.forecast.simpleforecast.forecastday[1].avewind.kph
			fcst1avewinddir =jsonTable.forecast.simpleforecast.forecastday[1].avewind.dir
			fcst1mm = WU.cleanJson(jsonTable.forecast.simpleforecast.forecastday[1].qpf_day.mm,"0")
		fcstday2 = jsonTable.forecast.txt_forecast.forecastday[2].title -- Evening Meteo
			fcst2 = jsonTable.forecast.txt_forecast.forecastday[2].fcttext_metric
			fcst2icon = jsonTable.forecast.txt_forecast.forecastday[2].icon_url
			fcst2SmallTxt = jsonTable.forecast.simpleforecast.forecastday[2].conditions
			fcst2Tmax = jsonTable.forecast.simpleforecast.forecastday[2].high.celsius
			fcst2Tmin = jsonTable.forecast.simpleforecast.forecastday[2].low.celsius
			fcst2avewind =jsonTable.forecast.simpleforecast.forecastday[2].avewind.kph
			fcst2avewinddir =jsonTable.forecast.simpleforecast.forecastday[2].avewind.dir
			fcst2mm = WU.cleanJson(jsonTable.forecast.simpleforecast.forecastday[1].qpf_night.mm,"0")
		fcstday3 = jsonTable.forecast.txt_forecast.forecastday[3].title -- Tomorrow
			fcst3 = jsonTable.forecast.txt_forecast.forecastday[3].fcttext_metric
			fcst3icon = jsonTable.forecast.txt_forecast.forecastday[1].icon_url
			fcst3SmallTxt = jsonTable.forecast.simpleforecast.forecastday[1].conditions
			fcst3Tmax = jsonTable.forecast.simpleforecast.forecastday[1].high.celsius
			fcst3Tmin = jsonTable.forecast.simpleforecast.forecastday[1].low.celsius
			fcst3avewind =jsonTable.forecast.simpleforecast.forecastday[1].avewind.kph
			fcst3avewinddir =jsonTable.forecast.simpleforecast.forecastday[1].avewind.dir
			fcst3mm = WU.cleanJson(jsonTable.forecast.simpleforecast.forecastday[2].qpf_allday.mm,"0")
		fcstday5 = jsonTable.forecast.txt_forecast.forecastday[5].title -- In 2 days
			fcst5 = jsonTable.forecast.txt_forecast.forecastday[5].fcttext_metric
			fcst5icon = jsonTable.forecast.txt_forecast.forecastday[1].icon_url
			fcst5SmallTxt = jsonTable.forecast.simpleforecast.forecastday[1].conditions
			fcst5Tmax = jsonTable.forecast.simpleforecast.forecastday[1].high.celsius
			fcst5Tmin = jsonTable.forecast.simpleforecast.forecastday[1].low.celsius
			fcst5avewind =jsonTable.forecast.simpleforecast.forecastday[1].avewind.kph
			fcst5avewinddir =jsonTable.forecast.simpleforecast.forecastday[1].avewind.dir
			fcst5mm = WU.cleanJson(jsonTable.forecast.simpleforecast.forecastday[3].qpf_allday.mm,"0")

		if (stationID ~= nil) and decode_error == false  then
			fibaro:call(WU.selfId , "setProperty", "ui.lblStation.value", locationID);
			if temperature < 5 then
			cTemperature = WU.HtmlColor(temperature,"blue")
			elseif temperature > 18 then
			cTemperature = WU.HtmlColor(temperature,"red")
			else
			cTemperature = WU.HtmlColor(temperature,"yellow")
			end
			fibaro:call(WU.selfId , "setProperty", "ui.lblTempHum.value", WU.translation[WU.language]["Temperature"]..": "..cTemperature.." °C - "..WU.translation[WU.language]["Humidity"]..": "..humidity);
			fibaro:call(WU.selfId , "setProperty", "ui.lblWindRain.value", WU.translation[WU.language]["Wind"]..": "..wind.." km/h - "..WU.translation[WU.language]["Rain"]..": "..rain.." mm");
			if (WU.now >= "00:00" and WU.now <= "15:59") then -- donne meteo du jour entre 00:00 (ou 3h) et 15:59. permet de garder la météo du soir jusqu'a 3h du matin, sinon change à  minuit
			fibaro:call(WU.selfId , "setProperty", "ui.lblFcst.value", WU.translation[WU.language]["Forecast"].." "..WU.HtmlColor(fcstday1,"yellow")..": "..WU.HtmlColor(fcst1.." ("..fcst1mm.." mm)","green"));
			fibaro:setGlobal("Meteo_Day", WU.substPercent(WU.translation[WU.language]["Forecast"].." "..fcstday1..": ".." "..fcst1.." ("..fcst1mm.." mm)") );
			fibaro:call(WU.selfId , "setProperty", "ui.lblIcon.value",WU.IconOrText(fcst1icon,fcst1SmallTxt));
			elseif (WU.now >= "16:00" and WU.now <= "23:59") then  -- donne meteo soirée entre 16:00 et 23:59
			fibaro:call(WU.selfId , "setProperty", "ui.lblFcst.value", WU.translation[WU.language]["Forecast"].." "..WU.HtmlColor(fcstday2,"yellow")..": "..WU.HtmlColor(fcst2.." ("..fcst2mm.." mm)","green"));
			fibaro:setGlobal("Meteo_Day", WU.substPercent(WU.translation[WU.language]["Forecast"].." "..fcstday2..": ".." "..fcst2.." ("..fcst2mm.." mm)") );
			fibaro:call(WU.selfId , "setProperty", "ui.lblIcon.value",WU.IconOrText(fcst2icon,fcst2SmallTxt));
			end
			-- Meteo of Tomorrow
			fibaro:call(WU.selfId , "setProperty", "ui.lblFcstTomorrow.value", WU.translation[WU.language]["Forecast"].." "..WU.HtmlColor(fcstday3,"yellow")..": "..WU.HtmlColor(fcst3.." ("..fcst3mm.." mm)","green"));
			fibaro:setGlobal("Meteo_Tomorrow", WU.substPercent(WU.translation[WU.language]["Forecast"].." "..fcstday3..": ".." "..fcst3.." ("..fcst3mm.." mm)") );
			fibaro:call(WU.selfId , "setProperty", "ui.lblIconTomorrow.value",WU.IconOrText(fcst3icon,fcst3SmallTxt));
			-- Meteo in 2 Days
			fibaro:call(WU.selfId , "setProperty", "ui.lblFcst2Days.value", WU.translation[WU.language]["Forecast"].." "..WU.HtmlColor(fcstday5,"yellow")..": "..WU.HtmlColor(fcst5.." ("..fcst5mm.." mm)","green"));
			fibaro:setGlobal("Meteo_In_2_Days", WU.substPercent(WU.translation[WU.language]["Forecast"].." "..fcstday5..": ".." "..fcst5.." ("..fcst5mm.." mm)") );
			fibaro:call(WU.selfId , "setProperty", "ui.lblIcon2Days.value",WU.IconOrText(fcst5icon,fcst5SmallTxt));
			if WU.sendPush then
				if (os.date("%H:%M") == WU.push_fcst1) then --
					fibaro:call(WU.smartphoneID , "sendPush", fcstday1.." - "..fcst1) -- envoie meteo du matin
				elseif (os.date("%H:%M") == WU.push_fcst2) then
					fibaro:call(WU.smartphoneID , "sendPush", fcstday2.." - "..fcst2) -- envoie meteo du soir
				end
			end
			if WU.sendPush then
				fibaro:call(WU.selfId , "setProperty", "ui.lblNotify.value", WU.translation[WU.language]["Push_forecast"].."  = true");
			else fibaro:call(WU.selfId , "setProperty", "ui.lblNotify.value",WU.translation[WU.language]["Push_forecast"].."  = false");
			end
			WU.scheduler = os.time()+updateEvery*60
			fibaro:call(WU.selfId, "setProperty", "ui.lblUpdate.value", WU.translation[WU.language]["Last_updated"]..": "..os.date("%c"));
			Debug( "cyan", WU.translation[WU.language]["Data_processed"])
			Debug( "white", WU.translation[WU.language]["Update_interval"].." "..updateEvery)
		else
		Debug( "red", WU.translation[WU.language]["NO_STATIONID_FOUND"])
		end
	else
	fibaro:debug("status:" .. status .. ", errorCode:" .. errorCode);
	end
end
sleepAndcheckslider = 0
while sleepAndcheckslider <= 20*updateEvery do
	fibaro:sleep(3000)
	WU.checkMobileOrWeb()
	sleepAndcheckslider = sleepAndcheckslider+1
	if (DoNotRecheckBefore <= os.time()) and ((WU.scheduler == os.time) or (os.date("%H:%M") == WU.push_fcst1) or (os.date("%H:%M") == WU.push_fcst2)) then
		Debug("orange", WU.translation[WU.language]["Exiting_loop_push"]);
		DoNotRecheckBefore = os.time()+60
		sleepAndcheckslider = 20*updateEvery
	end
end
end

Debug( "orange", "WU Weather - Original LUA Scripting by Jonny Larsson 2015");
Debug( "orange", "YAMS WU - Fork by Sébastien Jauquet 11/2015");
Debug( "orange", "Version: "..WU.version);
if WU.station == "LOCID" then
	locationID = WU.LOCID
elseif 
	WU.station == "PWS" then
	locationID = WU.PWS	
end
if WU.CreateVG then
	WU.createGlobalIfNotExists("Meteo_Day", "")
	WU.createGlobalIfNotExists("Meteo_Tomorrow", "")
	WU.createGlobalIfNotExists("Meteo_In_2_Days", "")
end
while true do 
	WU.fetchWU()
end
