-------------------------------------------------------------------------------------------
-- WU WeatherData - Fetch weather data from wunderground.com. Multilanguage support!
-- Original Code by Jonny Larsson 2015 http://forum.fibaro.com/index.php?/topic/19810-wu-weatherdata-version-202-2015-10-25/
-- Forked by Sébastien Jauquet 11/2015 http://www.domotique-fibaro.fr/index.php/topic/6446-yams-wu-yet-another-meteo-station-wunderground-version/
-- Inspired by GEA(steven), stevenvd, Lazer, Krikroff and many other users.
-- Source - forum.fibaro.com, domotique-fibaro.fr and worldwideweb

-- 2014-03-22 - Permissions granted from Krikroff 
-- 2014-03-23 - Added rain and forecast, Added FR language. 
-- 2014-03-23 - Language variable changed to get the translation from wunderground.com in forcast
-- 2014-03-24 - Added PL language
-- 2014-03-24 - Select between PWS or LOCID to download weather data
-- 2015-10-23 - New source code.
-- 2015-11-16 - Permissions granted from Jonny Larsson

-- 2015-11-13 - V3.0 - Fork Code by Sebastien Jauquet (3 days forecast, rain in mm)
-- 2015-11-14 - V3.1 - Compatibilty with GEA, French translation
-- 2015-11-14 - V3.2 - Catch rain errors (-999mm null empty etc.)
-- 2015-11-14 - V3.3 - Catch json decode error (was stopping main loop) with pcall (can be extended to other jdon datas if needed)
-- 2015-11-16 - V3.4 - Generate HTML and non HTML version (for compatibility with mobiles)
-- 2015-11-18 - V3.5 - Fixed bug not updating Meteo_Day becaus WU.now was only updated at first launch
-- 2015-11-18 - V3.6 - Merged some changes from jompa new version
-- 2015-11-18 - 		Added autmatic creation of Global Variables if not existing
-- 2015-11-19 - V3.7 - Modify schedule management and CleanUp code
-- 2015-11-22 - V3.8 - Finalise mobile version and bug fixing
-- 2015-11-23 - V3.9 - Added multiple notification options (Lazer way)
-- 2015-11-30 - V4.0 - More precision for rain mm (moring/evening) + added feels like T° + optimized display
-- 2016-07-11 - V4.1 - Added Speech VG, with subst of symbols of day, tomorrow and Day+2 to be more speech compatible (in french only, sorry)
-- Look for nearest station here: http://www.wunderground.com
-- 2016-10-01 - V4.2 - Removed HTML tags
-- 2018-03-07 - V4.3 - Mod création des VG si elles n'existent pas. (non testé, code from: https://www.domotique-fibaro.fr/topic/6446-yams-wu-yet-another-meteo-station-wunderground-version/?do=findComment&comment=169513

-------------------------------------------------------------------------------------------
-- MAIN CODE --
-------------------------------------------------------------------------------------------
WU = {};
-- WU settings
	--WU.APIkey = "XXXXXXXXXxxxxxXX";		-- Put your WU api key here
	--WU.PWS = "IGVLEBOR5";				-- The PWS location to get data from (Personal Weather Station)
	--WU.LOCID = "SWXX0076";				-- The location ID to get data from (City location)
	--WU.station = "PWS";					-- Choose your prefered method to retrieve from: PWS or LOCID
	WU.APIkey = "XXXXXxxxxxXXXXXXX";			-- Put your WU api key here
	WU.PWS = "XXXXXXXXXX";					-- The PWS location to get data from (Personal Weather Station)
	WU.LOCID = "XXXXXXX";					-- The location ID to get data from (Public City location)
	WU.station = "LOCID";						-- Choose your prefered method to retrieve from: PWS or LOCID
