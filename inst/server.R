#-----------
#Static Data
#-----------
#HTML templates
remove_btn      <- HTML('<button type="button" class="close deleteme" aria-hidden="true">x</button>')
edit_qry_btn    <- tags$div(class="btn", 'data-toggle'="modal", 'data-target'="#full-width", 'Edit Query')
inline_opts     <- 'inline: true, 
        plugins: ["advlist autolink lists link image charmap print preview anchor",
                  "searchreplace visualblocks code fullscreen",
                  "insertdatetime media table contextmenu paste"],
        toolbar: "insertfile undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image"'        


#Default data
default_db_name   <- names(db_list)[1]
default_db_obj    <- db_list[[default_db_name]]
default_query     <- default_db_obj$default_query
default_data      <- do.call(default_db_obj$query_fn, list(default_db_obj$db, default_query))
curr_result_tbl   <- default_data
default_dashboard <- 'Sample Dashboard'


#-----------------------
#Shiny Server Definition
#-----------------------
shinyServer(function(input, output, session) {

  #Initialization constants
  first_time            <- 1
  update_preview_val    <- 0
  save_changes_val      <- 0
  
  #Determine Available dashboards
  available_dashboards  <- reactive({invalidateLater(1000*30, session); str_replace(list.files(str_c(sb_dir, 'dashboards/')), '.RData', '')})
  
  #Determine selected dashboard from url
  selected_dashboard <- reactive({
    url_query <- parseQueryString(session$clientData$url_search)
    selected_dashboard <- default_dashboard
    if (length(url_query) > 0 )
      if(url_query[[1]] %in% isolate(available_dashboards()))
        selected_dashboard <- url_query[[1]]
    selected_dashboard
  })
  
  #Handle dashboard switch event
  observe({
    if(input$sel_dashboard != selected_dashboard() & first_time == 0){
      session$sendCustomMessage(type = "shiny.go_to_url", list(url = isolate(input$sel_dashboard)))
    }
  })
  
  #Handle dashboard delete event
  observe({
    if(input$delete_dash_btn > 0){
      if(isolate(selected_dashboard()) != default_dashboard){
        file.remove(str_c(sb_dir, 'dashboards/', isolate(selected_dashboard()),'.RData')) 
        session$sendCustomMessage(type = "shiny.go_to_url", list(url = default_dashboard))
      }
    }
  })
    
  #Available dashboards
  observe({
    invalidateLater(1000*30, session) #Update once every 30 sec
    updateSelectInput(session, 'sel_dashboard', choices = available_dashboards(), selected = selected_dashboard())
    first_time <<-0
  })
  
  
  #Initialize core data stores
  widget_counts <- reactiveValues(num_charts = 0, num_textareas = 0)
  input_dbs     <- reactiveValues()
  input_queries <- reactiveValues()
  input_data    <- reactiveValues()
  last_update   <- reactiveValues()
    
  #Selected Database
  selected_db       <- reactive({db_list[[input$selected_db]]$db})
  selected_query_fn   <- reactive({db_list[[input$selected_db]]$query_fn})
  
  #Save Query Button
  observe({
    if(input$save_changes > 0){
      isolate({
        new_input_data <- try(do.call(selected_query_fn(), list(selected_db(), input$code)))
        
        if(is.data.frame(new_input_data)){                    
          chart_id                  <- input$active_chart_id
          input_dbs[[chart_id]]     <- input$selected_db
          input_queries[[chart_id]] <- input$code
          input_data[[chart_id]]    <- new_input_data
          last_update[[chart_id]]   <- Sys.time()
        }
      })
    }
  }) 
  
  #Current Results Table
  curr_result_tbl <- reactive({
    active_chart_id <- input$active_chart_id
    if(active_chart_id != ''){
      if(input$update_preview > update_preview_val){ 
        #If change comes from 'Update Preview'
        update_preview_val     <<- input$update_preview
        return(isolate(do.call(selected_query_fn(), list(selected_db(), input$code))))
      }
      else{ #If change comes from switching active tile
        return(input_data[[active_chart_id]])
      }
    }else{
      return(data.frame(i = 1))
    }
    
  })
  
  #Result Table
  output$output_tbl <- renderDataTable(curr_result_tbl(), options = list(iDisplayLength = 5))
  
  #Code Editor/Selected DB Observer
  observe({
    active_chart_id <- input$active_chart_id
    if(active_chart_id != ''){
      updateAceEditor(session, 'code', value=isolate(input_queries[[active_chart_id]]))
      updateSelectInput(session, 'selected_db', label = NULL, choices = names(db_list), selected = input_dbs[[active_chart_id]])
    }
  })
  
  
  #Add Chart Widget Function
  chartWidget <- function (chart_id, chart_type, chart_opts){ 
    isolate({
    charteditor_id <- str_c(chart_id, '_editor')
    
    #Query Editor Button
    edit_qry_btn    <- tags$div(class="qry btn", 'style'="display:inline;", 'data-toggle'="modal", 'data-target'="#full-width", 'chart-id'= chart_id, title = 'Edit Query', icon('pencil-square-o'),'Query')
    
    #Chart
    output[[chart_id]] <- renderGoogleChart({ 
      googleChartObject(
        data = input_data[[chart_id]], 
        type = input[[charteditor_id]]$chartType, 
        options = input[[charteditor_id]]$options)
    })
    
    #Widget content
    widget_id   <- str_c('w_', chart_id)
    widget_html <- paste0(tags$li(
      class = 'new',
      id = widget_id, 
      remove_btn, 
      edit_qry_btn, 
      googleChartEditor(charteditor_id, chart_id, chart_type, chart_opts, paste0(icon('pencil-square-o'), ' Chart ')),
      fluidRow(googleChartOutput(chart_id), style = 'height : 100%;')
    ))
    })
    return(widget_html)
  }
  
  #Chart Initialization Observer
  observe({ #Take dependence on addChart button 
    if(input$addChart > 0){
    #Increment num charts
    widget_counts$num_charts <- isolate(widget_counts$num_charts) + 1
    num_charts <- isolate(widget_counts$num_charts)  
    
      chart_id                  <- str_c('gItemPlot', num_charts)
      input_dbs[[chart_id]]     <- default_db_name
      input_queries[[chart_id]] <- default_query
      input_data[[chart_id]]    <- default_data
      
      widget_html <- chartWidget(chart_id, 'Table', '{}')
      dataList <- list(id = 'gridster_frame', html = widget_html)
      dataList$size_x <- 2
      dataList$size_y <- 4
      session$sendCustomMessage("shinyGridster.add_widget", dataList) 
    
    }
  })  
  
  #Text Area Initialization Observer
  observe({#Take dependence on addText Button
    if(input$addText > 0){  
      widget_counts$num_textareas <- isolate(widget_counts$num_textareas) + 1
      num_textareas     <- isolate(widget_counts$num_textareas)
      #print(str_c('Num text areas: ', num_textareas))
      
      if(num_textareas > 0){
        textarea_id     <- str_c('textArea', num_textareas)
        widget_id       <- str_c('w_', textarea_id)
        text_area_tmpl  <- tinyMCE(textarea_id, 'Click to edit text.', inline_opts)
        widget_html     <- paste0(tags$li(class = 'new', id = widget_id, remove_btn, p('.', style = 'color: transparent'), text_area_tmpl))
        
        dataList        <- list(id = 'gridster_frame', html = widget_html)
        dataList$size_x <- 2
        dataList$size_y <- 4
        session$sendCustomMessage("shinyGridster.add_widget", dataList)
      }
    }
  })

  
  #Save dashboard function
  saveDashBoard <- function(dashboard_title){
      isolate({     
        #Initialize/populate dashboard state object
        dashboard_state <- fromJSON(input$gridster_frame)
        #print('====Raw Object====') print(dashboard_state)

        #Save widgets
        for (i in 1:length(dashboard_state)){
          widget_id <- dashboard_state[[i]]$id
          if(str_detect(widget_id, 'gItemPlot')){
            chart_id                          <- str_replace(widget_id, 'w_','')
            charteditor_id                    <- str_c(chart_id,'_editor')
            dashboard_state[[i]]$db_name      <- input_dbs[[chart_id]]
            dashboard_state[[i]]$query        <- input_queries[[chart_id]]
            dashboard_state[[i]]$data         <- input_data[[chart_id]]
            dashboard_state[[i]]$last_update  <- last_update[[chart_id]]
            dashboard_state[[i]]$chart_type   <- input[[charteditor_id]]$chartType
            dashboard_state[[i]]$chart_opts   <- input[[charteditor_id]]$options
          }
          else if(str_detect(widget_id, 'textArea')){
            textarea_id     <- str_replace(widget_id, 'w_','')
            dashboard_state[[i]]$content <-  input[[textarea_id]]
          }
          else{
            print('Unknown widget')
          }  
        }
        #Save dashboard state
        save(list = c('dashboard_state'), file = str_c(sb_dir, 'dashboards/', dashboard_title, '.RData'))
        #print('====Saved Object===='); print(dashboard_state)
      })
    }
  
  #Save/Save As Observers
  observe({
    if(input$save_dash_btn > 0) 
      saveDashBoard(selected_dashboard())
  })
  observe({  
    if(input$save_as_dash_btn > 0) {
      dashboard_title <- isolate(input$save_as_file_name)
      saveDashBoard(dashboard_title)
      new_available_dashboards  <- str_replace(list.files(str_c(sb_dir, 'dashboards/')), '.RData', '')
      selected_dashboard        <- dashboard_title
      updateSelectInput(session, 'sel_dashboard', choices = new_available_dashboards, selected = dashboard_title) 
    }
  })
  #New Dash Observer
  observe({  
    if(input$new_dash_btn > 0) {
      dashboard_title           <- isolate(input$new_dash_file_name)
      file.copy(str_c(sb_dir, 'data/empty_dash.RData'), str_c(sb_dir, 'dashboards/', dashboard_title, '.RData'))
      new_available_dashboards  <- str_replace(list.files(str_c(sb_dir, 'dashboards/')), '.RData', '')
      selected_dashboard        <- dashboard_title
      updateSelectInput(session, 'sel_dashboard', choices = new_available_dashboards, selected = dashboard_title) 
    }
  })

  
  #Load dash observer
  observe({
        #Load data
        load(file = str_c(sb_dir, 'dashboards/', selected_dashboard(), '.RData'))
        #print('====Loaded Object====')print(dashboard_state)
        
        #Load widgets
        for (i in 1:length(dashboard_state)){
          if(str_detect(dashboard_state[[i]]$id, 'gItemPlot')){
            widget_counts$num_charts <- isolate(widget_counts$num_charts) + 1
            num_charts      <- isolate(widget_counts$num_charts)
            chart_id        <- str_c('gItemPlot', num_charts)
            widget_id       <- str_c('w_', chart_id)
            
            chart_type                <- dashboard_state[[i]]$chart_type
            chart_opts                <- dashboard_state[[i]]$chart_opts
            input_dbs[[chart_id]]     <- dashboard_state[[i]]$db_name
            input_queries[[chart_id]] <- dashboard_state[[i]]$query
            input_data[[chart_id]]    <- dashboard_state[[i]]$data
            last_update[[chart_id]]   <- dashboard_state[[i]]$last_update
            widget_html               <- chartWidget(chart_id, chart_type, chart_opts)          
          }
          else if(str_detect(dashboard_state[[i]]$id, 'textArea')){
            widget_counts$num_textareas <- isolate(widget_counts$num_textareas) + 1
            num_textareas   <- isolate(widget_counts$num_textareas)
            textarea_id     <- str_c('textArea', num_textareas)
            widget_id       <- str_c('w_', textarea_id)
            
            widget_content  <- tinyMCE(textarea_id, HTML(dashboard_state[[i]]$content), inline_opts)
            widget_html     <- paste0(tags$li(class = 'new', id = widget_id, remove_btn, p('.', style = 'color: transparent'), widget_content))     
          }
          else{
            print('Unknown widget')
          }
          
          #Build parameter list for widget
          dataList <- list(id = 'gridster_frame',
                           col = dashboard_state[[i]]$row,
                           row = dashboard_state[[i]]$col,
                           size_x = dashboard_state[[i]]$size_x,
                           size_y = dashboard_state[[i]]$size_y,
                           html = widget_html)

          #Add widget
          session$sendCustomMessage(type = "shinyGridster.add_widget", dataList)
          
       }
  })
})



