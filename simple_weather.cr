# A very minimalistic application with a basic use: retrieve some information about the real world, and present it in a different way.
#
# This exact application implementation is not that useful:
# - The output is very minimalistic.
# - The data source is not configurable.
#
# However, the point of it is to have a starting point of the problem we are trying to solve.


#
# Architecture of this program:
# 
#   simple-weather ----\
#   |     |            |
#   |     v            v
#   |  http/client | json
#   |   |              /
#   v   v             /
#   Crystal <---------
#   |    | \ 
#   v    v  ...
# LLVM   libc
#     ...
# Operating system
#

require "http/client"
require "json"

# 10348 is the station of "Böblingen".
response = HTTP::Client.get "https://dwd.api.proxy.bund.dev/v30/stationOverviewExtended?stationIds=10348"
response.status_code
response.body

value = JSON.parse(response.body)

today = value["10348"]["days"][0]

# mm/h
precipitation = today["precipitation"].as_i / 10

# °C
temperatureMin = today["temperatureMin"].as_i / 10
temperatureMax = today["temperatureMax"].as_i / 10

# business logic; provide overview
if precipitation > 10
  puts "Prepare for rain!"
end

if temperatureMin < 10
  puts "It will be pretty cold!"
end

if temperatureMax > 20
  puts "It will be pretty warm!"
end

if temperatureMin > 10 && temperatureMax < 20
  puts "Normal weather!"
end

#
# While this application may look a bit boring, the problem it tries to solve is very typical.
# - Some data needs to be fetched
# - The retrieved data needs to be evaluated
# - The evaluated data needs to be presented
#
# In addition, we can imagine that the user would like this application to be enhanced such that:
# - specify the source from where to retrieve the weather data
# - specify or customize how the weather shall be displayed
# - live updating
#
# Therefore, the architecture of the full blown application should allow the developers maintaining this software to:
# - Read out configuration data
# - Make it straight forward to add more visualizations
# - Make it straight forward to implement more data sources
#
# What is described here is now the scope of this example program.
# I think this scope is perfect to show how programs in the real world are architected.
#