-- notifications
	WU.notifications = true;				-- send notifications
	WU.push_fcst1 = "11:30";				-- time when forecast for today will be pushed to smartphone
	WU.push_fcst2 = "18:15";				-- time when forecast for tonight will be pushed to smartphone
	WU.notificationTypes = {"push", "email"};--notification types {"push", "email", "sms"}
	WU.smartphoneID = {1347};				-- Smartphone Id to send push to. {id1, id2, id3}
	WU.userID = {2};						-- User Id to send email to. {id1, id2, id3}
	WU.sms = {
		["VD_ID"] = 0,						-- Virtual Device ID
		["VD_Button"] = "1",				-- Virtual Device Button
		["VG_Name"] = "SMS"};				-- Global Variable Name
	WU.debug_messages = false;				-- Diplay debug for notifications
-- Other settings
	WU.translation = {true};
	WU.language = "FR";						-- EN, FR, SW, PL (default is en)
	WU.GEA = true;							-- subst % with %% when storing in the VG's (because gea bug with % in push messages)
	WU.CreateVG = true;						-- will atomaticaly create global variables at first run if = true
	WU.updateEvery = 30;					-- get data every xx minutes
-- Do not change
	WU.startTime = os.time();
	WU.scheduler = os.time()+60*WU.updateEvery;
	WU.currentDate = os.date("*t");
	WU.now = os.date("%H:%M");
	WU.DoNotRecheckBefore = os.time();
	WU.selfId = fibaro:getSelfId();
	WU.version = "4.3";

WU.translation["EN"] = {
	Push_forecast = "Push forecast",
	Exiting_loop_slider = "Exiting loop earlier (Slider Changed)",
	Exiting_loop_push = "Exiting loop earlier (For push)",
	Last_updated = "Last updated",
	Temperature = "T°/Feels Like",
	Humidity = "Humidity",
	Pressure = "Pressure",
	Wind = "Wind",
	Rain = "Rain",
	Forecast = "Forecast ",
	EmailSubject = "Meteo of this",
	Station = "Station",
	Fetched = "Fetched",
	Data_processed = "Data processed",
	Update_interval = "Next update will be in (min)",
	No_data_fetched = "No data fetched",
	NO_STATIONID_FOUND = "No stationID found",
	NO_DATA_FOUND = "No data found"
	};
WU.translation["FR"] = {
	Push_forecast = "Push des prévisions",
	Exiting_loop_slider = "Sortie de boucle (Slider Changé)",
	Exiting_loop_push = "Sortie de boucle (Pour Push)",
	Last_updated = "Mise àjour",
	Temperature = "T°/Ressentie",
	Humidity = "Humidité",
	Pressure = "Pression",
	Wind = "Vent",
	Rain = "Pluie",
	Forecast = "",
	EmailSubject = "Météo de ce",
	Station = "Station",
	Fetched = "Données reçues",
	Data_processed = "Données mises àjour",
	Update_interval = "Prochaine Mise àjour prévue dans (min)",
	No_data_fetched = "Pas de données reçues !!",
	NO_STATIONID_FOUND = "StationID non trouvée !!",
	NO_DATA_FOUND = "Pas de données disponibles !!"
	};
WU.translation["SW"] = {
	Push_forecast = "Push forecast",
	Exiting_loop_slider = "Exiting loop earlier (Slider Changed)",
	Exiting_loop_push = "Exiting loop earlier (For push)",
	Last_updated = "Last updated",
	Temperature = "T°/Feels Like",
	Humidity = "Fuktighet",
	Pressure = "Barometer",
	Wind = "Vind",
	Rain = "Regn",
	Forecast = "Prognos ",
	EmailSubject = "Meteo of this",
	Station = "Station",
	Fetched = "Hämtat",
	Data_processed = "All data processat",
	Update_interval = "Nästa uppdatering är om (min)",
	No_data_fetched = "Inget data hämtat",
	NO_STATIONID_FOUND = "StationID ej funnet",
	NO_DATA_FOUND = "Ingen data hos WU"
	};
