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

ui <- fluidPage(
  titlePanel("🧬 Explorador Taxonómico"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("img", "Carga una imagen de una especie", accept = c("image/png", "image/jpeg")),
      actionButton("analizar", "Analizar imagen"),
      br(), br(),
      helpText("Esta aplicación identifica la especie en la imagen y proporciona información científica."),
      helpText("Desarrollado con ", tags$strong("Noctua"), ".")
    ),
    
    mainPanel(
      uiOutput("img_preview"),
      br(),
      gt_output("tabla_resultado")
    )
  )
)

server <- function(input, output, session) {
  
  output$img_preview <- renderUI({
    req(input$img)
    tags$img(
      src = input$img$datapath,
      width = "100%",
      style = "max-width: 400px; display: block; margin-left: auto; margin-right: auto;"
    )
  })
  
  resultado <- eventReactive(input$analizar, {
    req(input$img)
    
    kuzco::llm_image_custom(
      llm_model = "gemini",
      image = input$img$datapath,
      system_prompt = "Eres un experto en taxonomía y biodiversidad. Observa la imagen proporcionada y responde en español con el nombre científico, familia y una breve descripción de la especie que aparece.",
      image_prompt = "¿Qué especie aparece en esta imagen?",
      example_df = data.frame(
        nombre_cientifico = "Panthera onca",
        familia = "Felidae",
        descripcion = "El jaguar es un gran felino nativo de América Central y del Sur."
      )
    )
  })
  
  output$tabla_resultado <- render_gt({
    req(resultado())
    gt::gt(resultado())
  })
}

shinyApp(ui, server)