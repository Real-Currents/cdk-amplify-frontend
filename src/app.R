source("modules/include.R")

options(`show.error.messages` = TRUE)
options(`usethis.protocol` = "ssh")

## include()... an easy, RStudio re-loadable, way to dynamically
## load Shiny modules (unlike R.utils::sourceDirectory())
include("modules/library.R")
include("modules/global.R")

print(options("googleAuthR.scopes.selected"))

## Google Photos library API requires oauth2.0 authentication of the following two scopes.
#
#### https://www.googleapis.com/auth/photoslibrary
#### https://www.googleapis.com/auth/photoslibrary.sharing
gar_set_client(
  "data/azure-active-directory-345018-ead4206dfb9f.json",
  "data/client_secret_1094116453446-95d6n1eea7mc7cv0aiqbqll3bghr0adg.apps.googleusercontent.com.json",
  scopes = c(
    as.character(
      options("googleAuthR.scopes.selected")
    ),
    "https://www.googleapis.com/auth/photoslibrary",
    "https://www.googleapis.com/auth/photoslibrary.sharing"
  ),
  activate = c("web")
)

googleUserData <- shiny::reactiveValues()

ui_run <- shiny::reactiveVal(0)

shiny::runApp(
  app =
## Create Shiny app ----
    shiny::shinyApp(

    # Define function that *calls* ui ----
    ui = (function () {
          include("modules/ui.R")
          ui(ui_run)
    })(),
    server = function (input, output, session) {

      # message(paste0(getwd(), "/www"))
      #
      # shiny::addResourcePath("/www", paste0(getwd(), "/www"))

      # R.utils::sourceDirectory("modules", local = TRUE)
      ## Instead of ^ R.utils::sourceDirectory(), we use include()...
      ## If called within server/ui function, path to module file
      ## must be relative to dir in which app.R is executing ...

      include("modules/server.R")
      server(input, output, session)
    }
  )
  ,
  host = "0.0.0.0",
  port = as.numeric("1221"),
  launch.browser = FALSE
)