WU.translation["PL"] = {
	Push_forecast = "Push prognoza",
	Exiting_loop_slider = "Exiting loop earlier (Slider Changed)",
	Exiting_loop_push = "Exiting loop earlier (For push)",
	Last_updated = "Last updated",
	Temperature = "T°/Feels Like",
	Humidity = "Wilgotnosc",
	Pressure = "Pressure",
	Wind = "Wiatr",
	Rain = "Rain",
	Forecast = "Forecast ",
	EmailSubject = "Meteo of this",
	Station = "Station",
	Fetched = "Fetched",
	Data_processed = "Data processed",
	No_data_fetched = "No data fetched",
	Update_interval = "Next update will be in (min)",
	NO_STATIONID_FOUND = "No stationID found",
	NO_DATA_FOUND = "No data found"
	};
WU.translation["NL"] = {
	Push_forecast = "Push verwachting",
	Exiting_loop_slider = "Exiting loop earlier (Slider Changed)",
	Exiting_loop_push = "Exiting loop earlier (For push)",
	Last_updated = "Last updated",
	Temperature = "T°/Feels Like",
	Humidity = "Vochtigheid",
	Pressure = "Druk",
	Wind = "Wind",
	Rain = "Regen",
	Forecast = "Verwachting ",
	EmailSubject = "Meteo of this",
	Station = "Weerstation",
	Fetched = "Ontvangen",
	Data_processed = "Gegevens verwerkt",
	Update_interval = "Volgende update in (min)",
	No_data_fetched = "Geen gegevens ontvangen",
	NO_STATIONID_FOUND = "Geen stationID gevonden",
	NO_DATA_FOUND = "Geen gegevens gevonden"
	};
WU.translation["DE"] = {
	Push_forecast = "Push vorhersage",
	Exiting_loop_slider = "Exiting loop earlier (Slider Changed)",
	Exiting_loop_push = "Exiting loop earlier (For push)",
	Last_updated = "Last updated",
	Temperature = "T°/Feels Like",
	Humidity = "Luftfeuchtigkeit",
	Pressure = "Luftdruck",
	Wind = "Wind",
	Rain = "Regen",
	Forecast = "Vorhersage ",
	EmailSubject = "Meteo of this",
	Station = "Station",
	Fetched = "Abgerufen",
	Data_processed = "Daten verarbeitet",
	No_data_fetched = "Keine Daten abgerufen",
	Update_interval = "Das nächste Update in (min)",
	NO_STATIONID_FOUND = "Keine stationID gefunden",
	NO_DATA_FOUND = "Keine Daten gefunden"
	};

Debug = function (color, message)
	if color and color ~= "" then
		fibaro:debug('<span style="color:'..color..';">'..message..'</span>');
	else
		fibaro:debug(message);
	end
end
WU.notification = function(message, subject, param)
	local message = message or "<vide>";
	if WU.debug_messages then
		Debug("yellow", "Notification : "..message);
	end
	if param then
		for _, notif in ipairs(param) do
			if WU.debug_messages then
				Debug("grey", notif);
			end
			-- Envoi Push
			if notif == "push" and WU.smartphoneID then
				for _, id in ipairs(WU.smartphoneID) do
					if WU.debug_messages then
						Debug("grey", "Send Push smartphone ID : "..id);
					end
					fibaro:call(id, "sendPush", message);
				end
			-- Envoi Email
			elseif notif == "email" and WU.userID then
				for _, id in ipairs(WU.userID) do
					if WU.debug_messages then
						Debug("grey", "Send Email user ID : "..id);
					end
					fibaro:call(id, "sendEmail", subject, message);
				end
			-- Envoi SMS
			elseif notif == "sms" and WU.sms then
				if WU.debug_messages then
					Debug("grey", "Send SMS : VD_ID="..(WU.sms["VD_ID"] or 0).." VD_Button="..(WU.sms["VD_Button"] or "0").." VG_Name="..(WU.sms["VG_Name"] or ""));
				end
				fibaro:setGlobal(WU.sms["VG_Name"], message);
				if WU.sms["VD_ID"] and tonumber(WU.sms["VD_ID"])>0 and WU.sms["VD_Button"] and tonumber(WU.sms["VD_Button"])>0 then
					fibaro:call(WU.sms["VD_ID"], "pressButton", WU.sms["VD_Button"]);
				end
			end
		end
	else
		Debug("orange", "Warning : no notification options given");
	end
