require 'tzinfo/timezone_definition'

module TZInfo
  module Definitions
    module America
      module Sao_Paulo
        include TimezoneDefinition
        
        timezone 'America/Sao_Paulo' do |tz|
          tz.offset :o0, -11188, 0, :LMT
          tz.offset :o1, -10800, 0, :BRT
          tz.offset :o2, -10800, 3600, :BRST
          
          tz.transition 1914, 1, :o1, 52274886397, 21600
          tz.transition 1931, 10, :o2, 29119417, 12
          tz.transition 1932, 4, :o1, 29121583, 12
          tz.transition 1932, 10, :o2, 19415869, 8
          tz.transition 1933, 4, :o1, 29125963, 12
          tz.transition 1949, 12, :o2, 19466013, 8
          tz.transition 1950, 4, :o1, 19467101, 8
          tz.transition 1950, 12, :o2, 19468933, 8
          tz.transition 1951, 4, :o1, 29204851, 12
          tz.transition 1951, 12, :o2, 19471853, 8
          tz.transition 1952, 4, :o1, 29209243, 12
          tz.transition 1952, 12, :o2, 19474781, 8
          tz.transition 1953, 3, :o1, 29213251, 12
          tz.transition 1963, 10, :o2, 19506605, 8
          tz.transition 1964, 3, :o1, 29261467, 12
          tz.transition 1965, 1, :o2, 19510333, 8
          tz.transition 1965, 3, :o1, 29266207, 12
          tz.transition 1965, 12, :o2, 19512765, 8
          tz.transition 1966, 3, :o1, 29270227, 12
          tz.transition 1966, 11, :o2, 19515445, 8
          tz.transition 1967, 3, :o1, 29274607, 12
          tz.transition 1967, 11, :o2, 19518365, 8
          tz.transition 1968, 3, :o1, 29278999, 12
          tz.transition 1985, 11, :o2, 499748400
          tz.transition 1986, 3, :o1, 511236000
          tz.transition 1986, 10, :o2, 530593200
          tz.transition 1987, 2, :o1, 540266400
          tz.transition 1987, 10, :o2, 562129200
          tz.transition 1988, 2, :o1, 571197600
          tz.transition 1988, 10, :o2, 592974000
          tz.transition 1989, 1, :o1, 602042400
          tz.transition 1989, 10, :o2, 624423600
          tz.transition 1990, 2, :o1, 634701600
          tz.transition 1990, 10, :o2, 656478000
          tz.transition 1991, 2, :o1, 666756000
          tz.transition 1991, 10, :o2, 687927600
          tz.transition 1992, 2, :o1, 697600800
          tz.transition 1992, 10, :o2, 719982000
          tz.transition 1993, 1, :o1, 728445600
          tz.transition 1993, 10, :o2, 750826800
          tz.transition 1994, 2, :o1, 761709600
          tz.transition 1994, 10, :o2, 782276400
          tz.transition 1995, 2, :o1, 793159200
          tz.transition 1995, 10, :o2, 813726000
          tz.transition 1996, 2, :o1, 824004000
          tz.transition 1996, 10, :o2, 844570800
          tz.transition 1997, 2, :o1, 856058400
          tz.transition 1997, 10, :o2, 876106800
          tz.transition 1998, 3, :o1, 888717600
          tz.transition 1998, 10, :o2, 908074800
          tz.transition 1999, 2, :o1, 919562400
          tz.transition 1999, 10, :o2, 938919600
          tz.transition 2000, 2, :o1, 951616800
          tz.transition 2000, 10, :o2, 970974000
          tz.transition 2001, 2, :o1, 982461600
          tz.transition 2001, 10, :o2, 1003028400
          tz.transition 2002, 2, :o1, 1013911200
          tz.transition 2002, 11, :o2, 1036292400
          tz.transition 2003, 2, :o1, 1045360800
          tz.transition 2003, 10, :o2, 1066532400
          tz.transition 2004, 2, :o1, 1076810400
          tz.transition 2004, 11, :o2, 1099364400
          tz.transition 2005, 2, :o1, 1108864800
          tz.transition 2005, 10, :o2, 1129431600
          tz.transition 2006, 2, :o1, 1140314400
          tz.transition 2006, 11, :o2, 1162695600
          tz.transition 2007, 2, :o1, 1172368800
          tz.transition 2007, 11, :o2, 1194145200
          tz.transition 2008, 2, :o1, 1203818400
          tz.transition 2008, 11, :o2, 1225594800
          tz.transition 2009, 2, :o1, 1235268000
          tz.transition 2009, 11, :o2, 1257044400
          tz.transition 2010, 2, :o1, 1267322400
          tz.transition 2010, 11, :o2, 1289098800
          tz.transition 2011, 2, :o1, 1298772000
          tz.transition 2011, 11, :o2, 1320548400
          tz.transition 2012, 2, :o1, 1330221600
          tz.transition 2012, 11, :o2, 1351998000
          tz.transition 2013, 2, :o1, 1361671200
          tz.transition 2013, 11, :o2, 1383447600
          tz.transition 2014, 2, :o1, 1393120800
          tz.transition 2014, 11, :o2, 1414897200
          tz.transition 2015, 2, :o1, 1424570400
          tz.transition 2015, 11, :o2, 1446346800
          tz.transition 2016, 2, :o1, 1456624800
          tz.transition 2016, 11, :o2, 1478401200
          tz.transition 2017, 2, :o1, 1488074400
          tz.transition 2017, 11, :o2, 1509850800
          tz.transition 2018, 2, :o1, 1519524000
          tz.transition 2018, 11, :o2, 1541300400
          tz.transition 2019, 2, :o1, 1550973600
          tz.transition 2019, 11, :o2, 1572750000
          tz.transition 2020, 2, :o1, 1582423200
          tz.transition 2020, 11, :o2, 1604199600
          tz.transition 2021, 2, :o1, 1614477600
          tz.transition 2021, 11, :o2, 1636254000
          tz.transition 2022, 2, :o1, 1645927200
          tz.transition 2022, 11, :o2, 1667703600
          tz.transition 2023, 2, :o1, 1677376800
          tz.transition 2023, 11, :o2, 1699153200
          tz.transition 2024, 2, :o1, 1708826400
          tz.transition 2024, 11, :o2, 1730602800
          tz.transition 2025, 2, :o1, 1740276000
          tz.transition 2025, 11, :o2, 1762052400
          tz.transition 2026, 2, :o1, 1771725600
          tz.transition 2026, 11, :o2, 1793502000
          tz.transition 2027, 2, :o1, 1803780000
          tz.transition 2027, 11, :o2, 1825556400
          tz.transition 2028, 2, :o1, 1835229600
          tz.transition 2028, 11, :o2, 1857006000
          tz.transition 2029, 2, :o1, 1866679200
          tz.transition 2029, 11, :o2, 1888455600
          tz.transition 2030, 2, :o1, 1898128800
          tz.transition 2030, 11, :o2, 1919905200
          tz.transition 2031, 2, :o1, 1929578400
          tz.transition 2031, 11, :o2, 1951354800
          tz.transition 2032, 2, :o1, 1961632800
          tz.transition 2032, 11, :o2, 1983409200
          tz.transition 2033, 2, :o1, 1993082400
          tz.transition 2033, 11, :o2, 2014858800
          tz.transition 2034, 2, :o1, 2024532000
          tz.transition 2034, 11, :o2, 2046308400
          tz.transition 2035, 2, :o1, 2055981600
          tz.transition 2035, 11, :o2, 2077758000
          tz.transition 2036, 2, :o1, 2087431200
          tz.transition 2036, 11, :o2, 2109207600
          tz.transition 2037, 2, :o1, 2118880800
          tz.transition 2037, 11, :o2, 2140657200
          tz.transition 2038, 2, :o1, 29585791, 12
          tz.transition 2038, 11, :o2, 19725877, 8
          tz.transition 2039, 2, :o1, 29590159, 12
          tz.transition 2039, 11, :o2, 19728789, 8
          tz.transition 2040, 2, :o1, 29594527, 12
          tz.transition 2040, 11, :o2, 19731701, 8
          tz.transition 2041, 2, :o1, 29598895, 12
          tz.transition 2041, 11, :o2, 19734613, 8
          tz.transition 2042, 2, :o1, 29603263, 12
          tz.transition 2042, 11, :o2, 19737525, 8
          tz.transition 2043, 2, :o1, 29607631, 12
          tz.transition 2043, 11, :o2, 19740437, 8
          tz.transition 2044, 2, :o1, 29612083, 12
          tz.transition 2044, 11, :o2, 19743405, 8
          tz.transition 2045, 2, :o1, 29616451, 12
          tz.transition 2045, 11, :o2, 19746317, 8
          tz.transition 2046, 2, :o1, 29620819, 12
          tz.transition 2046, 11, :o2, 19749229, 8
          tz.transition 2047, 2, :o1, 29625187, 12
          tz.transition 2047, 11, :o2, 19752141, 8
          tz.transition 2048, 2, :o1, 29629555, 12
          tz.transition 2048, 11, :o2, 19755053, 8
          tz.transition 2049, 2, :o1, 29634007, 12
          tz.transition 2049, 11, :o2, 19758021, 8
          tz.transition 2050, 2, :o1, 29638375, 12
        end
      end
    end
  end
end
