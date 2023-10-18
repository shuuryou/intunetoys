###############################################################################
# SetOSTimeZone.ps1                                                           #
# PowerShell script for Microsoft Intune to set the time zone of the computer #
# based on the external IP address. This is required for fully automated      #
# Windows Autopilot deployment scenarios, because users will not get a chance #
# to enable location services, which causes the time zone of the computer to  #
# default to Redmond.                                                         #
# Using this script, the time zone is determined using an online service and  #
# set once during the course of deployment. It's not necessary to enable any  #
# location service settings or to make manual registry changes if this script #
# is used.                                                                    #
#                                                                             #
# Log output at %WINDIR%\Temp\Onboarding-SetOSTimeZone.log                    #
#                                                                             #
# https://github.com/shuuryou/intunetoys                                      #
# https://github.com/shuuryou/intunetoys/blob/main/LICENSE                    #
###############################################################################

$API_ENDPOINT = "https://ipapi.co/json"

$API_KEY = "" # If you have one (see <https://ipapi.co/#pricing>; 1000 requests/day are free)


# Please note that the embedded list of time zones was taken from 
# the Unicode CLDR Project (https://github.com/unicode-org/cldr)
# File: cldr/main/common/supplemental/windowsZones.xml
# Copyright © 1991-2013 Unicode, Inc.

