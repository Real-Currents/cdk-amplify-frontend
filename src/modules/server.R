server <- function (input, output, session) {
  # observeEvent(input$col, {
  #   shinyjs::js$resetPage(paste0("test=",input$col))
  # })

  include("modules/googlePhotoMutator.R")
  googlePhotoMutator(input, output, session, googleUserData,
                     album_title = "Our Dear One Dawna",
                     album_url = "https://photos.google.com/lr/album/AOTYMnnzEQKgqfLLyGUMr-BkGgfoCBfMfjLgzurJp09sXg7NT1-kS8Eiw-4AEProM2NAkNnGwAEG"
  )
}
