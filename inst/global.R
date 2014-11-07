#---------
#Libraries
#---------
library(stringr)
library(googleVis)
#library(RJDBC)
library(RJSONIO)
library(RSQLite)
library(shinyAce)
library(shinyMCE)
library(shinyGridster)
library(ShinyBuilder)

source(system.file('googleChart.R', package = 'ShinyBuilder'))

#DB list
db_list <- dbListInit()

#Shinybuilder directory
sb_dir <- system.file('', package = 'ShinyBuilder')

#Available dashboards
available_dashboards <- str_replace(list.files(path = str_c(sb_dir,'dashboards')), '.RData', '')



