library(shinydashboard)
library(leaflet)

header <- dashboardHeader(
  title = "Chicago Transit Authority Buses"
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
        h4("Ten selected bus routes"),
        tags$br(),
        actionButton("zoomButton", "Zoom to fit buses"),
        tags$br(),
        tags$br(),
        tags$br(),
        checkboxGroupInput("directions", "Show",
          choices = c(
            Northbound = 4,
            Southbound = 1,
            Eastbound = 2,
            Westbound = 3
          ),
          selected = c(1, 2, 3, 4)
        ),
        tags$br(),
        p(paste("Note:")),
        p(
          class = "text-muted",
          paste("A route number can have several different trips, each",
                "with a different path. Only the most commonly-used path will",
                "be displayed on the map.")
        )
        
      ),
      box(width = NULL, status = "warning",
        selectInput("interval", "Refresh interval",
          choices = c(
            "30 seconds" = 30,
            "1 minute" = 60,
            "2 minutes" = 120,
            "5 minutes" = 300,
            "10 minutes" = 600
          ),
          selected = "60"
        ),
        uiOutput("timeSinceLastUpdate"),
        actionButton("refresh", "Refresh now"),
        p(class = "text-muted",
          br(),
          "Source data updates every 30 seconds."
        ),
        p(class = "text-muted",
          br(),
          paste("A route number can have several different trips, each",
                "with a different path. Only the most commonly-used path will",
                "be displayed on the map." )
          ),
        p(class = "text-muted",
          br(),
          paste("This website is adapted from the Shiny-086 example for",
                "Minneapolis in order to accommodate the API for the Chicago",
                "Transit Authority",
                "Marcel Merchat, Phone: 773-852-1689",
                "https://github.com/marcelMerchat/chicagoTransitAuthorityBusesDemo2")
        )
      )
    )
  )
)

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)
