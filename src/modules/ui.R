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
          useShinyjs(),
          shinyjs::extendShinyjs(
            text = "shinyjs.resetPage = function (params) { window.location.search = params.toString(); }",
            functions = c("resetPage")
          ),
          shiny::textInput("query",
                           label = "Google Photo query",
                           value = "Our Dear One Dawna"),
          shiny::tableOutput("gdrive"),
          # selectInput("col", "Colour:",
          #             c("white", "yellow", "red", "blue", "purple")),
          class = "display-inline-block restrain-width text-align-center"
        )
    # )
}
