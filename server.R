#   This program generates a map for transit buses is patterned after shiny
#   Example-086 for Minneapolis, MN. My contribution is to adapt it for the
#   API for the Chicago Transit Authority

library(shinydashboard)
library(leaflet)
library(dplyr)
library(curl) # make the jsonlite suggested dependency explicit

#   1=South, 2=East, 3=West, 4=North
    dirColors <-c("1"="#595490", "2"="#527525", "3"="#A93F35", "4"="#BA48AA")

#   Load static trip and shape data
    trips  <- readRDS("metrotransit-data/rds/trips.rds")
    shapes <- readRDS("metrotransit-data/rds/shapes.rds")

#   The following function getBusData() accepts three input:
#   (1) info: We always enter "getvehicles" but there are other possibilities.
#   (2) info_detail: We always enter "rt" for the bus route number; "vid" is
#     another possibility.
#   (3) bus_routes: We enter "22,49,56,63,65,66,72,90,92,151" for ten popular
#                   bus routes because the shiny drop-down selector may be 
#                   limited to no more than 10 choices.
#   (4) key: An ID obtained from the Chicago Transit Authority

#   A data frame for all buses on the list of the bus_routes parameter is
#   returned.
    
key = " " # ID obtained from Chicago Transit Authority
    
getBusData <- function(info,info_detail,bus_routes,key) {
    url <- paste("http://www.ctabustracker.com/bustime/api/v2/",info,
                 "?key=",key,"&",info_detail,"=",bus_routes,
                 "&format=json",sep="") 
    jsonlite::fromJSON(url)
}

#   Function: get_route_shape

#   Since the buses in Chicago are fairly straight, get_route_shape is useful
#   only in a few cases. But we seek to follow the shiny example. It gets the
#   shape for a particular route. Each route has a large number of different
#   trips, and each trip can have a different shape. This function simply returns
#   the most commonly-used shape across all trips for a particular route.

get_route_shape <- function(route) {
    routeid <- paste0(route, "-75")

  # For this route, get all the shape_ids listed in trips, and a count of how
  # many times each shape is used. We'll just pick the most commonly-used shape.
    shape_counts <- trips %>%
    filter(route_id == routeid) %>%
    group_by(shape_id) %>%
    summarise(n = n()) %>%
    arrange(-n)

    shapeid <- shape_counts$shape_id[1]

  # Get the coordinates for the shape_id
    shapes %>% filter(shape_id == shapeid)
}


