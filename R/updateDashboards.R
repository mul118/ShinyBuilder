#' Update All Dashboards
#' 
#' @param dashboards a vector of dashboard names.  By default, all dashboards in the dashboards directory are updated
#' @export 
#' @examples
#' \dontrun{
#' #All Dashboards
#' updateDashboards()
#' #Selected dashboards
#' updeateDashboards(c('dashboard_1', 'dashboard_2'))
#' }
updateDashboards <- function(dashboards = NULL){

  sbd_path <- system.file('dashboards', package = 'ShinyBuilder')
  
  #Check/set permissions
  Sys.chmod(sbd_path, mode = "0755")
  
  if(is.null(dashboards)) 
    dashboards <- list.files(path = sbd_path, full.names = T)
  
  db_list <- dbListInit()

  for (dashboard_file in dashboards){
    #Load current dashboard
    load(dashboard_file)
    print(paste0('Updating ', dashboard_file))
    
    #Update chart data
    for (i in 1:length(dashboard_state)){
      if(grepl('gItemPlot', dashboard_state[[i]]$id)){
        input_query               <- dashboard_state[[i]]$query
        db_obj                    <- db_list[[dashboard_state[[i]]$db_name]]
        dashboard_state[[i]]$data <- do.call(db_obj$query_fn, list(db_obj$db, input_query))
      }
    }
    #Save current dashboard
    save(dashboard_state, file = dashboard_file)
  }
}