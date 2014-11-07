#' Initialize connections in db list
#' 
#' Load db list from file, initializing connections to all included databases.
#' @return an initialized db_list object
#' @examples
#' \dontrun{db_list <- dbListInit()}
#' @export
dbListInit <- function(){
  sb_dir <- system.file(package = 'ShinyBuilder')
  load(file = paste0(sb_dir,'/data/db_list.RData'))
  lapply(db_list, function(x){x$db <- eval(x$db); x})
}

#' Add new database to db list
#' 
#' Adds a new database to db list.
#' @param db_name name of the database to be added
#' @param db an expression yielding a db connection object
#' @param query_fn function used to query the database. 
#' @param default_query the default query to use for this connection.  
#' @examples
#' \dontrun{
#' db <- quote({dbConnect(dbDriver('SQLite'), dbname = system.file('data/births.db', package = 'ShinyBuilder'))})
#' dbListAdd(db_name = 'SQLite Database', db = db, query_fn = RJDBC::dbGetQuery, default_query = 'SELECT * FROM births')}
#' @export
dbListAdd <- function(db_name, db, query_fn, default_query){
  sb_dir <- system.file(package = 'ShinyBuilder')
  load(file = paste0(sb_dir, '/data/db_list.RData'))
  db_list[[db_name]] <- list(
    db = db,
    query_fn = query_fn,
    default_query = default_query)
  save(db_list, file = paste0(sb_dir,'/data/db_list.RData'))
}

#' Remove a database from db list
#' 
#' Removes a database from db_list.
#' @param db_name name of the database to be removed
#' @export
dbListRemove <- function(db_name){
  sb_dir <- system.file(package = 'ShinyBuilder')
  load(file = paste0(sb_dir, '/data/db_list.RData'))
  db_list[[db_name]] <- NULL
  save(db_list, file = paste0(sb_dir,'/data/db_list.RData'))
}

#' Print the current contents of db list
#' 
#' Print the current contents of db list.
#' @export
dbListPrint <- function(){
  sb_dir <- system.file(package = 'ShinyBuilder')
  load(file = paste0(sb_dir, '/data/db_list.RData'))
  print(db_list)
}

#Code to Initialize sample_db
# births    <- read.csv(paste0(getwd(),'/data/births.csv'))
# sample_db <- dbConnect(dbDriver('SQLite'), dbname = paste0(getwd(),'/data/births.db'))
# dbWriteTable(sample_db, 'births', births)
# dbGetQuery(sample_db, 'SELECT * FROM births LIMIT 5')
# dbDisconnect(sample_db)
