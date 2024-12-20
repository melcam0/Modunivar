if(!nzchar(system.file(package = "shiny"))) install.packages("shiny")
if(!nzchar(system.file(package = "shinydashboard"))) install.packages("shinydashboard")
if(!nzchar(system.file(package = "shinythemes"))) install.packages("shinythemes")
if(!nzchar(system.file(package = "shinyWidgets"))) install.packages("shinyWidgets")
if(!nzchar(system.file(package = "shinyjs"))) install.packages("shinyjs")
if(!nzchar(system.file(package = "lattice"))) install.packages("lattice")
if(!nzchar(system.file(package = "ggplot2"))) install.packages("ggplot2")
if(!nzchar(system.file(package = "ggiraph"))) install.packages("ggiraph")
if(!nzchar(system.file(package = "tools"))) install.packages("tools")
if(!nzchar(system.file(package = "DT"))) install.packages("DT")
if(!nzchar(system.file(package = "RcmdrMisc"))) install.packages("RcmdrMisc")
if(!nzchar(system.file(package = "car"))) install.packages("car")
if(!nzchar(system.file(package = "lmtest"))) install.packages("lmtest")
if(!nzchar(system.file(package = "outliers"))) install.packages("outliers")
if(!nzchar(system.file(package = "MESS"))) install.packages("MESS")
if(!nzchar(system.file(package = "pwr"))) install.packages("pwr")
if(!nzchar(system.file(package = "plotly"))) install.packages("plotly")



library(shiny)
library(shinydashboard)
library(shinythemes)
library(shinyWidgets)
library(shinyjs) 
library(lattice)
library(ggplot2)
library(ggiraph)
library(tools)
library(DT)
library(RcmdrMisc)
library(car)
library(lmtest)
library(outliers)
library(MESS)
library(pwr)
library(plotly)

options(warn = -1)
options(shiny.maxRequestSize = 30 * 1024 ^ 2)




