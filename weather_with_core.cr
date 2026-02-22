# 
# The first thing we are going to is that common functionality that is needed no matter the user input and ouput.
# We call this part of the software the "Core": The goal of it is that it will be easy to add more data sources, or visualizations.
#
# The "Core" will provide the following functionality:
#
# - Logic for querying a generic source
# - Logic for triggering the visualization
# - Logic for reading out user configuration
#
# Our application will have the following big building blocks:
#
# - "Core" logic
# - Any number of implementations for sources => "sources driver"
# - Any number of visualizations  of the data => "visualization driver"
#
# While the "Core" will trigger the drivers, it is also planned that it will provide common functionality (e.g., reading the config file), that the driver can use directly.
# Because there are multiple drivers, it makes sense to have them depend on the Core.
# For the Core to be able to trigger the drivers, it will provide interfaces, for which implementations can be registered via the drivers.
#
# Alternative architectures could be:
# - The Core provides all the information to the drivers via interfaces provided by the drivers.
#   This architecture is a bit weird, because now the interfaces need to be owned by the drivers.
#   However, the drivers generally don't care about each other; them having shared ownership is a bit weird.
#   Therefore, one would probably introduce an additional entity that will have the "ownership" of these interfaces.
#   The architecture would therefore look as follows:

#      Core
#       |
#       v
#     Driver interfaces <-----------
#       ^         ^       \         \
#       |         |       |         |
#     SDriver1 SDriver2 VDriver1 VDriver2
#
#   This kind of architecture can also be found in the wild.
#   For example, whenever an interface is defined in a third party place, e.g., a standard.
#
#   In practice, however, to be more agile, the interfaces are not some fixed standardised thing.
#   Instead, the developers implementing the "Core" will often have concrete ideas of what they want from the driver.
#   Note also that driver developers may request additional functionality from Core.
#   This more-or-less corresponds to Conways law that states that code structure orients itself around organizational structure.
#
# Note that architecting an application of this scope in that way is a bit unnecessary: 
# As a single developer can implement the application, it will probably be possible to create a maintainable application without explicit architecting.
# However, if we would imagine that the project is huge and there are many teams, sub-teams where each team has a handful of people, such structuring is more-or-less unavoidable (interacts with Conways law).
# The question in a project of this scope is: what is a structuring such that teams can be partitioned to be most efficient.
#
# An additional interesting thought at this point can be:
# Where would the visualization drivers put code that they want to share between each other?
# The usual answer would be that it will not be part of "Core":
# Instead, the visualization driver developers would add their own common code entity. E.g.:
#
#      Core <-----------------------
#       ^         \       \         \
#       |         |       |         |
#     SDriver1 SDriver2 VDriver1 VDriver2
#
# Turns into:
#
#      Core <-------------------------------------
#       ^         \       \            \          \
#       |         |       |            |          |
#     SDriver1 SDriver2 VDriver1 -> VCommon <- VDriver2
#
# The reason for this would be:
#
# - The "Core" people don't care about visualization specialities; their domain is more generic.
# - The visualization driver people want a place for common code, to keep code duplication low.
#   E.g., to increase the chance that if a bug is found only one code location needs to be fixed.
# 
#
# The architects job will be to decide which parts exist. E.g.:
#
# - What belongs into Core, do we need to subdivide Core more?
# - What is the job of the drivers?
# I.e., the decisions of the architect will influence the exact interfaces fundamentally.
#
# As the system grows bigger and more complicated, it will naturally be harder to implement features that are fundamentally different.
# Even if everything is nicely structured, this does not mean that adding such features is easy.
# The job of the architect then is how best to extend the various participants to support such features.
# Often the architect needs to decide on a compromise: The effort of the implementation needs to be weighed against the additional complexity that will be added.
# On the one extreme, a complete rework of the "Core" and the associated systems could be decided upon, or on the other extreme, only the drivers will be adapted for the feature, but may need some code duplication and ugly hacks to get the job done.
# Thankfully, in my experience, if the "Core" system is already a later iteration of a system, the fundamentals are fixed, and new features only need to touch specific parts of the system.
# 
# For example, what if in the future, the idea of the program is changed to become a lot more user interactable; i.e., instead of only a user configuration existing to modify the system, we now want external triggers to dynamically influence the system.
# One could either decide that this only makes sense with specific visualization drivers, and the ones in question can be adapted.
# Or, this is so fundamental that a new "DynamicConfig" system is added to the Core.
# Or if the data sources shall be changed on-the-fly, there are again a few options; either a source driver is added that is dynamically delegating to another source driver, or alternatively the "Core" system could need to be enhanced such that it directly can implement the dynamic switching of data sources.
#
# Based on this example, it can already be observed that an architect would be person that is able to understand all the options.
# If no architect would exist, the team which ends up with the task would very likely try to implement it on their end.
#
# It may also spark the idea of doing "up-front" architecture.
# However, similar that writing code for future problems usually does not pan-out, this is also a danger for the architecture work being done early on.
# Especially if the domain is in a lot of flux, "up-front" architecture that tries to accomodate all possible future feauters is probably impossible,
# and a more iterative approach needs to be taken.
# In case of a more closed domain, up-front architecting will be hard becaues the architect needs to basically check that no code is written that is breaking necessary assumptions.
#
# 
# This architecture structure can also appear multiple times in various places.
# E.g., the concept of "middleware" is conceptually similar to a "Core", as described here.
# And one can imagine that there is an application that relies on a "middleware", but additionally provides a "Core".

