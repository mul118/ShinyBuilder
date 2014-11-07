.onLoad <- function(libname, pkgname) {
  require(shiny)
  require(RJSONIO)
  addResourcePath("ShinyBuilder", system.file("www", package = "ShinyBuilder"))
}

.onAttach <- function(libname, pkgname) {
  require(shiny)    
} 