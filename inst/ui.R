shinyUI(fluidPage(
  
  #Includes
  tags$head(tags$script(src = "//tinymce.cachefly.net/4.0/tinymce.min.js")),
  tags$head(tags$script(src = 'shinyMCE/shiny-tinymce-bindings.js')),
  includeScript(str_c(sb_dir, 'www/shiny-gridster-bindings.js')), 
  includeScript(str_c(sb_dir, 'www/json2.js')),
  tags$head(tags$script(src = "//www.google.com/jsapi")),
  includeScript(str_c(sb_dir, 'www/googleChart_init.js')),

  #Navbar
  div(class="navbar navbar-static-top navbar", 
      div(class = 'navbar-inner',
        span(class = 'brand pull-left', list('Shiny Builder')),
        column(3, selectInput('sel_dashboard', NULL, choices = available_dashboards)),
        #File
        withTags(
          ul(class = "nav",
             li(class = "dropdown",
                a(class="dropdown-toggle", "data-toggle" = "dropdown", 'File', b(class = "caret")),
                ul(class = "dropdown-menu",
                   li(a(id="save_dash_btn", class="action-button shiny-input-bound", icon('floppy-o'), 'Save')),
                   li(class = "divider"),
                   li(a(id="save_as_modal_btn", 'data-toggle' = "modal", 'data-target' = '#save_as_modal', icon('floppy-o'), 'Save As')),
                   li(a(id="new_dash_modal_btn", 'data-toggle' = "modal", 'data-target' = '#new_dash_modal', icon('dashboard'), 'New Dashboard')),
                   li(a(id="delete_dash_modal_btn", class = 'action-button', 'data-toggle' = "modal", 'data-target' = '#delete_modal', icon('trash-o'), 'Delete Dashboard'))
                )
             )
          )),

          #Edit
          withTags(
            ul(class = "nav",
             li(class = "dropdown",
                a(class="dropdown-toggle", "data-toggle" = "dropdown", 'Edit', b(class = "caret")),
                ul(class = "dropdown-menu",
                   li(a(id="addChart", class="action-button shiny-input-bound", icon('bar-chart-o'), 'Add Chart')),
                   li(a(id="addText", class="action-button shiny-input-bound", icon('bars'), 'Add Text Area'))
                )
             )
          ))

      )
      
  ),

  #Gridster frame
  br(),
  fluidRow(gridster(id = 'gridster_frame', marginx = 10, marginy = 10, width = 100, height = 50)),
  hr(), 
  
  #'Delete' modal
  div(id = 'delete_modal', class = 'modal hide',
      div(class = 'modal-header',
          tags$div(class = 'button', class = 'close', 'data-dismiss' = 'modal', 'aria-hidden'='true', 'x'),
          h3('Confirm Deletion')),
      div(class = 'modal-body',
          p('Are you sure you want to delete this dashboard?  This operation cannot be undone.')),
      div(class = 'modal-footer',
          HTML('<button type="button" data-dismiss="modal" class="btn">Cancel</button>
               <button type="button" data-dismiss="modal" class="btn btn-primary action-button" id="delete_dash_btn">Delete Dashboard</button>')) 
  ),
  
  #'New Dashboard' Modal
  div(id = 'new_dash_modal', class = 'modal hide', 
      div(class = 'modal-header', tags$div(class = 'button', class = 'close', 'data-dismiss' = 'modal', 'aria-hidden'='true', 'x'), h3('New Dashboard')),
      div(class = 'modal-body', 
          p('Enter a new dashboard title:'), 
          textInput('new_dash_file_name', label = NULL, value = '')
      ),
      div(class = 'modal-footer',
          HTML('<button type="button" data-dismiss="modal" class="btn">Close</button>
                  <button type="button" data-dismiss="modal" class="btn btn-primary action-button" id="new_dash_btn">Create Dashboard</button>')
      )
  ),

  #'Save As' Modal
  div(id = 'save_as_modal', class = 'modal hide', 
      div(class = 'modal-header', tags$div(class = 'button', class = 'close', 'data-dismiss' = 'modal', 'aria-hidden'='true', 'x'), h3('Save As')),
      div(class = 'modal-body', 
          p('Enter a new dashboard title:'), 
          textInput('save_as_file_name', label = NULL, value = '')
          ),
      div(class = 'modal-footer',
          HTML('<button type="button" data-dismiss="modal" class="btn">Close</button>
                  <button type="button" data-dismiss="modal" class="btn btn-primary action-button" id="save_as_dash_btn">Save Dashboard</button>')
      )
  ),
          
  
  #Query Editor Modal
  div(id = 'full-width', class = 'modal container hide', style = 'width: 100%; margin: auto; left: 0', tabindex = '-1',
      div(class = 'modal-header',
          HTML('<button type="button" class="close" data-dismiss="modal" aria-hidden="true">x</button>'),
          fluidRow(column(6,h3('Edit Query')), column(5,h3('Table Preview')))
      ),
    div(class = 'modal-body',
          fluidRow(
            column(6, aceEditor("code", 
                                mode="sql", 
                                height = "300px",
                                value=''
            ),
           HTML('<button class="btn btn-primary action-button shiny-bound-input" id="update_preview">Update Preview</button>'),
           selectInput('selected_db', label = NULL, choices = names(db_list)), 
           tags$input(id = 'active_chart_id', type = 'text', value = '', class = 'shiny-bound-input', style = 'visibility: hidden; z-index: -1')
           ),
            column(6, dataTableOutput("output_tbl"))
          )
     ),
    div(class = 'modal-footer',
           HTML('<button type="button" data-dismiss="modal" class="btn">Cancel</button>
                  <button type="button" data-dismiss="modal" class="btn btn-primary action-button" id="save_changes">Save Query</button>')
      )
  ),  
  
  #Main Stylesheet
  includeCSS(str_c(sb_dir, '/www/main.css'))
))