function(input, output, session) {

  # Route select input box
    output$routeSelect <- renderUI({
    routeNums <- c(22,49,56,63,65,66,72,90,92,151)
  # Add names, so that we can add all=0
    names(routeNums) <- routeNums
    routeNums <- c(All = 0, routeNums)
    selectInput("routeNum", "Bus Route", choices = routeNums,
                                        selected = routeNums[2])
  })

#   Locations of all active vehicles
    vehicleLocations <- reactive({
        input$refresh # Refresh if button clicked

    #   Get interval (minimum 60)
        interval <- max(as.numeric(input$interval), 60)
    #   Invalidate this reactive after the interval has passed, so that data is
    #   fetched again.
        invalidateLater(interval * 1000, session)
        bus_data <- getBusData("getvehicles","rt",
                        bus_routes="22,49,56,63,65,66,72,90,92,151",key)[[1]][[1]]  
        bus_data[,"lat"] <- as.numeric(bus_data[,"lat"]) # Latitude 
        bus_data[,"lon"] <- as.numeric(bus_data[,"lon"]) # Longitude 
        bus_data[,"hdg"] <- as.numeric(bus_data[,"hdg"]) # Bus direction, heading
        
    #   "North", Direction-4
        bus_data[,"Direction"] <- 4 
    #   "East", Direction-2        
        bus_data[bus_data$hdg > 60 & bus_data$hdg < 120, "Direction"] <- 2
    #   "South", Direction-1
        bus_data[bus_data$hdg >= 120 & bus_data$hdg <= 240, "Direction"] <- 1
    #   "West", Direction-3
        bus_data[bus_data$hdg > 240 & bus_data$hdg < 300, "Direction"] <- 3
        bus_data
  })

#   Locations of vehicles for a particular route
    routeVehicleLocations <- reactive({
    
    if (is.null(input$routeNum))
      return()

    locations <- vehicleLocations()

    if (as.numeric(input$routeNum) == 0)
      return(locations)

    locations[locations$rt == input$routeNum,c("lat","lon","Direction") ]
  })

# Get time that vehicles locations were updated
  lastUpdateTime <- reactive({
    vehicleLocations() # Trigger this reactive when vehicles locations are updated
    Sys.time()
  })

# Number of seconds since last update
  output$timeSinceLastUpdate <- renderUI({
    # Trigger this every 5 seconds
    invalidateLater(5000, session)
    p(
      class = "text-muted",
      "Data refreshed ",
      round(difftime(Sys.time(), lastUpdateTime(), units="secs")),
      " seconds ago."
    )
  })

  output$numVehiclesTable <- renderUI({
    locations <- routeVehicleLocations()
    if (length(locations) == 0 || nrow(locations) == 0)
      return(NULL)

#   Create a Bootstrap-styled table
    tags$table(class = "table",
      tags$thead(tags$tr(
        tags$th("Color"),
        tags$th("Direction"),
        tags$th("Number of vehicles")
      )),
      tags$tbody(
        tags$tr(
          tags$td(span(style = sprintf(
            "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
            dirColors[4]
          ))),
          tags$td("Northbound"),
          tags$td(nrow(locations[locations$Direction == "4",]))
        ),
        tags$tr(
          tags$td(span(style = sprintf(
            "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
            dirColors[1]
          ))),
          tags$td("Southbound"),
          tags$td(nrow(locations[locations$Direction == "1",]))
        ),
        tags$tr(
          tags$td(span(style = sprintf(
            "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
            dirColors[2]
          ))),
          tags$td("Eastbound"),
          tags$td(nrow(locations[locations$Direction == "2",]))
        ),
        tags$tr(
          tags$td(span(style = sprintf(
            "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
            dirColors[3]
          ))),
          tags$td("Westbound"),
          tags$td(nrow(locations[locations$Direction == "3",]))
        ),
        tags$tr(class = "active",
          tags$td(),
          tags$td("Total"),
          tags$td(nrow(locations))
        )
      )
    )
  })

#   Store last zoom button value so we can detect when it's clicked
    lastZoomButtonValue <- NULL

    output$busmap <- renderLeaflet({
        locations <- routeVehicleLocations()
        locs <- class(locations)
       if (locs != "data.frame")
           return(NULL)

#   Show only selected directions
    locations <- filter(locations, Direction %in% as.numeric(input$Directions))

#   Four possible directions for bus routes
    dirPal <- colorFactor(dirColors, names(dirColors))

    map <- leaflet(locations) %>%
      addTiles('http://{s}.tile.thunderforest.com/transport/{z}/{x}/{y}.png') %>%
      addCircleMarkers(
        lat = ~locations$lat,
        lng = ~locations$lon,
        color = ~dirPal(Direction),
        opacity = 0.8,
        radius = 8
      )

    if (as.numeric(input$routeNum) != 0) {
      route_shape <- get_route_shape(input$routeNum)

      map <- addPolylines(map,
        route_shape$shape_pt_lon,
        route_shape$shape_pt_lat,
        fill = FALSE
      )
    }

    rezoom <- "first"
# If zoom button was clicked this time, and store the value, and rezoom
    if (!identical(lastZoomButtonValue, input$zoomButton)) {
      lastZoomButtonValue <<- input$zoomButton
      rezoom <- "always"
    }

    map <- map %>% mapOptions(zoomToLimits = rezoom)

    map
  })
}