end
WU.createGlobalIfNotExists = function(varName, defaultValue)
	if (fibaro:getGlobal(varName) == nil) then
		Debug("red", "Global Var: "..varName.." HAS BEEN CREATED");
		newVar = {};
		newVar.name = varName;
		HC2 = Net.FHttp("127.0.0.1", 11111);
		HC2:POST("/api/globalVariables", json.encode(newVar));
	end
end
WU.substPercent = function(doublePercentSymbol)
	if 	WU.GEA then
		doublePercentSymbol = string.gsub(doublePercentSymbol, "%%.", "%%%%");
	end
	return doublePercentSymbol;
end
WU.substSpeech = function(substSpeech)
		substSpeech = string.gsub(substSpeech, "km/h", "kilomètre heure");
		substSpeech = string.gsub(substSpeech, "ºC", "degrés");
  		substSpeech = string.gsub(substSpeech, "°C", "degrés");
		substSpeech = string.gsub(substSpeech, "%(", "de ");
		substSpeech = string.gsub(substSpeech, "%)", "");
		substSpeech = string.gsub(substSpeech, "mm", "milimètres de pluie.");
		substSpeech = string.gsub(substSpeech, " Vents ", " Vents de provenance ");
		substSpeech = string.gsub(substSpeech, "/", " à");
		substSpeech = string.gsub(substSpeech, " N ", " Nord ");
		substSpeech = string.gsub(substSpeech, " S ", " Sud ");
		substSpeech = string.gsub(substSpeech, " E ", " Est ");
		substSpeech = string.gsub(substSpeech, " O ", " Ouest ");
		substSpeech = string.gsub(substSpeech, " NE ", " Nord Est ");
		substSpeech = string.gsub(substSpeech, " NNE ", " Nord Nord Est ");
		substSpeech = string.gsub(substSpeech, " ENE ", " Est Nord Est ");
		substSpeech = string.gsub(substSpeech, " NO ", " Nord Ouest ");
		substSpeech = string.gsub(substSpeech, " NNO ", " Nord Nord Ouest ");
		substSpeech = string.gsub(substSpeech, " ONO ", " Ouest Nord Ouest ");
		substSpeech = string.gsub(substSpeech, " SE ", " Sud Est ");
		substSpeech = string.gsub(substSpeech, " SSE ", " Sud Sud Est ");
		substSpeech = string.gsub(substSpeech, " ESE ", " Est Sud Est ");
		substSpeech = string.gsub(substSpeech, " SO ", " Sud Ouest ");
		substSpeech = string.gsub(substSpeech, " SSO ", " Sud Sud Ouest ");
		substSpeech = string.gsub(substSpeech, " OSO ", " Ouest Sud Ouest ");
	return substSpeech;
end
WU.cleanJson = function(jsontocheck,returnIfTrue)
	if jsontocheck == "-999.00" or jsontocheck == "--" or jsontocheck == json.null then
	jsontocheck = returnIfTrue;
	end
		local ok = pcall(function()
			testConcatenate = "Test Concatenate: " .. jsontocheck; -- test for non concatenate value
			end )
		if (not ok) then
			decode_error = true;
			Debug( "red", "decode raised an error");
			if WU.notifications then
				WU.notification("decode error in WU Meteo","Got a Decode Error in WU Meteo.", WU.notificationTypes);
			end
		end
	return jsontocheck;
end
WU.HtmlColor = function(StringToColor,color)
	if MobileDisplay == false then 
	StringToColor= "<font color=\""..color.."\"> "..StringToColor.."</font>";
	end
	return StringToColor;
end
WU.IconOrText = function(icon,txt)
	if MobileDisplay == false then
	IconOrText = "<img src="..icon.."\>";
	else
	IconOrText = txt;
	end
	return IconOrText;
