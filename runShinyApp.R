.libPaths("./R-Portable/App/R-Portable/library")
## the path to portable chrome (da usare se ci sara bisogno in futuro)
# browser.path = file.path(getwd(),"GoogleChromePortable/GoogleChromePortable.exe")
# options(browser = browser.path)
# shiny::runApp("./Shiny/",port=8888,launch.browser=TRUE)
## al momento usiamo browser predefinito
shiny::runApp("./Shiny/",launch.browser=TRUE)