$TimeZones = @"
Windows,IANA
Dateline Standard Time,Etc/GMT+12
Dateline Standard Time,Etc/GMT+12
UTC-11,Etc/GMT+11
UTC-11,Pacific/Pago_Pago
UTC-11,Pacific/Niue
UTC-11,Pacific/Midway
UTC-11,Etc/GMT+11
Aleutian Standard Time,America/Adak
Aleutian Standard Time,America/Adak
Hawaiian Standard Time,Pacific/Honolulu
Hawaiian Standard Time,Pacific/Rarotonga
Hawaiian Standard Time,Pacific/Tahiti
Hawaiian Standard Time,Pacific/Johnston
Hawaiian Standard Time,Pacific/Honolulu
Hawaiian Standard Time,Etc/GMT+10
Marquesas Standard Time,Pacific/Marquesas
Marquesas Standard Time,Pacific/Marquesas
Alaskan Standard Time,America/Anchorage
Alaskan Standard Time,America/Anchorage America/Juneau America/Metlakatla America/Nome America/Sitka America/Yakutat
UTC-09,Etc/GMT+9
UTC-09,Pacific/Gambier
UTC-09,Etc/GMT+9
Pacific Standard Time (Mexico),America/Tijuana
Pacific Standard Time (Mexico),America/Tijuana America/Santa_Isabel
UTC-08,Etc/GMT+8
UTC-08,Pacific/Pitcairn
UTC-08,Etc/GMT+8
Pacific Standard Time,America/Los_Angeles
Pacific Standard Time,America/Vancouver
Pacific Standard Time,America/Los_Angeles
Pacific Standard Time,PST8PDT
US Mountain Standard Time,America/Phoenix
US Mountain Standard Time,America/Creston America/Dawson_Creek America/Fort_Nelson
US Mountain Standard Time,America/Hermosillo
US Mountain Standard Time,America/Phoenix
US Mountain Standard Time,Etc/GMT+7
Mountain Standard Time (Mexico),America/Mazatlan
Mountain Standard Time (Mexico),America/Mazatlan
Mountain Standard Time,America/Denver
Mountain Standard Time,America/Edmonton America/Cambridge_Bay America/Inuvik America/Yellowknife
Mountain Standard Time,America/Ciudad_Juarez
Mountain Standard Time,America/Denver America/Boise
Mountain Standard Time,MST7MDT
Yukon Standard Time,America/Whitehorse
Yukon Standard Time,America/Whitehorse America/Dawson
Central America Standard Time,America/Guatemala
Central America Standard Time,America/Belize
Central America Standard Time,America/Costa_Rica
Central America Standard Time,Pacific/Galapagos
Central America Standard Time,America/Guatemala
Central America Standard Time,America/Tegucigalpa
Central America Standard Time,America/Managua
Central America Standard Time,America/El_Salvador
Central America Standard Time,Etc/GMT+6
Central Standard Time,America/Chicago
Central Standard Time,America/Winnipeg America/Rainy_River America/Rankin_Inlet America/Resolute
Central Standard Time,America/Matamoros America/Ojinaga
Central Standard Time,America/Chicago America/Indiana/Knox America/Indiana/Tell_City America/Menominee America/North_Dakota/Beulah America/North_Dakota/Center America/North_Dakota/New_Salem
Central Standard Time,CST6CDT
Easter Island Standard Time,Pacific/Easter
Easter Island Standard Time,Pacific/Easter
Central Standard Time (Mexico),America/Mexico_City
Central Standard Time (Mexico),America/Mexico_City America/Bahia_Banderas America/Merida America/Monterrey America/Chihuahua 
Canada Central Standard Time,America/Regina
Canada Central Standard Time,America/Regina America/Swift_Current
SA Pacific Standard Time,America/Bogota
SA Pacific Standard Time,America/Rio_Branco America/Eirunepe
SA Pacific Standard Time,America/Coral_Harbour
SA Pacific Standard Time,America/Bogota
SA Pacific Standard Time,America/Guayaquil
SA Pacific Standard Time,America/Jamaica
SA Pacific Standard Time,America/Cayman
SA Pacific Standard Time,America/Panama
SA Pacific Standard Time,America/Lima
SA Pacific Standard Time,Etc/GMT+5
Eastern Standard Time (Mexico),America/Cancun
Eastern Standard Time (Mexico),America/Cancun
Eastern Standard Time,America/New_York
Eastern Standard Time,America/Nassau
Eastern Standard Time,America/Toronto America/Iqaluit America/Montreal America/Nipigon America/Pangnirtung America/Thunder_Bay
Eastern Standard Time,America/New_York America/Detroit America/Indiana/Petersburg America/Indiana/Vincennes America/Indiana/Winamac America/Kentucky/Monticello America/Louisville
Eastern Standard Time,EST5EDT
Haiti Standard Time,America/Port-au-Prince
Haiti Standard Time,America/Port-au-Prince
Cuba Standard Time,America/Havana
Cuba Standard Time,America/Havana
US Eastern Standard Time,America/Indianapolis
US Eastern Standard Time,America/Indianapolis America/Indiana/Marengo America/Indiana/Vevay
Turks And Caicos Standard Time,America/Grand_Turk
Turks And Caicos Standard Time,America/Grand_Turk
Paraguay Standard Time,America/Asuncion
Paraguay Standard Time,America/Asuncion
Atlantic Standard Time,America/Halifax
Atlantic Standard Time,Atlantic/Bermuda
Atlantic Standard Time,America/Halifax America/Glace_Bay America/Goose_Bay America/Moncton
Atlantic Standard Time,America/Thule
Venezuela Standard Time,America/Caracas
Venezuela Standard Time,America/Caracas
Central Brazilian Standard Time,America/Cuiaba
Central Brazilian Standard Time,America/Cuiaba America/Campo_Grande
SA Western Standard Time,America/La_Paz
SA Western Standard Time,America/Antigua
SA Western Standard Time,America/Anguilla
SA Western Standard Time,America/Aruba
SA Western Standard Time,America/Barbados
SA Western Standard Time,America/St_Barthelemy
SA Western Standard Time,America/La_Paz
SA Western Standard Time,America/Kralendijk
SA Western Standard Time,America/Manaus America/Boa_Vista America/Porto_Velho
SA Western Standard Time,America/Blanc-Sablon
SA Western Standard Time,America/Curacao
SA Western Standard Time,America/Dominica
SA Western Standard Time,America/Santo_Domingo
SA Western Standard Time,America/Grenada
SA Western Standard Time,America/Guadeloupe
SA Western Standard Time,America/Guyana
SA Western Standard Time,America/St_Kitts
SA Western Standard Time,America/St_Lucia
SA Western Standard Time,America/Marigot
SA Western Standard Time,America/Martinique
SA Western Standard Time,America/Montserrat
SA Western Standard Time,America/Puerto_Rico
SA Western Standard Time,America/Lower_Princes
SA Western Standard Time,America/Port_of_Spain
SA Western Standard Time,America/St_Vincent
SA Western Standard Time,America/Tortola
SA Western Standard Time,America/St_Thomas
SA Western Standard Time,Etc/GMT+4
Pacific SA Standard Time,America/Santiago
Pacific SA Standard Time,America/Santiago
Newfoundland Standard Time,America/St_Johns
Newfoundland Standard Time,America/St_Johns
Tocantins Standard Time,America/Araguaina
Tocantins Standard Time,America/Araguaina
E. South America Standard Time,America/Sao_Paulo
E. South America Standard Time,America/Sao_Paulo
SA Eastern Standard Time,America/Cayenne
SA Eastern Standard Time,Antarctica/Rothera Antarctica/Palmer
SA Eastern Standard Time,America/Fortaleza America/Belem America/Maceio America/Recife America/Santarem
SA Eastern Standard Time,Atlantic/Stanley
SA Eastern Standard Time,America/Cayenne
SA Eastern Standard Time,America/Paramaribo
SA Eastern Standard Time,Etc/GMT+3
Argentina Standard Time,America/Buenos_Aires
Argentina Standard Time,America/Buenos_Aires America/Argentina/La_Rioja America/Argentina/Rio_Gallegos America/Argentina/Salta America/Argentina/San_Juan America/Argentina/San_Luis America/Argentina/Tucuman America/Argentina/Ushuaia America/Catamarca America/Cordoba America/Jujuy America/Mendoza
Greenland Standard Time,America/Godthab
Greenland Standard Time,America/Godthab
Montevideo Standard Time,America/Montevideo
Montevideo Standard Time,America/Montevideo
Magallanes Standard Time,America/Punta_Arenas
Magallanes Standard Time,America/Punta_Arenas
Saint Pierre Standard Time,America/Miquelon
Saint Pierre Standard Time,America/Miquelon
Bahia Standard Time,America/Bahia
Bahia Standard Time,America/Bahia
UTC-02,Etc/GMT+2
UTC-02,America/Noronha
UTC-02,Atlantic/South_Georgia
UTC-02,Etc/GMT+2
Azores Standard Time,Atlantic/Azores
Azores Standard Time,America/Scoresbysund
Azores Standard Time,Atlantic/Azores
Cape Verde Standard Time,Atlantic/Cape_Verde
Cape Verde Standard Time,Atlantic/Cape_Verde
Cape Verde Standard Time,Etc/GMT+1
UTC,Etc/UTC
UTC,Etc/UTC Etc/GMT
GMT Standard Time,Europe/London
GMT Standard Time,Atlantic/Canary
GMT Standard Time,Atlantic/Faeroe
GMT Standard Time,Europe/London
GMT Standard Time,Europe/Guernsey
GMT Standard Time,Europe/Dublin
GMT Standard Time,Europe/Isle_of_Man
GMT Standard Time,Europe/Jersey
GMT Standard Time,Europe/Lisbon Atlantic/Madeira
Greenwich Standard Time,Atlantic/Reykjavik
Greenwich Standard Time,Africa/Ouagadougou
Greenwich Standard Time,Africa/Abidjan
Greenwich Standard Time,Africa/Accra
Greenwich Standard Time,America/Danmarkshavn
Greenwich Standard Time,Africa/Banjul
Greenwich Standard Time,Africa/Conakry
Greenwich Standard Time,Africa/Bissau
Greenwich Standard Time,Atlantic/Reykjavik
Greenwich Standard Time,Africa/Monrovia
Greenwich Standard Time,Africa/Bamako
Greenwich Standard Time,Africa/Nouakchott
Greenwich Standard Time,Atlantic/St_Helena
Greenwich Standard Time,Africa/Freetown
Greenwich Standard Time,Africa/Dakar
Greenwich Standard Time,Africa/Lome
Sao Tome Standard Time,Africa/Sao_Tome
Sao Tome Standard Time,Africa/Sao_Tome
Morocco Standard Time,Africa/Casablanca
Morocco Standard Time,Africa/El_Aaiun
Morocco Standard Time,Africa/Casablanca
W. Europe Standard Time,Europe/Berlin
W. Europe Standard Time,Europe/Andorra
W. Europe Standard Time,Europe/Vienna
W. Europe Standard Time,Europe/Zurich
W. Europe Standard Time,Europe/Berlin Europe/Busingen
W. Europe Standard Time,Europe/Gibraltar
W. Europe Standard Time,Europe/Rome
W. Europe Standard Time,Europe/Vaduz
W. Europe Standard Time,Europe/Luxembourg
W. Europe Standard Time,Europe/Monaco
W. Europe Standard Time,Europe/Malta
W. Europe Standard Time,Europe/Amsterdam
W. Europe Standard Time,Europe/Oslo
W. Europe Standard Time,Europe/Stockholm
W. Europe Standard Time,Arctic/Longyearbyen
W. Europe Standard Time,Europe/San_Marino
W. Europe Standard Time,Europe/Vatican
Central Europe Standard Time,Europe/Budapest
Central Europe Standard Time,Europe/Tirane
Central Europe Standard Time,Europe/Prague
Central Europe Standard Time,Europe/Budapest
Central Europe Standard Time,Europe/Podgorica
Central Europe Standard Time,Europe/Belgrade
Central Europe Standard Time,Europe/Ljubljana
Central Europe Standard Time,Europe/Bratislava
Romance Standard Time,Europe/Paris
Romance Standard Time,Europe/Brussels
Romance Standard Time,Europe/Copenhagen
Romance Standard Time,Europe/Madrid Africa/Ceuta
Romance Standard Time,Europe/Paris
Central European Standard Time,Europe/Warsaw
Central European Standard Time,Europe/Sarajevo
Central European Standard Time,Europe/Zagreb
Central European Standard Time,Europe/Skopje
Central European Standard Time,Europe/Warsaw
W. Central Africa Standard Time,Africa/Lagos
W. Central Africa Standard Time,Africa/Luanda
W. Central Africa Standard Time,Africa/Porto-Novo
W. Central Africa Standard Time,Africa/Kinshasa
W. Central Africa Standard Time,Africa/Bangui
W. Central Africa Standard Time,Africa/Brazzaville
W. Central Africa Standard Time,Africa/Douala
W. Central Africa Standard Time,Africa/Algiers
W. Central Africa Standard Time,Africa/Libreville
W. Central Africa Standard Time,Africa/Malabo
W. Central Africa Standard Time,Africa/Niamey
W. Central Africa Standard Time,Africa/Lagos
W. Central Africa Standard Time,Africa/Ndjamena
W. Central Africa Standard Time,Africa/Tunis
W. Central Africa Standard Time,Etc/GMT-1
Jordan Standard Time,Asia/Amman
Jordan Standard Time,Asia/Amman
GTB Standard Time,Europe/Bucharest
GTB Standard Time,Asia/Nicosia Asia/Famagusta
GTB Standard Time,Europe/Athens
GTB Standard Time,Europe/Bucharest
Middle East Standard Time,Asia/Beirut
Middle East Standard Time,Asia/Beirut
Egypt Standard Time,Africa/Cairo
Egypt Standard Time,Africa/Cairo
E. Europe Standard Time,Europe/Chisinau
E. Europe Standard Time,Europe/Chisinau
Syria Standard Time,Asia/Damascus
Syria Standard Time,Asia/Damascus
West Bank Standard Time,Asia/Hebron
West Bank Standard Time,Asia/Hebron Asia/Gaza
South Africa Standard Time,Africa/Johannesburg
South Africa Standard Time,Africa/Bujumbura
South Africa Standard Time,Africa/Gaborone
South Africa Standard Time,Africa/Lubumbashi
South Africa Standard Time,Africa/Maseru
South Africa Standard Time,Africa/Blantyre
South Africa Standard Time,Africa/Maputo
South Africa Standard Time,Africa/Kigali
South Africa Standard Time,Africa/Mbabane
South Africa Standard Time,Africa/Johannesburg
South Africa Standard Time,Africa/Lusaka
South Africa Standard Time,Africa/Harare
South Africa Standard Time,Etc/GMT-2
FLE Standard Time,Europe/Kiev
FLE Standard Time,Europe/Mariehamn
FLE Standard Time,Europe/Sofia
FLE Standard Time,Europe/Tallinn
FLE Standard Time,Europe/Helsinki
FLE Standard Time,Europe/Vilnius
FLE Standard Time,Europe/Riga
FLE Standard Time,Europe/Kiev Europe/Uzhgorod Europe/Zaporozhye
Israel Standard Time,Asia/Jerusalem
Israel Standard Time,Asia/Jerusalem
South Sudan Standard Time,Africa/Juba
South Sudan Standard Time,Africa/Juba
Kaliningrad Standard Time,Europe/Kaliningrad
Kaliningrad Standard Time,Europe/Kaliningrad
Sudan Standard Time,Africa/Khartoum
Sudan Standard Time,Africa/Khartoum
Libya Standard Time,Africa/Tripoli
Libya Standard Time,Africa/Tripoli
Namibia Standard Time,Africa/Windhoek
Namibia Standard Time,Africa/Windhoek
Arabic Standard Time,Asia/Baghdad
Arabic Standard Time,Asia/Baghdad
Turkey Standard Time,Europe/Istanbul
Turkey Standard Time,Europe/Istanbul
Arab Standard Time,Asia/Riyadh
Arab Standard Time,Asia/Bahrain
Arab Standard Time,Asia/Kuwait
Arab Standard Time,Asia/Qatar
Arab Standard Time,Asia/Riyadh
Arab Standard Time,Asia/Aden
Belarus Standard Time,Europe/Minsk
Belarus Standard Time,Europe/Minsk
Russian Standard Time,Europe/Moscow
Russian Standard Time,Europe/Moscow Europe/Kirov
Russian Standard Time,Europe/Simferopol
E. Africa Standard Time,Africa/Nairobi
E. Africa Standard Time,Antarctica/Syowa
E. Africa Standard Time,Africa/Djibouti
E. Africa Standard Time,Africa/Asmera
E. Africa Standard Time,Africa/Addis_Ababa
E. Africa Standard Time,Africa/Nairobi
E. Africa Standard Time,Indian/Comoro
E. Africa Standard Time,Indian/Antananarivo
E. Africa Standard Time,Africa/Mogadishu
E. Africa Standard Time,Africa/Dar_es_Salaam
E. Africa Standard Time,Africa/Kampala
E. Africa Standard Time,Indian/Mayotte
E. Africa Standard Time,Etc/GMT-3
Iran Standard Time,Asia/Tehran
Iran Standard Time,Asia/Tehran
Arabian Standard Time,Asia/Dubai
Arabian Standard Time,Asia/Dubai
Arabian Standard Time,Asia/Muscat
Arabian Standard Time,Etc/GMT-4
Astrakhan Standard Time,Europe/Astrakhan
Astrakhan Standard Time,Europe/Astrakhan Europe/Ulyanovsk
Azerbaijan Standard Time,Asia/Baku
Azerbaijan Standard Time,Asia/Baku
Russia Time Zone 3,Europe/Samara
Russia Time Zone 3,Europe/Samara
Mauritius Standard Time,Indian/Mauritius
Mauritius Standard Time,Indian/Mauritius
Mauritius Standard Time,Indian/Reunion
Mauritius Standard Time,Indian/Mahe
Saratov Standard Time,Europe/Saratov
Saratov Standard Time,Europe/Saratov
Georgian Standard Time,Asia/Tbilisi
Georgian Standard Time,Asia/Tbilisi
Volgograd Standard Time,Europe/Volgograd
Volgograd Standard Time,Europe/Volgograd
Caucasus Standard Time,Asia/Yerevan
Caucasus Standard Time,Asia/Yerevan
Afghanistan Standard Time,Asia/Kabul
Afghanistan Standard Time,Asia/Kabul
West Asia Standard Time,Asia/Tashkent
West Asia Standard Time,Antarctica/Mawson
West Asia Standard Time,Asia/Oral Asia/Aqtau Asia/Aqtobe Asia/Atyrau
West Asia Standard Time,Indian/Maldives
West Asia Standard Time,Indian/Kerguelen
West Asia Standard Time,Asia/Dushanbe
West Asia Standard Time,Asia/Ashgabat
West Asia Standard Time,Asia/Tashkent Asia/Samarkand
West Asia Standard Time,Etc/GMT-5
Ekaterinburg Standard Time,Asia/Yekaterinburg
Ekaterinburg Standard Time,Asia/Yekaterinburg
Pakistan Standard Time,Asia/Karachi
Pakistan Standard Time,Asia/Karachi
Qyzylorda Standard Time,Asia/Qyzylorda
Qyzylorda Standard Time,Asia/Qyzylorda
India Standard Time,Asia/Calcutta
India Standard Time,Asia/Calcutta
Sri Lanka Standard Time,Asia/Colombo
Sri Lanka Standard Time,Asia/Colombo
Nepal Standard Time,Asia/Katmandu
Nepal Standard Time,Asia/Katmandu
Central Asia Standard Time,Asia/Almaty
Central Asia Standard Time,Antarctica/Vostok
Central Asia Standard Time,Asia/Urumqi
Central Asia Standard Time,Indian/Chagos
Central Asia Standard Time,Asia/Bishkek
Central Asia Standard Time,Asia/Almaty Asia/Qostanay
Central Asia Standard Time,Etc/GMT-6
Bangladesh Standard Time,Asia/Dhaka
Bangladesh Standard Time,Asia/Dhaka
Bangladesh Standard Time,Asia/Thimphu
Omsk Standard Time,Asia/Omsk
Omsk Standard Time,Asia/Omsk
Myanmar Standard Time,Asia/Rangoon
Myanmar Standard Time,Indian/Cocos
Myanmar Standard Time,Asia/Rangoon
SE Asia Standard Time,Asia/Bangkok
SE Asia Standard Time,Antarctica/Davis
SE Asia Standard Time,Indian/Christmas
SE Asia Standard Time,Asia/Jakarta Asia/Pontianak
SE Asia Standard Time,Asia/Phnom_Penh
SE Asia Standard Time,Asia/Vientiane
SE Asia Standard Time,Asia/Bangkok
SE Asia Standard Time,Asia/Saigon
SE Asia Standard Time,Etc/GMT-7
Altai Standard Time,Asia/Barnaul
Altai Standard Time,Asia/Barnaul
W. Mongolia Standard Time,Asia/Hovd
W. Mongolia Standard Time,Asia/Hovd
North Asia Standard Time,Asia/Krasnoyarsk
North Asia Standard Time,Asia/Krasnoyarsk Asia/Novokuznetsk
N. Central Asia Standard Time,Asia/Novosibirsk
N. Central Asia Standard Time,Asia/Novosibirsk
Tomsk Standard Time,Asia/Tomsk
Tomsk Standard Time,Asia/Tomsk
China Standard Time,Asia/Shanghai
China Standard Time,Asia/Shanghai
China Standard Time,Asia/Hong_Kong
China Standard Time,Asia/Macau
North Asia East Standard Time,Asia/Irkutsk
North Asia East Standard Time,Asia/Irkutsk
Singapore Standard Time,Asia/Singapore
Singapore Standard Time,Asia/Brunei
Singapore Standard Time,Asia/Makassar
Singapore Standard Time,Asia/Kuala_Lumpur Asia/Kuching
Singapore Standard Time,Asia/Manila
Singapore Standard Time,Asia/Singapore
Singapore Standard Time,Etc/GMT-8
W. Australia Standard Time,Australia/Perth
W. Australia Standard Time,Australia/Perth
Taipei Standard Time,Asia/Taipei
Taipei Standard Time,Asia/Taipei
Ulaanbaatar Standard Time,Asia/Ulaanbaatar
Ulaanbaatar Standard Time,Asia/Ulaanbaatar Asia/Choibalsan
Aus Central W. Standard Time,Australia/Eucla
Aus Central W. Standard Time,Australia/Eucla
Transbaikal Standard Time,Asia/Chita
Transbaikal Standard Time,Asia/Chita
Tokyo Standard Time,Asia/Tokyo
Tokyo Standard Time,Asia/Jayapura
Tokyo Standard Time,Asia/Tokyo
Tokyo Standard Time,Pacific/Palau
Tokyo Standard Time,Asia/Dili
Tokyo Standard Time,Etc/GMT-9
North Korea Standard Time,Asia/Pyongyang
North Korea Standard Time,Asia/Pyongyang
Korea Standard Time,Asia/Seoul
Korea Standard Time,Asia/Seoul
Yakutsk Standard Time,Asia/Yakutsk
Yakutsk Standard Time,Asia/Yakutsk Asia/Khandyga
Cen. Australia Standard Time,Australia/Adelaide
Cen. Australia Standard Time,Australia/Adelaide Australia/Broken_Hill
AUS Central Standard Time,Australia/Darwin
AUS Central Standard Time,Australia/Darwin
E. Australia Standard Time,Australia/Brisbane
E. Australia Standard Time,Australia/Brisbane Australia/Lindeman
AUS Eastern Standard Time,Australia/Sydney
AUS Eastern Standard Time,Australia/Sydney Australia/Melbourne
West Pacific Standard Time,Pacific/Port_Moresby
West Pacific Standard Time,Antarctica/DumontDUrville
West Pacific Standard Time,Pacific/Truk
West Pacific Standard Time,Pacific/Guam
West Pacific Standard Time,Pacific/Saipan
West Pacific Standard Time,Pacific/Port_Moresby
West Pacific Standard Time,Etc/GMT-10
Tasmania Standard Time,Australia/Hobart
Tasmania Standard Time,Australia/Hobart Australia/Currie Antarctica/Macquarie
Vladivostok Standard Time,Asia/Vladivostok
Vladivostok Standard Time,Asia/Vladivostok Asia/Ust-Nera
Lord Howe Standard Time,Australia/Lord_Howe
Lord Howe Standard Time,Australia/Lord_Howe
Bougainville Standard Time,Pacific/Bougainville
Bougainville Standard Time,Pacific/Bougainville
Russia Time Zone 10,Asia/Srednekolymsk
Russia Time Zone 10,Asia/Srednekolymsk
Magadan Standard Time,Asia/Magadan
Magadan Standard Time,Asia/Magadan
Norfolk Standard Time,Pacific/Norfolk
Norfolk Standard Time,Pacific/Norfolk
Sakhalin Standard Time,Asia/Sakhalin
Sakhalin Standard Time,Asia/Sakhalin
Central Pacific Standard Time,Pacific/Guadalcanal
Central Pacific Standard Time,Antarctica/Casey
Central Pacific Standard Time,Pacific/Ponape Pacific/Kosrae
Central Pacific Standard Time,Pacific/Noumea
Central Pacific Standard Time,Pacific/Guadalcanal
Central Pacific Standard Time,Pacific/Efate
Central Pacific Standard Time,Etc/GMT-11
Russia Time Zone 11,Asia/Kamchatka
Russia Time Zone 11,Asia/Kamchatka Asia/Anadyr
New Zealand Standard Time,Pacific/Auckland
New Zealand Standard Time,Antarctica/McMurdo
New Zealand Standard Time,Pacific/Auckland
UTC+12,Etc/GMT-12
UTC+12,Pacific/Tarawa
UTC+12,Pacific/Majuro Pacific/Kwajalein
UTC+12,Pacific/Nauru
UTC+12,Pacific/Funafuti
UTC+12,Pacific/Wake
UTC+12,Pacific/Wallis
UTC+12,Etc/GMT-12
Fiji Standard Time,Pacific/Fiji
Fiji Standard Time,Pacific/Fiji
Chatham Islands Standard Time,Pacific/Chatham
Chatham Islands Standard Time,Pacific/Chatham
UTC+13,Etc/GMT-13
UTC+13,Pacific/Enderbury
UTC+13,Pacific/Fakaofo
UTC+13,Etc/GMT-13
Tonga Standard Time,Pacific/Tongatapu
Tonga Standard Time,Pacific/Tongatapu
Samoa Standard Time,Pacific/Apia
Samoa Standard Time,Pacific/Apia
Line Islands Standard Time,Pacific/Kiritimati
Line Islands Standard Time,Pacific/Kiritimati
Line Islands Standard Time,Etc/GMT-14
"@ | ConvertFrom-Csv -Delim ','