end
WU.HtmlOrText = function(_html,txt)
	if MobileDisplay == false then 
	HtmlOrText = _html;
	else
	HtmlOrText = txt;
	end
	return HtmlOrText;
end
WU.getSlider = function()
	ValeurSliderfunct = fibaro:getValue(WU.selfId , "ui.WebOrMobile.value");
	return tonumber(ValeurSliderfunct);
end
WU.setSlider = function(position)
	fibaro:call(WU.selfId , "setProperty", "ui.WebOrMobile.value", position);
	return WU.getSlider();
end
WU.checkMobileOrWeb = function()
	ValeurSliderSleep = WU.getSlider(); -- check slider value at first run
	if ValeurSliderSleep <= 50 then 
		if ValeurSliderSleep == 1 then
		MobileDisplay = false;
		else
		MobileDisplay = false;
		WU.runDirect = 1;
		sleepAndcheckslider = 20*WU.updateEvery; -- exit wait loop
		Debug("orange", WU.translation[WU.language]["Exiting_loop_slider"]);
		end
		WU.setSlider(1); -- désactive le run immediat lors du prochain test
	end
	if ValeurSliderSleep >= 50 then
		if ValeurSliderSleep == 98 then
		else
		MobileDisplay = true;
		WU.runDirect = 1;
		sleepAndcheckslider = 20*WU.updateEvery; -- exit wait loop
		Debug("orange", WU.translation[WU.language]["Exiting_loop_slider"]);
		end
		WU.setSlider(98); -- désactive le run immediat lors du prochain test
	end 
  return WU.getSlider();
