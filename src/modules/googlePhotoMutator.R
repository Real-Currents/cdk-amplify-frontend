# oauth_client_id <- Sys.getenv("OAUTH_CLIENT_ID")
# oauth_client_secret <- Sys.getenv("OAUTH_CLIENT_SECRET")
# options("googleAuthR.scopes.selected" = c(
#   "https://www.googleapis.com/auth/photoslibrary",
#   "https://www.googleapis.com/auth/photoslibrary.sharing",
#   "https://www.googleapis.com/auth/urlshortener"
# ))

fileSearch <- function(query) {
  googleAuthR::gar_api_generator("https://www.googleapis.com/drive/v3/files/",
                                 "GET",
                                 pars_args=list(q=query),
                                 data_parse_function = function(x) x$files)()
}

shorten_url <- function(url){
  body = list(
    longUrl = url
  )

  f <-
    gar_api_generator("https://www.googleapis.com/urlshortener/v1/url",
                      "POST",
                      data_parse_function = function(x) x$id)

  f(the_body = body)

}

googlePhotoMutator <- function (input, output, session, googleUserData, album_title, album_url) {

  app_redirect_uri <- paste0(
    shiny::isolate(session$clientData$url_protocol), "//",
    ifelse(!grepl("127", shiny::isolate(session$clientData$url_hostname)),
           shiny::isolate(session$clientData$url_hostname),
           "localhost"
    ),
    ifelse(is.null(shiny::isolate(session$clientData$url_port)),
           "",
           paste0(":", shiny::isolate(session$clientData$url_port))
    )
  )

  message(app_redirect_uri)

  options(googleAuthR.redirect = app_redirect_uri) # 'http://localhost:1221')

  for(userCode in names(shiny::isolate(shiny::reactiveValuesToList(googleUserData)))) {
    print(userCode)
    user <- shiny::isolate(shiny::reactiveValuesToList(googleUserData))[[userCode]]
    print(user)
    print("\n")
  }

  url_query <- shiny::isolate(parseQueryString(session$clientData$url_search))

  # k <- gargle::token_fetch(token = gar_token())
  googleUserCredentials <- if ("code" %in% names(url_query)){
    url_code <- url_query$code
    if (!(url_code %in% names(shiny::isolate(shiny::reactiveValuesToList(googleUserData))))) {
      tryCatch(
        {
          k <- gar_shiny_auth(session)
          if (!is.null(k)) {
            credentials <- get("credentials", envir = k)

            session$userData[["credentials"]] <- credentials

            googleUserData[[url_code]] <- session$userData
            googleUserData[[url_code]] <<- session$userData #<<- modifies ws_clients globally

            message("Updated userData credentials: ")
            message(as.character(session$userData[["credentials"]]))

            session$userData[["credentials"]]
          }
        },
        error =  function (e) {

          # # DEBUG
          # message(e)

          #if (!no_error) {
          if (!is.null(e) && !is.na(e$message) && grepl("invalid_grantBad", e$message)) {
            ## reset $url_search
            updateQueryString("", mode = c("replace"), session = session)
            shinyjs::js$resetPage("")
          }
        },
        finally = "Attempted to get authorization with old code."
      )
    } else {

      session$userData[["credentials"]] <- get(
        "credentials",
        shiny::isolate(shiny::reactiveValuesToList(googleUserData))[[url_code]])

      message("Previous userData credentials: ")
      message(as.character(session$userData[["credentials"]]))

      session$userData[["credentials"]]
    }
  } else {
    message("Current userData credentials: ")
    message(as.character(session$userData[["credentials"]]))
    session$userData[["credentials"]]
  }

  output$gdrive <- shiny::renderTable({

    result <- if(!is.null(session$userData[["credentials"]])) {
      authorization = paste('Bearer ', session$userData[["credentials"]]$access_token)

      getalbum <-
        GET(glue("https://photoslibrary.googleapis.com/v1/albums"),
            add_headers(
              'Authorization' = authorization,
              'Accept'  = 'application/json')) %>%
          content(., as = "text", encoding = "UTF-8") %>%
          fromJSON(., flatten = TRUE) %>%
          data.frame()

      if (nrow(getalbum) > 0) {
        session$sendCustomMessage(
          type = 'credentials',
          message = session$userData[["credentials"]])
      }

      shiny::req(input$query)

      # no need for with_shiny()
      # fileSearch(input$query)

      session$sendCustomMessage(
        type = 'album_title',
        message = (
          getalbum %>%
            dplyr::filter(
              # `albums.title` == album_title
              `albums.title` == input$query
            )
        )$albums.title
      )

      # data.frame(c(mode = "test"))
      getalbum %>%
        dplyr::filter(
          # `albums.title` == album_title
          `albums.title` == input$query
        )
    } else {
      data.frame(c(mode = "test"))
    }

    return(result)

  })

  # ## Create access token and render login button
  # access_token <- callModule(googleAuth,
  #                            "loginButton",
  #                            login_text = "Login1")
  #
  # access_token <- callModule(googleSignIn, "your_id")
  #
  # output$short_url <- renderText({
  #
  #   access_token()
  #
  # })

  # app_redirect_uri <- paste0(
  #   session$clientData$url_protocol, "//",
  #   ifelse(!grepl("127", session$clientData$url_hostname),
  #          session$clientData$url_hostname,
  #          "localhost"
  #   ),
  #   ifelse(is.null(session$clientData$url_port),
  #          "",
  #          paste0(":", session$clientData$url_port)
  #   )
  # )
  #
  # # message(app_redirect_uri)

  # app <- reactiveVal(
  #   oauth_app(appname = "OurDearOneDawna",
  #             key = oauth_client_id,
  #             secret = oauth_client_secret)
  # )
  # # app(
  # #   oauth_app(appname = "OurDearOneDawna",
  # #             key = oauth_client_id,
  # #             secret = oauth_client_secret,
  # #             redirect_uri = app_redirect_uri)
  # # )
  #
  # # authorization = paste('Bearer ', k$credentials$access_token)
}
