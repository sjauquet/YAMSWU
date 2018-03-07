# YAMSWU
# -------------------------------------------------------------------------------------------
# -- WU WeatherData - Fetch weather data from wunderground.com. Multilanguage support!
# -- Original Code by Jonny Larsson 2015 http://forum.fibaro.com/index.php?/topic/19810-wu-weatherdata-version-202-2015-10-25/
# -- Forked by Sébastien Jauquet 11/2015 http://www.domotique-fibaro.fr/index.php/topic/6446-yams-wu-yet-another-meteo-station-wunderground-version/
# -- Inspired by GEA(steven), stevenvd, Lazer, Krikroff and many other users.
# -- Source - forum.fibaro.com, domotique-fibaro.fr and worldwideweb
# 
# -- 2014-03-22 - Permissions granted from Krikroff 
# -- 2014-03-23 - Added rain and forecast, Added FR language. 
# -- 2014-03-23 - Language variable changed to get the translation from wunderground.com in forcast
# -- 2014-03-24 - Added PL language
# -- 2014-03-24 - Select between PWS or LOCID to download weather data
# -- 2015-10-23 - New source code.
# -- 2015-11-16 - Permissions granted from Jonny Larsson
# 
# -- 2015-11-13 - V3.0 - Fork Code by Sebastien Jauquet (3 days forecast, rain in mm)
# -- 2015-11-14 - V3.1 - Compatibilty with GEA, French translation
# -- 2015-11-14 - V3.2 - Catch rain errors (-999mm null empty etc.)
# -- 2015-11-14 - V3.3 - Catch json decode error (was stopping main loop) with pcall (can be extended to other jdon datas if needed)
# -- 2015-11-16 - V3.4 - Generate HTML and non HTML version (for compatibility with mobiles)
# -- 2015-11-18 - V3.5 - Fixed bug not updating Meteo_Day becaus WU.now was only updated at first launch
# -- 2015-11-18 - V3.6 - Merged some changes from jompa new version
# -- 2015-11-18 - 		Added autmatic creation of Global Variables if not existing
# -- 2015-11-19 - V3.7 - Modify schedule management and CleanUp code
# -- 2015-11-22 - V3.8 - Finalise mobile version and bug fixing
# -- 2015-11-23 - V3.9 - Added multiple notification options (Lazer way)
# -- 2015-11-30 - V4.0 - More precision for rain mm (moring/evening) + added feels like T° + optimized display
# -- 2016-07-11 - V4.1 - Added Speech VG, with subst of symbols of day, tomorrow and Day+2 to be more speech compatible (in french only, sorry)
# -- Look for nearest station here: http://www.wunderground.com
# -- 2016-10-01 - V4.2 - Removed HTML tags
# -- 2018-03-07 - V4.3 - Mod création des VG si elles n'existent pas. (non testé, code from: https://www.domotique-fibaro.fr/topic/6446-yams-wu-yet-another-meteo-station-wunderground-version/?do=findComment&comment=169513