end
WU.fetchWU = function()
decode_error = false;
WU.checkMobileOrWeb();
local WGROUND = Net.FHttp("api.wunderground.com",80);
local response ,status, err = WGROUND:GET("/api/"..WU.APIkey.."/conditions/forecast/lang:"..WU.language.."/q/"..WU.station..":"..locationID..".json");
--Debug("orange", "api.wunderground.com/api/"..WU.APIkey.."/conditions/forecast/lang:"..WU.language.."/q/"..WU.station..":"..locationID..".json");
if (tonumber(status) == 200 and tonumber(err)==0) then
	Debug( "cyan", WU.translation[WU.language]["Fetched"]);
	if (response ~= nil) then
		WU.now = os.date("%H:%M");
		jsonTable = json.decode(response);
		if jsonTable.response.error ~= nil then
			Debug( "red", WU.translation[WU.language]["NO_DATA_FOUND"]);
			fibaro:sleep(15*1000);
			Debug( "yellow", WU.translation[WU.language]["NO_DATA_FOUND"]);
			fibaro:sleep(15*1000);
		return
		end
		-- current observation
		stationID = jsonTable.current_observation.station_id;
		humidity = jsonTable.current_observation.relative_humidity;
		temperature = jsonTable.current_observation.temp_c;
		pression = jsonTable.current_observation.pressure_mb;
		wind = jsonTable.current_observation.wind_kph;
		rain = WU.cleanJson(jsonTable.current_observation.precip_today_metric,"0");
		weathericon = jsonTable.current_observation.icon_url;
		feelslike_c = jsonTable.current_observation.feelslike_c;
		temperatureWithFeels = temperature.."/"..feelslike_c
		-- Today meteo
		fcstday1 = jsonTable.forecast.txt_forecast.forecastday[1].title;
			fcst1 = jsonTable.forecast.txt_forecast.forecastday[1].fcttext_metric;
			fcst1icon = jsonTable.forecast.txt_forecast.forecastday[1].icon_url;
		-- Today Evening Meteo
		fcstday2 = jsonTable.forecast.txt_forecast.forecastday[2].title;
			fcst2 = jsonTable.forecast.txt_forecast.forecastday[2].fcttext_metric;
			fcst2icon = jsonTable.forecast.txt_forecast.forecastday[2].icon_url;
		-- Tomorrow Morning Meteo
		fcstday3 = jsonTable.forecast.txt_forecast.forecastday[3].title;
			fcst3 = jsonTable.forecast.txt_forecast.forecastday[3].fcttext_metric;
			fcst3icon = jsonTable.forecast.txt_forecast.forecastday[3].icon_url;
		 -- In 2 days Morning Meteo
		fcstday5 = jsonTable.forecast.txt_forecast.forecastday[5].title;
			fcst5 = jsonTable.forecast.txt_forecast.forecastday[5].fcttext_metric;
			fcst5icon = jsonTable.forecast.txt_forecast.forecastday[5].icon_url;

			-- SimpleForecast Today Meteo (Complete day)
			fcst1SmallTxt = jsonTable.forecast.simpleforecast.forecastday[1].conditions;
			fcst1Tmax = jsonTable.forecast.simpleforecast.forecastday[1].high.celsius;
			fcst1Tmin = jsonTable.forecast.simpleforecast.forecastday[1].low.celsius;
			fcst1avewind =jsonTable.forecast.simpleforecast.forecastday[1].avewind.kph;
			fcst1avewinddir =jsonTable.forecast.simpleforecast.forecastday[1].avewind.dir;
			fcst1mmday = WU.cleanJson(jsonTable.forecast.simpleforecast.forecastday[1].qpf_day.mm,"0");
			fcst1mmnight = WU.cleanJson(jsonTable.forecast.simpleforecast.forecastday[1].qpf_night.mm,"0");
			fcst1mm = fcst1mmday.."/"..fcst1mmnight
		-- SimpleForecast Tomorrow Meteo (Complete day)
			fcst2SmallTxt = jsonTable.forecast.simpleforecast.forecastday[2].conditions;
			fcst2Tmax = jsonTable.forecast.simpleforecast.forecastday[2].high.celsius;
			fcst2Tmin = jsonTable.forecast.simpleforecast.forecastday[2].low.celsius;
			fcst2avewind =jsonTable.forecast.simpleforecast.forecastday[2].avewind.kph;
			fcst2avewinddir =jsonTable.forecast.simpleforecast.forecastday[2].avewind.dir;
			fcst2mmday = WU.cleanJson(jsonTable.forecast.simpleforecast.forecastday[2].qpf_day.mm,"0");
			fcst2mmnight = WU.cleanJson(jsonTable.forecast.simpleforecast.forecastday[2].qpf_night.mm,"0");
			fcst2mm = fcst2mmday.."/"..fcst2mmnight
		-- In 2 days Meteo (Complete day)
			fcst3SmallTxt = jsonTable.forecast.simpleforecast.forecastday[3].conditions;
			fcst3Tmax = jsonTable.forecast.simpleforecast.forecastday[3].high.celsius;
			fcst3Tmin = jsonTable.forecast.simpleforecast.forecastday[3].low.celsius;
			fcst3avewind =jsonTable.forecast.simpleforecast.forecastday[3].avewind.kph;
			fcst3avewinddir =jsonTable.forecast.simpleforecast.forecastday[3].avewind.dir;
			fcst3mmday = WU.cleanJson(jsonTable.forecast.simpleforecast.forecastday[3].qpf_day.mm,"0");
			fcst3mmnight = WU.cleanJson(jsonTable.forecast.simpleforecast.forecastday[3].qpf_night.mm,"0");
			fcst3mm = fcst3mmday.."/"..fcst3mmnight


		if (stationID ~= nil) and decode_error == false  then
			fibaro:call(WU.selfId , "setProperty", "ui.lblStation.value", locationID);
			fibaro:call(WU.selfId , "setProperty", "ui.lblTempHum.value", WU.translation[WU.language]["Temperature"]..": "..temperature.."°C | "..humidity.." "..WU.translation[WU.language]["Humidity"]);
			fibaro:call(WU.selfId , "setProperty", "ui.lblWindRain.value", WU.translation[WU.language]["Wind"]..": "..wind.." km/h - "..WU.translation[WU.language]["Rain"]..": "..rain.." mm");
			if (WU.now >= "03:00" and WU.now <= "23:59") then -- donne meteo du jour entre 00:00 (ou 3h) et 15:59. permet de garder la météo du soir jusqu'a 3h du matin, sinon change àminuit
			fibaro:call(WU.selfId , "setProperty", "ui.lblFcst.value", WU.HtmlOrText(
				WU.translation[WU.language]["Forecast"]..fcstday1..": "..fcst1.." ("..fcst1mm.." mm)",
				fcst1Tmax.."°/"..fcst1Tmin.."° | "..fcst1mm.."mm | "..fcst1avewind.."Km/h ("..fcst1avewinddir..")"));
			fibaro:call(WU.selfId , "setProperty", "ui.lblIcon.value",WU.IconOrText(fcst1icon,fcstday1..": "..fcst1SmallTxt));
			local texte = WU.substPercent(WU.translation[WU.language]["Forecast"]..fcstday1..": ".." "..fcst1.." ("..fcst1mm.." mm)");
			fibaro:setGlobal("Meteo_Day", texte);
			local texte = WU.substPercent(WU.translation[WU.language]["Forecast"]..fcstday1..": ".." "..fcst1);
			texte = WU.substSpeech(texte);
			fibaro:setGlobal("Meteo_Day_Speech", texte);
			elseif (WU.now >= "16:00" and WU.now <= "23:59") then  -- donne meteo soirée entre 16:00 et 23:59
			fibaro:call(WU.selfId , "setProperty", "ui.lblFcst.value", WU.HtmlOrText(
				WU.translation[WU.language]["Forecast"]..fcstday2..": "..fcst2.." ("..fcst1mm.." mm)",
				fcst1Tmax.."°/"..fcst1Tmin.."° | "..fcst1mm.."mm | "..fcst1avewind.."Km/h ("..fcst1avewinddir..")"));
			fibaro:call(WU.selfId , "setProperty", "ui.lblIcon.value",WU.IconOrText(fcst2icon,fcstday2..": "..fcst1SmallTxt));
			local texte = WU.substPercent(WU.translation[WU.language]["Forecast"]..fcstday2..": ".." "..fcst2.." ("..fcst1mm.." mm)");
			fibaro:setGlobal("Meteo_Day", texte);
			local texte = WU.substPercent(WU.translation[WU.language]["Forecast"]..fcstday2..": ".." "..fcst2);
			texte = WU.substSpeech(texte);
			fibaro:setGlobal("Meteo_Day_Speech", texte);
			end
			-- Meteo of Tomorrow
			fibaro:call(WU.selfId , "setProperty", "ui.lblFcstTomorrow.value", WU.HtmlOrText(
				WU.translation[WU.language]["Forecast"]..fcstday3..": "..fcst3.." ("..fcst2mm.." mm)",
				fcst2Tmax.."°/"..fcst2Tmin.."° | "..fcst2mm.."mm | "..fcst2avewind.."Km/h ("..fcst2avewinddir..")"));
			fibaro:call(WU.selfId , "setProperty", "ui.lblIconTomorrow.value",WU.IconOrText(fcst3icon,fcstday3..": "..fcst2SmallTxt));
			local texte = WU.substPercent(WU.translation[WU.language]["Forecast"]..fcstday3..": ".." "..fcst3.." ("..fcst2mm.." mm)");
			fibaro:setGlobal("Meteo_Tomorrow", texte);
			local texte = WU.substPercent(WU.translation[WU.language]["Forecast"]..fcstday3..": ".." "..fcst3);
			texte = WU.substSpeech(texte);
			fibaro:setGlobal("Meteo_Tomorrow_Sp", texte);
			-- Meteo in 2 Days
			fibaro:call(WU.selfId , "setProperty", "ui.lblFcst2Days.value", WU.HtmlOrText(
				WU.translation[WU.language]["Forecast"]..fcstday5..": "..fcst5.." ("..fcst3mm.." mm)",
				fcst3Tmax.."°/"..fcst3Tmin.."° | "..fcst3mm.."mm | "..fcst3avewind.."Km/h ("..fcst3avewinddir..")"));
			fibaro:call(WU.selfId , "setProperty", "ui.lblIcon2Days.value",WU.IconOrText(fcst5icon,fcstday5..": "..fcst3SmallTxt));
			local texte = WU.substPercent(WU.translation[WU.language]["Forecast"]..fcstday5..": ".." "..fcst5.." ("..fcst3mm.." mm)");
			fibaro:setGlobal("Meteo_In_2_Days", texte);
			local texte = WU.substPercent(WU.translation[WU.language]["Forecast"]..fcstday5..": ".." "..fcst5);
			texte = WU.substSpeech(texte);
			fibaro:setGlobal("Meteo_In_2_Days_Sp", texte);
			if WU.notifications then
				if (os.date("%H:%M") == WU.push_fcst1) then
					WU.notification(fcstday1.." - "..fcst1.." ("..fcst1mm.." mm)" , WU.translation[WU.language]["EmailSubject"].." "..fcstday1 , WU.notificationTypes); -- Send Morning meteo
				elseif (os.date("%H:%M") == WU.push_fcst2) then
					WU.notification( fcstday2.." - "..fcst2.." ("..fcst2mm.." mm)" , WU.translation[WU.language]["EmailSubject"].." "..fcstday2 , WU.notificationTypes); -- Send evening meteo
				end
			end
			if WU.notifications then
				fibaro:call(WU.selfId , "setProperty", "ui.lblNotify.value", WU.translation[WU.language]["Push_forecast"].."  = true");
			else fibaro:call(WU.selfId , "setProperty", "ui.lblNotify.value",WU.translation[WU.language]["Push_forecast"].."  = false");
			end
			WU.scheduler = os.time()+WU.updateEvery*60;
			fibaro:call(WU.selfId, "setProperty", "ui.lblUpdate.value", WU.translation[WU.language]["Last_updated"]..": "..os.date("%c"));
			Debug( "cyan", WU.translation[WU.language]["Data_processed"]);
			Debug( "white", WU.translation[WU.language]["Update_interval"].." "..WU.updateEvery);
		else
		Debug( "red", WU.translation[WU.language]["NO_STATIONID_FOUND"]);
		end
	else
	fibaro:debug("status:" .. status .. ", errorCode:" .. errorCode);
	end
