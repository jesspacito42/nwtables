### NW Loot Tables
### UI File

# Libraries
library(shiny)
library(DT)

# UI
shinyUI(fluidPage(
    title = 'NW Tables',
    fluidRow(
        column(2),
        column(8, h1('Loot Tables'),),
        column(2)
    ),
    fluidRow(
        column(2), 
        column(8, DT::dataTableOutput('lt')),
        column(2)
    ),
    includeCSS("nwtables-gruvbox.css"), 
    tags$head(tags$script(src="https://use.fontawesome.com/releases/v5.15.4/js/all.js"))
))