###############################################################################

Start-Transcript -Path $env:windir\Temp\Onboarding-SetOSTimeZone.log

Write-Output("Attempting to query IP API ""{0}"" for time zone information..." -f $API_ENDPOINT)

try
{
    if ($API_KEY -ne "")
    {
        $API_ENDPOINT = $API_ENDPOINT + "?key=$API_KEY"
    }

	$ipinfo = Invoke-RestMethod -Method Get -Uri $API_ENDPOINT
}
catch
{
	Write-Error("Unable to pull geographic information from IP API: {0}" -f, $_)
	Exit 1
}

if ($ipinfo.timezone.ToUpper() -eq 'UNKNOWN')
{
	Write-Error("IP API request successful, but the API was not able to determine the IANA time zone.")
	Write-Error("API response was: {0}" -f $ipinfo)
	Exit 2
}

Write-Output("IP API request successful. IANA time zone for ""{0}"" is ""{1}""." -f $ipinfo.ip, $ipinfo.timezone) 


Write-Output("Trying to match IANA time zone with a Windows time zone.")

$MatchedZone = ""

foreach ($Zone in $TimeZones)
{
	if ($Zone.IANA.ToUpper().Contains($ipinfo.timezone.ToUpper()))
	{ 
		$MatchedZone = $zone.Windows
		break
	}
}

if ($MatchedZone -eq "")
{
	Write-Error("Unable to match IANA time zone ""{0}"" with a Windows time zone." -f $ipinfo.timezone)
	Exit 3
}

Write-Output("Matched IANA time zone ""{0}"" with Windows time zone: ""{1}""" -f $ipinfo.timezone, $MatchedZone)		


Write-Output("Now attempting to set Windows time zone.")

try
{
	Set-TimeZone($MatchedZone)
}
catch 
{
	Write-Error("Failed to set Windows time zone: {0}" -f $_)
	Exit 4
}

Write-Output("Set Windows time zone successfully. Everything went well.")

Exit 0
