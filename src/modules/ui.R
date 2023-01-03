library(shiny)
library(shinyjs)
library(googleAuthR)

ui <- function (ui_run) {
    message(paste0("ui_run: ", shiny::isolate(ui_run())))

    gar_shiny_ui(
      htmlTemplate(
        "templates/index.html",
        google_auth = (function () {
            ui_run_update <- shiny::isolate(ui_run()) + 1
            ui_run(ui_run_update)

            shiny::div(
              useShinyjs(),
              shinyjs::extendShinyjs(
                text = "shinyjs.resetPage = function (params) { window.location.search = params.toString(); }",
                functions = c("resetPage")
              ),
              shiny::textInput("query",
                               label = "Google Photo query",
                               value = "Our Dear One Dawna"),
              shiny::uiOutput("selectedAlbum"),
              shiny::tableOutput("gdrive"),
              class = "display-inline-block restrain-width text-align-center"
            )
        })()
      )
    )
}
