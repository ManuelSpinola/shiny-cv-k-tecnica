#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(ellmer)
library(kuzco)
library(gt)
library(gargle)
library(magick)
library(bslib)

# Cargar funciones auxiliares
source("my_view_llm_results.R")

# Claves API desde variables de entorno
GEMINI_API_KEY <- Sys.getenv("GEMINI_API_KEY")
GOOGLE_API_KEY <- Sys.getenv("GOOGLE_API_KEY")

ui <- fluidPage(
  # Encabezado con título y subtítulo centrados
  tags$div(
    style = "text-align: center; margin-bottom: 10px;",
    tags$h1("BioObserva"),
    tags$h3("¿Qué hay en tu imagen? Análisis visual e identificación de especies"),
    div(style = "height: 10px;"),
    tags$h4("Con la ayuda de Noctua, el búho observador", style = "font-style: italic;"),
    div(style = "height: 10px;"),
    tags$p(
      HTML("<strong>Noctua</strong>, nuestro búho observador, utiliza inteligencia artificial para ayudarte a descubrir lo que hay en una imagen. No solo identifica las especies presentes, sino que también analiza toda la escena visual, detectando detalles relevantes que podrían pasar desapercibidos. Ideal para aprender, explorar y maravillarse con la biodiversidad que nos rodea.")
    )
  ),
  
  # Logo centrado
  tags$div(
    style = "text-align: center; margin-bottom: 10px;",
    tags$img(src = "logo_maritza.png", style = "max-width: 250px; height: auto;")
  ),
  
  # Crédito del logo
  tags$div(
    style = "text-align: center; font-style: italic; font-size: 0.9em; margin-bottom: 30px;",
    "Ilustración por Gemini 2.0 Flash y Maritza Ramírez"
  ),
  
  # Inputs centrados
  div(
    style = "max-width: 600px; margin: auto;",
    fileInput(
      inputId = "imagen",
      label = "Escoge una imagen",
      buttonLabel = "Seleccionar...",
      placeholder = "Ningún archivo seleccionado",
      width = "100%"
    ),
    div(style = "text-align: center;",
        actionButton("goButton", "Analizar imagen")
    )
  ),
  
  # Resultado: imagen, texto y tabla centrados
  div(
    style = "max-width: 700px; margin: 40px auto; padding: 10px;",
    
    imageOutput("my_image", height = "auto"),
    
    div(
      style = "margin-top: 20px;",
      gt_output("results_table")
    )
  )
)

server <- function(input, output, session) {
  
  # Mostrar la imagen cargada
  observeEvent(input$imagen, {
    req(input$imagen)
    output$my_image <- renderImage({
      list(
        src = input$imagen$datapath,
        contentType = input$imagen$type,
        width = "100%",
        height = "auto"
      )
    }, deleteFile = FALSE)
  })
  
  # Análisis con Gemini al hacer clic en el botón
  resultado <- eventReactive(input$goButton, {
    req(input$imagen)
    
    kuzco::llm_image_custom(
      provider = "google_gemini",
      llm_model = "gemini-2.5-flash",
      backend = "ellmer",
      api_key = GOOGLE_API_KEY,
      image = input$imagen$datapath,
      system_prompt = "Eres un experto en taxonomía y biodiversidad. Observa la imagen proporcionada y responde en español con el nombre científico, familia y una breve descripción de la especie que aparece.",
      image_prompt = "¿Qué especie aparece en esta imagen?",
      example_df = data.frame(
        nombre_cientifico = "Panthera onca",
        familia = "Felidae",
        descripcion = "El jaguar es un gran felino nativo de América Central y del Sur."
      )
    )
  })
  
  output$results_table <- render_gt({
    req(resultado())
    gt::gt(resultado())
  })
}

shinyApp(ui, server)