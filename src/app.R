source("modules/include.R")

options(`show.error.messages` = TRUE)
options(`usethis.protocol` = "ssh")

## include()... an easy, RStudio re-loadable, way to dynamically
## load Shiny modules (unlike R.utils::sourceDirectory())
include("modules/library.R")
include("modules/global.R")

library(googleAuthR)

options(`googleAuthR.scopes.selected` = c(
  "https://www.googleapis.com/auth/urlshortener"
))

print(options("googleAuthR.scopes.selected"))

# options(`googleAuthR.scopes.selected` = c(
#   as.character(
#     options("googleAuthR.scopes.selected")
#   ),
#   "https://www.googleapis.com/auth/photoslibrary",
#   "https://www.googleapis.com/auth/photoslibrary.sharing"
# ))

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

ui_run <- shiny::reactiveVal(1)

# # Create Shiny app ----
# shiny::shinyApp(
#
#     # Define function that *calls* ui ----
#     ui = function () {
#         # include("modules/ui.R")
#         # ui()
#
#       gar_shiny_ui(fluidPage(title = "googleAuthR Shiny Demo",
#                              textInput("query",
#                                        label = "Google Drive query",
#                                        value = "mimeType != 'application/vnd.google-apps.folder'"),
#                              tableOutput("gdrive")
#       ))
#     },
#
#     # Define function that *calls* server logic function ----
#     server = function (input, output, session) {
#
#         # R.utils::sourceDirectory("modules", local = TRUE)
#         ## Instead of ^ R.utils::sourceDirectory(), we use include()...
#         ## If called within server/ui function, path to module file
#         ## must be relative to dir in which app.R is executing ...
#         include("modules/googlePhotoMutator.R")
#         googlePhotoMutator(input, output, session)
#
#         include("modules/server.R")
#         server(input, output, session)
#     }
# )

fileSearch <- function(query) {
  googleAuthR::gar_api_generator("https://www.googleapis.com/drive/v3/files/",
                                 "GET",
                                 pars_args=list(q=query),
                                 data_parse_function = function(x) x$files)()
}

# ## ui.R
# ui <- shiny::fluidPage(title = "googleAuthR Shiny Demo",
#                        shiny::textInput("query",
#                           label = "Google Drive query",
#                           value = "mimeType != 'application/vnd.google-apps.folder'"),
#                        shiny::tableOutput("gdrive")
# )

# ui <- (function () {
#   ui_i <- function () {
#     shiny::fluidPage(title = "googleAuthR Shiny Demo",
#                      shiny::textInput("query",
#                                       label = "Google Drive query",
#                                       value = "mimeType != 'application/vnd.google-apps.folder'"),
#                      shiny::tableOutput("gdrive")
#     )
#   }
#   ui_i()
# })()



# shiny::runApp(
#   ## gar_shiny_ui() needs to wrap the ui you have created above.
#   app =
    shiny::shinyApp(
    ui = (function () {
      message(paste0("ui_run: ", shiny::isolate(ui_run())))
      gar_shiny_ui(htmlTemplate(
        "templates/index.html",
        google_login = (function () {
          ui_run_update <- shiny::isolate(ui_run()) + 1
          ui_run(ui_run_update)

          # ui <- function () {
          #   shiny::fluidPage(title = "googleAuthR Shiny Demo",
          #                    shiny::textInput("query",
          #                                     label = "Google Drive query",
          #                                     value = "mimeType != 'application/vnd.google-apps.folder'"),
          #                    shiny::tableOutput("gdrive")
          #   )
          # }

          include("modules/ui.R")
          ui(ui_run)
        })()
      ))
    })(),
    server = function (input, output, session) {

      # R.utils::sourceDirectory("modules", local = TRUE)
      ## Instead of ^ R.utils::sourceDirectory(), we use include()...
      ## If called within server/ui function, path to module file
      ## must be relative to dir in which app.R is executing ...
      include("modules/googlePhotoMutator.R")
      googlePhotoMutator(input, output, session, googleUserData,
                         album_title = "Our Dear One Dawna",
                         album_url = "https://photos.google.com/lr/album/AOTYMnnzEQKgqfLLyGUMr-BkGgfoCBfMfjLgzurJp09sXg7NT1-kS8Eiw-4AEProM2NAkNnGwAEG"
      )

      include("modules/server.R")
      server(input, output, session)
    }
  )
#   ,
#   host = "0.0.0.0",
#   port = as.numeric("1221"),
#   launch.browser = FALSE
# )
