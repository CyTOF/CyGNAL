args <- commandArgs(trailingOnly = TRUE)

#Packages to use:
list.of.packages <- c("tidyverse", 
                        "RColorBrewer",
                        "shiny",
                        "plotly"
                        )
# check if pkgs are installed already, if not, install automatically:
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos = "http://cran.us.r-project.org")
#Load packages
lapply(list.of.packages, require, character.only = TRUE)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~DATA SETUP~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#Change selection to one based on col position (select from dplyr)
emd_info <- read_tsv(args)
minx <- min(emd_info %>% select(1))
maxx <- max(emd_info %>% select(1))

print(minx, maxx)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

###############################################################################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#~UI~#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
###############################################################################
# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("CyGNAL: EMD heatmap"),

    sidebarPanel(width=4,
        sliderInput("range",
                    "Slider Range:",
                    step = 0.1,
                    min = floor(minx) - 1,
                    max = ceiling(maxx) +1,
                    value = c(minx, maxx)),
        selectInput('in6', 'Select markers', unique(emd_info$marker), multiple=TRUE, selectize=TRUE),
        selectInput('in12', 'Select and reorder conditions', unique(emd_info$file_origin), multiple=TRUE, selectize=TRUE),
        tags$hr(),
        downloadButton('foo', "Download plot as .pdf")
    ),
    mainPanel(width=8,
        plotlyOutput("trendPlot")
    )
)

###############################################################################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#~Server~#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
###############################################################################
# Define server logic required to draw a histogram
server <- function(input, output, session) {

    output$out6 <- renderPrint(input$in6)
    
    output$trendPlot <- renderPlotly({
        if (!is.null(input$in6) & !is.null(input$in12)) {
            data_to_plot <- emd_info %>% filter(marker %in% input$in6) %>% filter(file_origin %in% input$in12)
            data_to_plot$file_origin <- as.factor(data_to_plot$file_origin) %>% fct_relevel(input$in12)
        }
        else if (!is.null(input$in6) & is.null(input$in12)) {
            data_to_plot <- emd_info %>% filter(marker %in% input$in6)
        }
        else if (is.null(input$in6) & !is.null(input$in12)) {
            data_to_plot <- emd_info %>% filter(file_origin %in% input$in12) 
            data_to_plot$file_origin <- as.factor(data_to_plot$file_origin) %>% fct_relevel(input$in12)
        }
        else{data_to_plot <- emd_info}
        
        initial_emd <- data_to_plot %>% ggplot(aes(x=file_origin, y=fct_rev(marker))) + geom_tile(aes(fill=EMD_no_norm_arc))
        print(
        ggplotly(initial_emd + scale_fill_distiller(
            palette = "RdBu", limits=c(input$range[1], input$range[2]),
            #breaks = c(floor(rng[1]), ceiling(rng[2])),
            oob = scales::squish, guide = guide_colourbar(
                nbin=100, draw.ulim = FALSE,
                draw.llim = FALSE, ticks = FALSE)) +
            theme(legend.position="right", legend.direction="vertical", 
                    axis.text.x = element_text(angle = 45, hjust = 1)) + 
            xlab("Condition") + ylab("Markers") +
            ggtitle("EMD scores heatmap")
        ) %>% layout(height = 700, width = 700))
    })
    output$foo <- downloadHandler(
        filename = "emd_heatmap.pdf",
        content = function(file) {
            if (!is.null(input$in6) & !is.null(input$in12)) {
                data_to_plot <- emd_info %>% filter(marker %in% input$in6) %>% filter(file_origin %in% input$in12)
                data_to_plot$file_origin <- as.factor(data_to_plot$file_origin) %>% fct_relevel(input$in12)
            }
            else if (!is.null(input$in6) & is.null(input$in12)) {
                data_to_plot <- emd_info %>% filter(marker %in% input$in6)
            }
            else if (is.null(input$in6) & !is.null(input$in12)) {
                data_to_plot <- emd_info %>% filter(file_origin %in% input$in12) 
                data_to_plot$file_origin <- as.factor(data_to_plot$file_origin) %>% fct_relevel(input$in12)
            }
            else{data_to_plot <- emd_info}
            
            initial_emd <- data_to_plot %>% ggplot(aes(x=file_origin, y=fct_rev(marker))) + geom_tile(aes(fill=EMD_no_norm_arc))
            
            ggsave(file, plot = initial_emd + scale_fill_distiller(
                                palette = "RdBu", limits=c(input$range[1], input$range[2]),
                #breaks = c(floor(rng[1]), ceiling(rng[2])),
                                oob = scales::squish, guide = guide_colourbar(
                                    nbin=100, draw.ulim = FALSE,
                                    draw.llim = FALSE, ticks = FALSE)) +
                            theme(legend.position="right", legend.direction="vertical", 
                                axis.text.x = element_text(angle = 45, hjust = 1)) +  #, aspect.ratio = 1)) +
                            xlab("Condition") + ylab("Markers") +
                    ggtitle("EMD scores heatmap")
            , device = "pdf")
        }
    )
    #session$onSessionEnded(stopApp)
}

# Run the application 
shinyApp(ui = ui, server = server)
