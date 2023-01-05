# oauth_client_id <- Sys.getenv("OAUTH_CLIENT_ID")
# oauth_client_secret <- Sys.getenv("OAUTH_CLIENT_SECRET")
# options("googleAuthR.scopes.selected" = c(
#   "https://www.googleapis.com/auth/photoslibrary",
#   "https://www.googleapis.com/auth/photoslibrary.sharing",
#   "https://www.googleapis.com/auth/urlshortener"
# ))

# fileSearch <- function(query) {
#   googleAuthR::gar_api_generator("https://www.googleapis.com/drive/v3/files/",
#                                  "GET",
#                                  pars_args=list(q=query),
#                                  data_parse_function = function(x) x$files)()
# }

# shorten_url <- function(url){
#   body = list(
#     longUrl = url
#   )
#
#   f <- gar_api_generator("https://www.googleapis.com/urlshortener/v1/url",
#                       "POST",
#                       data_parse_function = function(x) x$id)
#
#   f(the_body = body)
# }

googleUserCredentials <- function (googleUserData, session) {

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

  url_query <- shiny::isolate(parseQueryString(session$clientData$url_search))

  if ("code" %in% names(url_query)) {
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
          message(toJSON(session$userData[["credentials"]]))

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
      message(toJSON(session$userData[["credentials"]]))

      session$userData[["credentials"]]
    }
  } else {
    message("Current userData credentials: ")
    message(toJSON(session$userData[["credentials"]]))
    session$userData[["credentials"]]
  }

  if (!is.null(session$userData[["credentials"]])) {
    session$sendCustomMessage(
      type = 'credentials',
      message = session$userData[["credentials"]])
  }

  return(session$userData[["credentials"]])
}

googlePhotoDownloadJPEG <- function (file_name, file_url) {
  ## From https://community.rstudio.com/t/access-and-download-images-from-urls-which-are-values-of-a-variable/66534/2
  library(jpeg) #to read and write the images
  library(here) #to save the files to the right location - this only works if you're working with a R project

  file_path <- paste0("www/media/", file_name)

  # Check if the file is already available
  if (file.exists(file_path)) {
    pic <- readJPEG(file_path)

  } else {
    ## Code to read download file and save it will look something like this:
    ## Creating temporary place to save download
    z <- tempfile()
    #Downloding the file
    download.file(file_url, z, mode="wb")
    #Reading the file from the temp object
    pic <- readJPEG(z)
    #Saving to your location
    writeJPEG(pic, file_path)
    # cleanup
    file.remove(z)
  }

  return(pic)
}

googlePhotoMutator <- function (input, output, session, googleUserData, album_title, album_url) {

  for(userCode in names(shiny::isolate(shiny::reactiveValuesToList(googleUserData)))) {
    print(userCode)
    user <- shiny::isolate(shiny::reactiveValuesToList(googleUserData))[[userCode]]
    print(user)
    print("\n")
  }

  # k <- gargle::token_fetch(token = gar_token())

  output$gdrive <- shiny::renderTable({

    # no need for with_shiny()
    # fileSearch(input$query)

    authorization <- googleUserCredentials(googleUserData, session)

    result <- if (!is.null(authorization)) {

      req_url <- "https://photoslibrary.googleapis.com/v1/albums"

      getalbums <-
        httr::GET(req_url,
                  add_headers(
                    'Authorization' = paste(authorization$token_type, authorization$access_token),
                    'Accept'  = 'application/json')) %>%
          content(., as = "text", encoding = "UTF-8")

      # data.frame(c(mode = "test"))
      getalbums %>%
        fromJSON(., flatten = TRUE) %>%
        data.frame()

    } else data.frame(c(mode = "test"))

    return(result)

  })

  output$selectedAlbum <- shiny::renderUI({

    authorization <- googleUserCredentials(googleUserData, session)

    shiny::req(input$query)

    result <- if(!is.null(authorization)) {

      req_url <- "https://photoslibrary.googleapis.com/v1/albums"

      getalbums <-
        httr::GET(req_url,
            add_headers(
              'Authorization' = paste(authorization$token_type, authorization$access_token),
              'Accept'  = 'application/json')) %>%
          content(., as = "text", encoding = "UTF-8")

      selected_album <- getalbums %>%
        fromJSON(., flatten = TRUE) %>%
        data.frame() %>%
        dplyr::filter(
          # `albums.title` == album_title
          `albums.title` == input$query
        )

      session$sendCustomMessage(
        type = 'album_title',
        message = (
          selected_album
        )$albums.title
      )

      getAlbumMedia <- httr::POST(
        "https://photoslibrary.googleapis.com/v1/mediaItems:search",
        add_headers(
          'Authorization' = paste(authorization$token_type, authorization$access_token),
          'Accept'  = 'application/json'),
        body = sprintf('
{
  "albumId": "%s",
  "pageSize": 100
}
', selected_album$albums.id) # "AOTYMnmSBBNEgVLsjArxvOCCBiHb0RnfF9k96LuA14rvZc8H0yIxZINcFPmUXBH1j2cuTjScQODU")
      ) %>%
        content(., as = "text", encoding = "UTF-8")

      session$sendCustomMessage(
        type = 'album_media',
        message = (
          getAlbumMedia
        )
      )

      album_media_frame <- getAlbumMedia %>%
        fromJSON(., flatten = TRUE) %>%
        data.frame()

      media_objects <- list()

      for (media_idx in c(1:nrow(album_media_frame))) {
        media_meta <- album_media_frame[media_idx,]
        media_file_name <- media_meta$mediaItems.filename
        media_url <- media_meta$mediaItems.baseUrl
        media_width <- media_meta$mediaItems.mediaMetadata.width
        media_height <- media_meta$mediaItems.mediaMetadata.height

        try({

          print(paste0("Loading ", media_file_name, " from..."))
          print(paste0(media_url, "=w", media_width, "-h", media_height))

          if (grepl("jpg", media_file_name)) {
            downloaded <- googlePhotoDownloadJPEG(
              media_file_name,
              paste0(media_url, "=w", media_width, "-h", media_height)
            )
            local_url <- paste0("www/media/", media_file_name)

            if (!is.null(downloaded) && file.exists(local_url)) {
              media_objects[[(length(media_objects) + 1)]] <- sprintf('%s', paste0("/", local_url))
            }
          }

        })
      }

      cat(toJSON(unlist(media_objects)))

      ## Store media uri's as relative links
      write_json(list("objects" = stringr::str_replace_all(unlist(media_objects)), "/www/", ""), path = "www/media/media_objects.json")

      ## Create a slideshow widget based on https://www.publicalbum.org/blog/embedding-google-photos-albums
      tagList(div(HTML(paste0('
<script src="https://cdn.jsdelivr.net/npm/publicalbum@latest/embed-ui.min.js" async></script>
<div class="pa-gallery-player-widget" style="width:100%%; height:480px; display:none;"
  data-link="https://photos.google.com/share/AF1QipNgIGpnUI_vsvrpoIj_enTw2-IWIIqAj7v_LqlYHJILB1oByeVyUduwOTy_mwQGBA?key=aGhEUmdONWQ2bHVVcmdmSldXX3FOOVowRFgxRDlR"
  data-title="Our Dear One Dawna"
  data-description="New item added to shared album">
  ', paste0(paste('<object data="', media_objects, '"></object>', sep = ""), collapse = "\n"), '
</div>
'))))

    } else tagList(div(HTML("test")))

    return(result)
  })
}