require "http/client"
require "json"

module Core
  # The Data model supported
  #
  # Intented to be used by the driver code
  # Usually the data structures in here are only used opaquely by the code belonging to Core.
  module Model
    module WeatherPrediction
      class Today
        getter precipitation : Float64
        getter temperatureMin : Float64
        getter temperatureMax : Float64

        def initialize(@precipitation, @temperatureMin, @temperatureMax)
        end
      end
    end
  end

  # TODO: read a config file for things
  #
  # Allowed to be used by the driver code
  module Config
    # TODO: implement generic config for fetching value for a key
  end

  # TODO: main entry point of the application
  #
  # Not allowed to be used by the driver code
  module Main
    extend self
    def main
      vd = Registry.registeredVDrivers.first_value
      sd = Registry.registeredSDrivers.first_value
      while true
        w = sd.fetch
        vd.display w
        sleep Time::Span.new(seconds: 1)
      end
    end
  end

  # Intended to be used by the driver code
  module DriverInterfaces
    module VDriver
      abstract class DisplayInfoHook
        abstract def display(data : Model::WeatherPrediction::Today)
      end
    end

    module SDriver
      abstract class FetchInfoHook
        abstract def fetch : Model::WeatherPrediction::Today
      end
    end
  end

  # TODO: allow registering of the drivers
  #
  # Intended to be used by the driver code to register themself.
  module Registry
    extend self
    # TODO: hide the variables inside of a singleton.
    @@registeredVDrivers = {} of String => DriverInterfaces::VDriver::DisplayInfoHook
    @@registeredSDrivers = {} of String =>
                           DriverInterfaces::SDriver::FetchInfoHook

    def registerVDriver(name : String, hookImpl :
                        DriverInterfaces::VDriver::DisplayInfoHook)
      if @@registeredVDrivers.has_key? name
        raise "Can not register different drivers for the same name!"
      end

      @@registeredVDrivers[name] = hookImpl
    end

    def registerSDriver(name : String, hookImpl :
                        DriverInterfaces::SDriver::FetchInfoHook)
      if @@registeredSDrivers.has_key? name
        raise "Can not register different drivers for the same name!"
      end

      @@registeredSDrivers[name] = hookImpl
    end

    def registeredVDrivers
      @@registeredVDrivers
    end

    def registeredSDrivers
      @@registeredSDrivers
    end
  end

end

module VDriver

  # TODO: text based UI
  module Tui
    class Impl < Core::DriverInterfaces::VDriver::DisplayInfoHook
      def display(data : Core::Model::WeatherPrediction::Today)
        # business logic; provide overview
        if data.precipitation > 10
          puts "Prepare for rain!"
        end

        if data.temperatureMin < 10
          puts "It will be pretty cold!"
        end

        if data.temperatureMax > 20
          puts "It will be pretty warm!"
        end

        if data.temperatureMin > 10 && data.temperatureMax < 20
          puts "Normal weather!"
        end
      end
    end
  end

  # TODO: creates a window and draws via SDL
  #module SDL
  #end

  # TODO: directly draws to the (Linux) framebuffer
  #module FB
  #end
end

module SDriver
  module DWD
    class Impl < Core::DriverInterfaces::SDriver::FetchInfoHook
      def fetch : Core::Model::WeatherPrediction::Today
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

        Core::Model::WeatherPrediction::Today.new(precipitation, temperatureMin,
                                                 temperatureMax)
      end
    end
  end
end

# Register drivers
Core::Registry.registerVDriver("sth", VDriver::Tui::Impl.new)
Core::Registry.registerSDriver("sth", SDriver::DWD::Impl.new)

# Start the application
Core::Main.main


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
