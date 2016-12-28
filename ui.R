library(shinydashboard)
library(leaflet)

header <- dashboardHeader(
  title = "Live Bus Service: Chicago Transit Authority", titleWidth=600
)

body <- dashboardBody(
  fluidRow(
    column(width = 9,
      box(width = NULL, solidHeader = TRUE,
        leafletOutput("busmap", height = 500)
      ),
      box(width = NULL,
        uiOutput("numVehiclesTable")
      )
    ),
    column(width = 3,
      box(width = NULL, status = "warning",
        uiOutput("routeSelect"),
        h5("Ten bus routes are included in this demo website."),
        tags$br(),
        actionButton("zoomButton", "Zoom to fit buses"),
        tags$br(),
        tags$br(),
        checkboxGroupInput("Directions", "Show",
          choices = c(
            Northbound = 4,
            Southbound = 1,
            Eastbound = 2,
            Westbound = 3
          ),
          selected = c(1, 2, 3, 4)
        ),
        tags$br(),
        selectInput("interval", "Refresh interval",
          choices = c(
            "1 minute" = 60,
            "2 minutes" = 120,
            "5 minutes" = 300,
            "10 minutes" = 600
          ),
          selected = 60
        ),
        uiOutput("timeSinceLastUpdate"),
        p(class = "text-muted",
           "Source data updates every 60 seconds."
        ),
        actionButton("refresh", "Refresh now"),
        
        p(class = "text-muted",
            br(),
            paste("This website is adapted from the Shiny-086 example for",
            "Minneapolis in order to accommodate the API for the Chicago",
            "Transit Authority.")
        ),
        p(class = "text-muted",
          br(),
          paste("Marcel Merchat")
        ),
        p(class = "text-muted",
          paste("Phone: 773-852-1689")
        ),
        p(class = "text-muted",
          "https://github.com/marcelMerchat/chicagoTransitAuthorityBusesDemo2"
        )
      )
    ) # end column
  ) # end fluid row
)

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)