end
sleepAndcheckslider = 0;
while sleepAndcheckslider <= 20*WU.updateEvery do
	fibaro:sleep(3000);
	WU.checkMobileOrWeb();
	sleepAndcheckslider = sleepAndcheckslider+1;
	if (WU.DoNotRecheckBefore <= os.time()) and ((WU.scheduler == os.time) or (os.date("%H:%M") == WU.push_fcst1) or (os.date("%H:%M") == WU.push_fcst2)) then
		Debug("orange", WU.translation[WU.language]["Exiting_loop_push"]);
		WU.DoNotRecheckBefore = os.time()+60;
		sleepAndcheckslider = 20*WU.updateEvery;
	end
end
end

Debug( "orange", "10/2015 - WU Weather - Original LUA Scripting by Jonny Larsson 2015");
Debug( "orange", "11/2015 - YAMS WU - Fork by Sébastien Jauquet");
Debug( "orange", "Version: "..WU.version);
if WU.station == "LOCID" then
	locationID = WU.LOCID;
elseif
	WU.station == "PWS" then
	locationID = WU.PWS;
end
if WU.CreateVG then
	WU.createGlobalIfNotExists("Meteo_Day", "");
	WU.createGlobalIfNotExists("Meteo_Tomorrow", "");
	WU.createGlobalIfNotExists("Meteo_In_2_Days", "");
	WU.createGlobalIfNotExists("Meteo_Day_Speech", "");
	WU.createGlobalIfNotExists("Meteo_Tomorrow_Sp", "");
	WU.createGlobalIfNotExists("Meteo_In_2_Days_Sp", "");
end
while true do 
	WU.fetchWU();
end

