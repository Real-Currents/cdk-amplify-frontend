library(shiny)
library(googleAuthR)

ui <- function (ui_run) {
    # shiny::fluidPage(title = "googleAuthR Shiny Demo",
    #                  shiny::textInput("query",
    #                                   label = "Google Drive query",
    #                                   value = "mimeType != 'application/vnd.google-apps.folder'"),
    #                  shiny::tableOutput("gdrive")
    # )

    message(paste0("ui_run: ", shiny::isolate(ui_run())))

    # htmlTemplate(
    #   "templates/index.html",
        #google_login =
        shiny::div(
          shiny::textInput("query",
                           label = "Google Photo query",
                           value = "Our Dear One Dawna"),
          shiny::tableOutput("gdrive"),
          class = "display-inline-block restrain-width text-align-center"
        )
    # )
}
