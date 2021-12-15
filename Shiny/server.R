rm(list = ls())

server <- function (input , output, session ){
  
  observeEvent(input$openModal, {
    showModal(
      modalDialog(title = "Autori:",size = 's',easyClose = TRUE,footer = NULL,
                  
                  tags$img(src = base64enc::dataURI(file = "GC.jpg", mime = "image/jpg")),
                  
                  
                  HTML((paste(" "," ","Giorgio Marrubini","email: giorgio.marrubini@unipv.it"," ",
                              'Camillo Melzi','email: camillomelzi@gmail.com',sep="<br/>"))))
    )
  })
  
  observeEvent(input$quit,{
    stopApp()
  })

  if (!interactive()) {
    session$onSessionEnded(function() {
      stopApp()
      q("no")
    })
  }
 
  observeEvent(input$reset,{
    dati$DS<-NULL
    dati$DS_nr=NULL
    dati$DS_righe=NULL
    dati$nr=NULL
    dati$var=NULL
    dati$var_nr=NULL
    dati$var_qt=NULL
    dati$var_ql=NULL
    dati$righe=NULL
    dati$righe_rest=NULL
    dati$righe_tolte=NULL
    dati$var_gr=NULL
    graf$xlim=NULL
    graf$xylim=NULL
    graf$xvar_gr=NULL
    graf$xgr=NULL

    reset("lista_esempi")
    reset("file_xlsx")
    reset("file_csv")
  })
  

# reactiveValues ----------------------------------------------------------
  
  dati<-reactiveValues(DS=NULL,DS_nr=NULL,DS_righe=NULL,nr=NULL,var=NULL,var_nr=NULL,
                       var_qt=NULL,var_ql=NULL,righe=NULL,righe_rest=NULL,righe_tolte=NULL,
                       var_gr=NULL)
  
  graf<-reactiveValues(xlim=NULL,ylim=NULL,var_gr=NULL,gr=NULL)


# carica dati -------------------------------------------------------------

  output$lista_esempi<-renderUI({
    fnames<-list.files(path = 'Dati')
    fext<-tools::file_ext(fnames)
    fnames<-fnames[fext %in% c("xlsx")]
    fnames<-tools::file_path_sans_ext(fnames)
    selectInput('lista_esempi',"",choices = c('',fnames),selected = 1)
  })

  observeEvent(input$lista_esempi,{
    if(input$lista_esempi!=""){
      tryCatch({
      require(readxl)
      path<-paste("Dati/",input$lista_esempi,".xlsx",sep="")
      df=read_excel(path = path,sheet = 1,col_names = TRUE)
      dati$DS<-as.data.frame(df)
      dati$DS_nr<-as.data.frame(df)
      dati$DS_righe<-as.data.frame(df)
      dati$righe<-row.names(df)
      dati$righe_rest<-row.names(df)
      dati$var<-colnames(df)
      dati$var_nr<-colnames(df)
      dati$var_qt<-colnames(df)},
      error = function(e) {
        stop(safeError(e))
      }
    )
    } else {
      dati$DS<-NULL
      dati$DS_nr=NULL
      dati$DS_righe=NULL
      dati$var=NULL
      dati$var_nr=NULL
      dati$var_qt=NULL
      dati$var_ql=NULL
      dati$righe=NULL
      dati$righe_rest=NULL
    }
  })
  
 output$dati_esempio <- renderTable({
    req(input$lista_esempi)
    if(input$esempi_hd == "head") {
      return(head(dati$DS))
    }
    else {
      return(dati$DS)
    }
  })
  
  observeEvent(input$file_xlsx,{
    tryCatch({
      require(readxl)
      df=read_excel(path = input$file_xlsx$datapath,sheet = input$foglio_n,col_names = input$header)
      dati$DS<-as.data.frame(df)
      dati$DS_nr<-as.data.frame(df)
      dati$DS_righe<-as.data.frame(df)
      dati$righe<-row.names(df)
      dati$righe_rest<-row.names(df)
      dati$var_nr<-colnames(df)
      dati$var<-colnames(df)
      dati$var_qt<-colnames(df)},
      error = function(e) {
        stop(safeError(e))
      }
    )
  })
  
  output$contents_xlsx <- renderTable({
    req(input$file_xlsx)
    
    if(input$disp_xlx == "head") {
      return(head(dati$DS))
    }
    else {
      return(dati$DS)
    }
  })
    
  observeEvent(input$file_csv,{
    tryCatch({
      df <- read.csv(input$file_csv$datapath,
                     header = input$header,
                     sep = input$sep,
                     quote = input$quote)
      dati$DS<-as.data.frame(df)
      dati$DS_nr<-as.data.frame(df)
      dati$DS_righe<-as.data.frame(df)
      dati$righe<-row.names(df)
      dati$righe_rest<-row.names(df)
      dati$var<-colnames(df)
      dati$var_nr<-colnames(df)
      dati$var_qt<-colnames(df)},
      error = function(e) {
        stop(safeError(e))
      }
    )
  })
  
  output$contents_csv <- renderTable({
    req(input$file_csv)
    if(input$disp_csv == "head") {
      return(head(dati$DS))
    }
    else {
      return(dati$DS)
    }
  })
  
  observeEvent(input$file_incolla,{
      df<-tryCatch(read.DIF(file = "clipboard",header = TRUE,transpose = TRUE),
                   error = function(e) "Selezionare un dataset!")
      df <- type.convert(df)
      dati$DS<-as.data.frame(df)
      dati$DS_nr<-as.data.frame(df)
      dati$DS_righe<-as.data.frame(df)
      dati$righe<-row.names(df)
      dati$righe_rest<-row.names(df)
      dati$var<-colnames(df)
      dati$var_nr<-colnames(df)
      dati$var_qt<-colnames(df)
    })
  
  output$contents_incolla <- renderTable({
    validate(need(input$file_incolla>0,""))
    req(input$file_incolla)
    req(!is.null(dati$DS))
    # if(!dati$DS=="Selezionare un dataset!"){
      if(input$disp_incolla == "head") {
        return(head(dati$DS))
      }
      else {
        return(dati$DS)
      }
    # }
 
  })
  

# dati caricati -----------------------------------------------------------
  
  output$dati<-DT::renderDataTable(rownames=TRUE,extensions = 'ColReorder',
                                   options = list(
                                     autoWidth = TRUE,
                                     columnDefs = list(list(width = '100px', targets = "_all")),
                                     colReorder = TRUE),
                                   class = 'cell-border stripe',
                                   # filter = 'bottom',
                                   {
    validate(need(nrow(dati$DS)!=0,""))
    #if(length(dati$nr)==0){
      dati$DS
   # } else {
    #  dati$DS_nr[!dati$righe%in%dati$righe_tolte,]}
      })

# variabili qualitative ---------------------------------------------------
  
  output$var_quali<-renderUI({
    checkboxGroupInput(inputId = "var_ql",label = "seleziona le variabili qualitative - fattori",
                       choices = dati$var,selected =dati$var_ql)
  })
  
  observeEvent(input$var_ql,ignoreNULL = FALSE,{
    dati$var_ql<-input$var_ql
    dati$var_qt<-dati$var[!dati$var%in%input$var_ql]
  })
  
  output$var_quanti <- renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    if(!length(dati$var_qt)==0){
      dati$var_qt
    }else{
      "Non ci sono variabili quantitative"
    }
  })
  

# variabile nomi righe ---------------------------------------------------

  output$var_nomi<-renderUI({
    selectizeInput(inputId = "var_nr"," ",
                       choices = dati$var_nr,
                   options = list(
                     placeholder = 'Selezione eventuale colonna nomi righe',
                     onInitialize = I('function() { this.setValue(""); }')
                   ))
  })
  
  observeEvent(input$var_nr,ignoreNULL = FALSE,{
    req(input$var_nr)
    if(length(input$var_nr)!=0){
      dati$col_nr<-input$var_n
      dati$DS<-as.data.frame(dati$DS_nr[,!dati$var_nr%in%input$var_nr])
      if(length(dati$var_nr)==2) names(dati$DS)<-dati$var_nr[input$var_nr!=dati$var_nr]
      dati$DS_righe<-as.data.frame(dati$DS_nr[,!dati$var_nr%in%input$var_nr])
      dati$nr<-dati$DS_nr[,dati$var_nr%in%input$var_nr]
      row.names(dati$DS)<-dati$nr
      dati$var<-colnames(dati$DS)
      dati$var_qt<-colnames(dati$DS)
      dati$righe<-dati$DS_nr[,dati$var_nr%in%input$var_nr]
    } else {
      dati$DS<-dati$DS_nr
      dati$nr<-NULL
      dati$var<-colnames(dati$DS)
      dati$var_qt<-colnames(dati$DS)
      dati$righe<-row.names(dati$DS)
    }
     
    })
  
  output$nomi_righe<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    if(length(dati$nr)==0){
      "Non c'è colonna nomi righe "
    } else {
      dati$nr
      }
    })
  
  
# summary -----------------------------------------------------------------
  
  output$var_gruppo<-renderUI({
    checkboxGroupInput(inputId = "var_gr",label = "seleziona i fattori",
                       choices = dati$var_ql,selected =dati$var_gr)
  })
  
  observeEvent(input$var_gr,ignoreNULL = FALSE,{
    dati$var_gr<-input$var_gr
  })
  
  output$sum_dati <- renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    tryCatch({
      if(length(dati$var_gr)==0){
        RcmdrMisc::numSummary(dati$DS[,dati$var_qt])
      } else if (length(dati$var_gr)==1){
        RcmdrMisc::numSummary(dati$DS[,dati$var_qt],groups =dati$DS[,dati$var_gr])
      } else if (length(dati$var_gr)==2){
        RcmdrMisc::numSummary(dati$DS[,dati$var_qt],
                              groups =interaction(dati$DS[,dati$var_gr[1]],dati$DS[,dati$var_gr[2]], sep = ":"))
      } else if (length(dati$var_gr)==3){
        RcmdrMisc::numSummary(dati$DS[,dati$var_qt],
                              groups =interaction(dati$DS[,dati$var_gr[1]],dati$DS[,dati$var_gr[2]],dati$DS[,dati$var_gr[3]], sep = ":"))
      } else if (length(dati$var_gr)>3){
        print("Massimo 3 gruppi")
      } 
    },
    error = function(e) {
      print("selezionare le variabili qualitative")
    })
  })
  
 

# oggetti  ------------------------------------------------
  
  output$righe_tolte<-renderUI({
    checkboxGroupInput(inputId = "righe_tolte",label = "seleziona le righe da cancellare",
                       choices = dati$righe,selected =dati$righe_tolte)
  })
  
  observeEvent(input$righe_tolte,ignoreNULL = FALSE,{
    if(length(input$righe_tolte)!=0){
      dati$righe_tolte<-input$righe_tolte
      dati$righe_rest<-dati$righe[!dati$righe%in%input$righe_tolte] 
      dati$DS<-as.data.frame(dati$DS_righe[dati$righe%in%dati$righe_rest,])
      colnames(dati$DS)<-colnames(dati$DS_righe)
      row.names(dati$DS)<-dati$righe_rest
    } else {
      dati$DS<-dati$DS_righe
      dati$righe_tolte<-NULL
      dati$righe_rest<-dati$righe
    }
  })
  
  output$righe_restanti <- renderPrint({
    if(!length(dati$righe_tolte)==0){
      dati$righe_tolte
    }else{
     "Non ci sono righe cancellate"
    }
  })
  
  observeEvent(input$desel_righe,{
    dati$DS<-dati$DS_righe
    dati$righe_tolte<-NULL
    dati$righe_rest<-dati$righe
  })
 

# grafico dispersione -----------------------------------------------------------

  output$graf_disp_var<-renderUI({
    selectizeInput(inputId = "graf_disp_var"," ",
                   choices = dati$var_qt)})

  output$graf_disp_var_gr<-renderUI({
    req(dati$var_ql)
    checkboxGroupInput(inputId = "graf_disp_var_gr",label = "seleziona i fattori",
                       choices = dati$var_ql,selected =dati$var_gr)
  })
  
  observeEvent(input$graf_disp_var_gr,ignoreNULL = FALSE,{
    graf$var_gr<-input$graf_disp_var_gr
    if(is.null(input$graf_disp_var_gr)){
      graf$gr<-NULL
    } else {
      graf$gr<-input$graf_disp_gr
    }
  })
  
  observeEvent(input$graf_disp_dblclick, {
    brush <- input$graf_disp_brush
    if (!is.null(brush)) {
      graf$xlim <- c(brush$xmin, brush$xmax)
      graf$ylim <- c(brush$ymin, brush$ymax)
    } else {
      graf$xlim <- NULL
      graf$ylim <- NULL
    }
  })
  
  output$graf_disp_gr<-renderUI({
    req(input$graf_disp_var_gr)
    req(graf$var_gr)
    if(length(graf$var_gr)==1){
      checkboxGroupInput(inputId = "graf_disp_gr",label = "deseleziona i livelli che non interessano",
                         choices = unique(dati$DS[,input$graf_disp_var_gr]),selected =unique(dati$DS[,input$graf_disp_var_gr]))
    } else if (length(graf$var_gr)==2){
      lv<-unique(interaction(dati$DS[,input$graf_disp_var_gr[1]],dati$DS[,input$graf_disp_var_gr[2]]))
      checkboxGroupInput(inputId = "graf_disp_gr",label = "deseleziona i livelli che non interessano",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)==3){
      lv<-unique(interaction(dati$DS[,input$graf_disp_var_gr[1]],dati$DS[,input$graf_disp_var_gr[2]],dati$DS[,input$graf_disp_var_gr[3]]))
      checkboxGroupInput(inputId = "graf_disp_gr",label = "deseleziona i livelli che non interessano",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)>3){
      print("Massimo 3 fattori")}
  })
  
  observeEvent(input$graf_disp_gr,ignoreNULL = FALSE,{
    graf$gr<-input$graf_disp_gr
  })

  output$graf_disp<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$graf_disp_var%in%colnames(dati$DS))
    df<-cbind.data.frame(dati$DS[,input$graf_disp_var,drop=FALSE],c(1:length(dati$DS[,input$graf_disp_var])))
    colnames(df)<-c("y","indice")
    if(!is.null(graf$var_gr)){
      if (length(graf$var_gr)==1){
        lab<-as.factor(dati$DS[,input$graf_disp_var_gr])
      } else if (length(graf$var_gr)==2){
        lab<-as.factor(interaction(dati$DS[,input$graf_disp_var_gr[1]],dati$DS[,input$graf_disp_var_gr[2]]))
      } else if (length(graf$var_gr)==3){
        lab<-as.factor(interaction(dati$DS[,input$graf_disp_var_gr[1]],dati$DS[,input$graf_disp_var_gr[2]],dati$DS[,input$graf_disp_var_gr[3]]))
      }
    } else {
      lab<-rep("0",nrow(df))
    }
    df<-cbind.data.frame(df,gruppo=lab)
    row.names(df)<-row.names(dati$DS)
    gr<-ggplot(df,mapping = aes(x=indice,y=y))+labs(x="indice",y=input$graf_disp_var)+
      theme_light()+ coord_cartesian(xlim = graf$xlim, ylim = graf$ylim, expand = TRUE)
    if(is.null(graf$gr)){
      if(!input$graf_disp_labels){
        gr<-gr+geom_point(cex=2,col="blue")
        gr+geom_hline(yintercept = mean(df$y),col="blue",lty=2)
      } else {
        gr<-gr+geom_text(mapping = aes(label=row.names(df)),col="blue")
        gr+geom_hline(yintercept = mean(df$y),col="blue",lty=2)
      }
    } else {
      if(!input$graf_disp_labels){
        gr<-gr+geom_point(cex=2,mapping = aes(colour=gruppo))
        gr<-gr%+%subset(df,df$gruppo%in%graf$gr)
        gr+geom_hline(yintercept = mean(df$y[df$gruppo%in%graf$gr]),col="blue",lty=2)
      } else {
        gr<-gr%+%subset(df,df$gruppo%in%graf$gr)
        gr<-gr+geom_text(mapping = aes(label=row.names(subset(df,df$gruppo%in%graf$gr)),colour=gruppo))
        gr+geom_hline(yintercept = mean(df$y[df$gruppo%in%graf$gr]),col="blue",lty=2)
      }
    }
  })
  
  observeEvent(input$graf_disp_canc_brush,ignoreNULL = FALSE, {
    req(input$graf_disp_brush)
    brush <- input$graf_disp_brush
    y<-dati$DS[,input$graf_disp_var]
    nr<-length(y)
    cr<-which(y>brush$ymin & y<brush$ymax & c(1:nr) >brush$xmin & c(1:nr) < brush$xmax)
    df<-dati$DS
    righe<-row.names(df)
    righe_tolte<-righe[cr]
    righe_rest<-righe[!cr]
    dati$righe_tolte<-c(righe_tolte,dati$righe_tolte)
    dati$righe_rest<-righe[!righe%in%dati$righe_tolte]
    dati$DS<-as.data.frame(dati$DS[dati$righe_rest, , drop = FALSE])
   # if(length(dati$var_nr)==2) {
   #   names(dati$DS)<-dati$var_nr[input$var_nr!=dati$var_nr]
   # } else {
    colnames(dati$DS)<-colnames(dati$DS_righe)
   # }
    row.names(dati$DS)<-dati$righe_rest
    })
  
  observeEvent(input$graf_disp_ripr_brush,ignoreNULL = FALSE, {
    dati$righe_tolte=NULL
    dati$righe_rest<-dati$righe
    dati$DS<-dati$DS_righe
   # if(length(dati$var_nr)==2) names(dati$DS)<-dati$var_nr[input$var_nr!=dati$var_nr]
  })
  output$graf_disp_selez<-renderPrint({
    req(input$graf_disp_brush)
    brush <- input$graf_disp_brush
    y<-dati$DS[,input$graf_disp_var]
    nr<-length(y)
    cr<-which(y>brush$ymin & y<brush$ymax & c(1:nr) >brush$xmin & c(1:nr) < brush$xmax)
    df<-as.data.frame(dati$DS[cr,])
    colnames(df)<-colnames(dati$DS)
    row.names(df)<-row.names(dati$DS)[cr]
    df
  })

# Istogramma --------------------------------------------------------------
  
  output$graf_hist_var<-renderUI({
    selectizeInput(inputId = "graf_hist_var"," ",
                   choices = dati$var_qt)})
  
  output$graf_hist_var_gr<-renderUI({
    req(dati$var_ql)
    checkboxGroupInput(inputId = "graf_hist_var_gr",label = "seleziona i fattori",
                       choices = dati$var_ql,selected =dati$var_gr)
  })
  
  observeEvent(input$graf_hist_var_gr,ignoreNULL = FALSE,{
    graf$var_gr<-input$graf_hist_var_gr
    if(is.null(input$graf_hist_var_gr)){
      graf$gr<-NULL
    } else {
      graf$gr<-input$graf_hist_gr
    }
  })
  
  output$graf_hist_gr<-renderUI({
    req(input$graf_hist_var_gr)
    req(graf$var_gr)
    if(length(graf$var_gr)==1){
      checkboxGroupInput(inputId = "graf_hist_gr",label = "deseleziona i livelli che non interessano",
                         choices = unique(dati$DS[,input$graf_hist_var_gr]),selected =unique(dati$DS[,input$graf_hist_var_gr]))
    } else if (length(graf$var_gr)==2){
      lv<-unique(interaction(dati$DS[,input$graf_hist_var_gr[1]],dati$DS[,input$graf_hist_var_gr[2]]))
      checkboxGroupInput(inputId = "graf_hist_gr",label = "deseleziona i livelli che non interessano",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)==3){
      lv<-unique(interaction(dati$DS[,input$graf_hist_var_gr[1]],dati$DS[,input$graf_hist_var_gr[2]],dati$DS[,input$graf_hist_var_gr[3]]))
      checkboxGroupInput(inputId = "graf_hist_gr",label = "deseleziona i livelli che non interessano",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)>3){
      print("Massimo 3 fattori")}
  })
  
  observeEvent(input$graf_hist_gr,ignoreNULL = FALSE,{
    graf$gr<-input$graf_hist_gr
  })

  output$graf_hist_bin<-renderUI({
    req(input$graf_hist_var%in%colnames(dati$DS))
    sliderInput(inputId = "graf_hist_bin",label = "larghezza barra",ticks = FALSE,
                min = round((1/4)*(max(abs(dati$DS[,input$graf_hist_var]))-min(abs(dati$DS[,input$graf_hist_var])))/sqrt(nrow(dati$DS)),3),
                max = round((7/4)*(max(abs(dati$DS[,input$graf_hist_var]))-min(abs(dati$DS[,input$graf_hist_var])))/sqrt(nrow(dati$DS)),3),
                step = round((3/20)*(max(abs(dati$DS[,input$graf_hist_var]))-min(abs(dati$DS[,input$graf_hist_var])))/sqrt(nrow(dati$DS)),3),
                value = round((max(dati$DS[,input$graf_hist_var])-min(dati$DS[,input$graf_hist_var]))/sqrt(nrow(dati$DS)),3))
  })
  
  output$graf_hist<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0 & input$graf_hist_var%in%colnames(dati$DS),""))
    req(input$graf_hist_var)
    req(input$graf_hist_bin)
    df<-as.data.frame(dati$DS[,input$graf_hist_var,drop=FALSE])
    if(!is.null(graf$var_gr)){
      if (length(graf$var_gr)==1){
        lab<-as.factor(dati$DS[,input$graf_hist_var_gr])
      } else if (length(graf$var_gr)==2){
        lab<-as.factor(interaction(dati$DS[,input$graf_hist_var_gr[1]],dati$DS[,input$graf_hist_var_gr[2]]))
      } else if (length(graf$var_gr)==3){
        lab<-as.factor(interaction(dati$DS[,input$graf_hist_var_gr[1]],dati$DS[,input$graf_hist_var_gr[2]],dati$DS[,input$graf_hist_var_gr[3]]))
      }
    } else {
      lab<-rep("0",nrow(df))
    }
    df<-cbind.data.frame(df,lab)
    colnames(df)<-c("x","gruppo")
    row.names(df)<-row.names(dati$DS)
    gr<-ggplot(df,mapping = aes(x=x))+labs(x=input$graf_hist_var)+theme_light()
    if(input$graf_hist_tipo=="conteggio"){
      if(is.null(graf$gr)){
        gr+geom_histogram(binwidth = input$graf_hist_bin,fill="blue",col="white",aes(y = ..count..))+labs(y="conteggio")
      } else {
        gr<-gr+geom_histogram(binwidth = input$graf_hist_bin,col="blue",aes(y = ..count..,fill=gruppo))+labs(y="conteggio")
        gr%+%subset(df,df$gruppo%in%graf$gr)
      }
    } else if (input$graf_hist_tipo=="percentuale"){
      if(is.null(graf$gr)){
        gr+geom_histogram(binwidth = input$graf_hist_bin,fill="blue",col="white",aes(y = 100*(..count..)/sum(..count..)))+labs(y="percentuale")
      } else {
        gr+geom_histogram(binwidth = input$graf_hist_bin,col="blue",aes(y = 100*(..count..)/sum(..count..),fill=gruppo))+labs(y="percentuale")
      }
    } else if (input$graf_hist_tipo=="densità"){
      if(is.null(graf$gr)){
        gr+geom_histogram(binwidth = input$graf_hist_bin,fill="blue",col="white",aes(y = ..density..))+labs(y="densità")
      } else {
        gr+geom_histogram(binwidth = input$graf_hist_bin,col="blue",aes(y = ..density..,fill=gruppo))+labs(y="densità")
      }
    }
  })

# BoxPlot -----------------------------------------------------------------

  output$graf_box_var<-renderUI({
    selectizeInput(inputId = "graf_box_var"," ",
                   choices = dati$var_qt)})
  
  output$graf_box_var_gr<-renderUI({
    req(dati$var_ql)
    checkboxGroupInput(inputId = "graf_box_var_gr",label = "seleziona i fattori",
                       choices = dati$var_ql,selected =dati$var_gr)
  })
  
  observeEvent(input$graf_box_var_gr,ignoreNULL = FALSE,{
    graf$var_gr<-input$graf_box_var_gr
    if(is.null(input$graf_box_var_gr)){
      graf$gr<-NULL
    } else {
      graf$gr<-input$graf_box_gr
    }
  })

  output$graf_box_gr<-renderUI({
    req(input$graf_box_var_gr)
    req(graf$var_gr)
    if(length(graf$var_gr)==1){
      checkboxGroupInput(inputId = "graf_box_gr",label = "deseleziona i livelli che non interessano",
                         choices = unique(dati$DS[,input$graf_box_var_gr]),selected =unique(dati$DS[,input$graf_box_var_gr]))
    } else if (length(graf$var_gr)==2){
      lv<-unique(interaction(dati$DS[,input$graf_box_var_gr[1]],dati$DS[,input$graf_box_var_gr[2]]))
      checkboxGroupInput(inputId = "graf_box_gr",label = "deseleziona i livelli che non interessano",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)==3){
      lv<-unique(interaction(dati$DS[,input$graf_box_var_gr[1]],dati$DS[,input$graf_box_var_gr[2]],dati$DS[,input$graf_box_var_gr[3]]))
      checkboxGroupInput(inputId = "graf_box_gr",label = "deseleziona i livelli che non interessano",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)>3){
      print("Massimo 3 fattori")}
  })

  observeEvent(input$graf_box_gr,ignoreNULL = FALSE,{
    graf$gr<-input$graf_box_gr
  })
  
  output$graf_box<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$graf_box_var%in%colnames(dati$DS))
    df<-as.data.frame(dati$DS[,input$graf_box_var,drop=FALSE])
    if(!is.null(graf$var_gr)){
      if (length(graf$var_gr)==1){
        lab<-as.factor(dati$DS[,input$graf_box_var_gr])
      } else if (length(graf$var_gr)==2){
        lab<-as.factor(interaction(dati$DS[,input$graf_box_var_gr[1]],dati$DS[,input$graf_box_var_gr[2]]))
      } else if (length(graf$var_gr)==3){
        lab<-as.factor(interaction(dati$DS[,input$graf_box_var_gr[1]],dati$DS[,input$graf_box_var_gr[2]],dati$DS[,input$graf_box_var_gr[3]]))
      }
    } else {
      lab<-rep("0",nrow(df))
    }
    df<-cbind.data.frame(df,lab)
    colnames(df)<-c("y","gruppo")
    row.names(df)<-row.names(dati$DS)
    gr<-ggplot(df,mapping = aes(x=gruppo,y=y))+labs(y=input$graf_box_var)+ theme_light()
    if(is.null(graf$gr)){
      gr+geom_boxplot(notch = input$graf_box_notch,fill="blue",width=0.5)+labs(x="")
    } else {
      gr<-gr+geom_boxplot(notch = input$graf_box_notch,mapping = aes(fill=gruppo))+
        scale_x_discrete(limits=graf$gr)+theme(legend.position="none")
      gr%+%subset(df,df$gruppo%in%graf$gr)
    }
  })
  
  observeEvent(input$graf_box_canc_brush,ignoreNULL = FALSE, {
    req(input$graf_box_brush)
    brush <- input$graf_box_brush
    y<-dati$DS[,input$graf_box_var]
    nr<-length(y)
    if(is.null(graf$gr)){
      cr<-which(y>brush$ymin & y<brush$ymax)
    } else{
      cr<-which(y>brush$ymin & y<brush$ymax & 
                  dati$DS[,input$graf_box_var_gr]%in%graf$gr[round(c(brush$xmin,brush$xmax))])
    }
    df<-dati$DS
    righe<-row.names(df)
    righe_tolte<-righe[cr]
    righe_rest<-righe[!cr]
    dati$righe_tolte<-c(righe_tolte,dati$righe_tolte)
    dati$righe_rest<-righe[!righe%in%dati$righe_tolte]
    dati$DS<-as.data.frame(dati$DS[dati$righe_rest, , drop=FALSE])
  #  if(length(dati$var_nr)==2) {
   #   names(dati$DS)<-dati$var_nr[input$var_nr!=dati$var_nr]
  #  } else {
      colnames(dati$DS)<-colnames(dati$DS_righe)
  #  }
    row.names(dati$DS)<-dati$righe_rest
  })
  
  observeEvent(input$graf_box_ripr_brush,ignoreNULL = FALSE, {
    dati$righe_tolte=NULL
    dati$righe_rest<-dati$righe
    dati$DS<-dati$DS_righe
  #  if(length(dati$var_nr)==2) names(dati$DS)<-dati$var_nr[input$var_nr!=dati$var_nr]
  })
  
  output$graf_box_selez<-renderPrint({
    req(input$graf_box_brush)
    brush <- input$graf_box_brush
    y<-dati$DS[,input$graf_box_var]
    nr<-length(y)
    
    if(is.null(graf$gr)){
      cr<-which(y>brush$ymin & y<brush$ymax)
    } else{
      cr<-which(y>brush$ymin & y<brush$ymax & 
                  dati$DS[,input$graf_box_var_gr]%in%graf$gr[round(c(brush$xmin,brush$xmax))])
    }
    df<-as.data.frame(dati$DS[cr,])
    colnames(df)<-colnames(dati$DS)
    row.names(df)<-row.names(dati$DS)[cr]
    df
  })  
  
# t test 1 -------------------------------------------------------------- 
  
  output$ttest1_variab<-renderUI({
    selectizeInput(inputId = "ttest1_variab"," ",
                   choices = dati$var_qt)})
  
  output$ttest1_Test1<-renderText({
    validate(need(input$ttest1_var==1,""))
    "z-test"
  })
  
  output$ttest1_Test2<-renderText({
    validate(need(input$ttest1_var==2,""))
    "t-test"
  })
  
  output$ttest1_H0<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    numericInput("ttest1_H0",label = "Media ipotizzata",
                 value=round(mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1]),3),width = "40%")
  })
  
  output$ttest1_var_nota<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    req(input$ttest1_var==1)
    numericInput("ttest1_var_nota",label = "Dev. standard nota",
                 value=round(sd(as.data.frame(dati$DS[,input$ttest1_variab])[,1]),3),width = "40%")
  })
  
  output$ttest1_H0_txt = renderUI({        
    HTML("H<SUB>0</SUB>: &mu; =", input$ttest1_H0,"<p> H<SUB>1</SUB>: &mu; &ne;",input$ttest1_H0)
  })
  
  output$ttest1_graf_distr<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    vrb<-as.data.frame(dati$DS[,input$ttest1_variab])
    
    x<-seq(-6, 6,by = 0.1)
    if(input$ttest1_var==1){
      df<-cbind.data.frame(x=x,y=dnorm(x,mean=0,sd=1))
      if(input$ttest1_alfa>0){
        q<-qnorm(input$ttest1_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
        if(q>6) q<-6
        x.b<-seq(q,6,by = 0.1)
        x.a<- -x.b[order(x.b,decreasing = TRUE)]
        df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =0,sd = 1))
        df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =0,sd = 1))
        df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      }
      gr<-ggplot() +theme_classic()+
        geom_line(data = df,mapping = aes(x=x,y=y))+
        ylab("densità")+xlab(expression(frac(bar(x)-mu,sigma * sqrt(1/m))))+ggtitle("N(0,1)")+
        theme(plot.title = element_text(size = 20, face = "bold",
                                        hjust = 0.5))
      
      if(input$ttest1_alfa>0){
        gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
      gr+geom_vline(xintercept = (mean(vrb[,1])-input$ttest1_H0)/(input$ttest1_var_nota*sqrt(1/nrow(vrb))),col="green")
    } else {
      dof<-nrow(vrb)-1
      if (dof==0){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"   Ci vuole almeno 1 grado di libertà \n
             numerosità del campione almeno 2 \n",col="red",cex=2)
      } else {
        ds<-sd(vrb[,1])
        df<-cbind.data.frame(x=x,y=dt(x,df = dof))
        if(input$ttest1_alfa>0){
          q<-qt(input$ttest1_alfa/2,df = dof,lower.tail = FALSE)
          if(q>6) q<-6
          x.b<-seq(q,6,by = 0.1)
          x.a<- -x.b[order(x.b,decreasing = TRUE)]
          df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
          df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
          df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
          df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        }
        
        gr<-ggplot() +theme_classic()+
          geom_line(data = df,mapping = aes(x=x,y=y))+
          ylab("densità")+xlab(expression(frac(bar(x)-mu,s * sqrt(1/m))))+ggtitle(paste("t(",dof,")",sep=""))+
          theme(plot.title = element_text(size = 20, face = "bold",
                                          hjust = 0.5))
        
        if(input$ttest1_alfa>0){
          gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
            geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
        
        gr+geom_vline(xintercept = (mean(vrb[,1])-input$ttest1_H0)/(ds*sqrt(1/nrow(vrb))),col="green") 
      }
    }
  })
  
  output$ttest1_media_camp_titolo<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    "Stima puntuale"
  })
  
  output$ttest1_media_camp<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    paste("media campionaria =",round(mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1]),3))
  })
  
  output$ttest1_sd_camp<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    validate(need(input$ttest1_var=="2",""))
    paste("dev. standard campionaria =",round(sd(as.data.frame(dati$DS[,input$ttest1_variab])[,1]),3))
  })
  
  output$ttest1_stat<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    if(input$ttest1_var=="1"){
      paste("statistica =",round((mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1])-input$ttest1_H0)/
              (input$ttest1_var_nota*sqrt(1/nrow(as.data.frame(dati$DS[,input$ttest1_variab])))),4)) 
    }else{
     paste("statistica =",round((mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1])-input$ttest1_H0)/
            (sd(as.data.frame(dati$DS[,input$ttest1_variab])[,1])*sqrt(1/nrow(as.data.frame(dati$DS[,input$ttest1_variab])))),4)) 
    }
  }) 
  
  output$ttest1_pval<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    if(input$ttest1_var=="1"){
      q<-(mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1])-input$ttest1_H0)/
        (input$ttest1_var_nota*sqrt(1/nrow(as.data.frame(dati$DS[,input$ttest1_variab])))) 
      p<-pnorm(q = abs(q),mean = 0,sd = 1,lower.tail = FALSE)
      p<-format(2*p,digits = 4,format="e")
    }else{
      q<-(mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1])-input$ttest1_H0)/
        (sd(as.data.frame(dati$DS[,input$ttest1_variab])[,1])*sqrt(1/nrow(as.data.frame(dati$DS[,input$ttest1_variab]))))
      dof<-nrow(as.data.frame(dati$DS[,input$ttest1_variab]))-1
      p<-pt(q = abs(q),df = dof,lower.tail = FALSE)
      p<-format(2*p,digits = 4,format="e")
    }
    paste("p-value =",p)
  }) 
  
  output$ttest1_ic_titolo<-renderText({
    validate(need(input$ttest1_alfa>0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    "Stima per intervallo"
  })
  
  output$ttest1_ic_inf<-renderText({
    validate(need(input$ttest1_alfa>0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    media<-mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1])
    m<-nrow(as.data.frame(dati$DS[,input$ttest1_variab]))
    if(input$ttest1_var==1){
      s<-input$ttest1_var_nota
      q<-qnorm(input$ttest1_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
    } else {
      s<-sd(as.data.frame(dati$DS[,input$ttest1_variab])[,1])
      q<-qt(input$ttest1_alfa/2,df = m-1,lower.tail = FALSE)
    }
    paste("estremo inferiore =",round(media-q*s*sqrt(1/m),4))
  })
  
  output$ttest1_ic_sup<-renderText({
    validate(need(input$ttest1_alfa>0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    media<-mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1])
    m<-nrow(as.data.frame(dati$DS[,input$ttest1_variab]))
    if(input$ttest1_var==1){
      s<-input$ttest1_var_nota
      q<-qnorm(input$ttest1_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
    } else {
      s<-sd(as.data.frame(dati$DS[,input$ttest1_variab])[,1])
      q<-qt(input$ttest1_alfa/2,df = m-1,lower.tail = FALSE)
    }
    paste("estremo superiore =",round(media+q*s*sqrt(1/m),4))
  })
  
  output$ttest1_qqplot<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    ggplot(dati$DS,aes(sample=dati$DS[,input$ttest1_variab]))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="quantili teorici",  y = "quantili campione")+
      theme_classic()
  })
  
  
  output$ttest1_shapiro<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    Dati<-dati$DS[,input$ttest1_variab]
    shapiro.test(Dati) 
  })
# ttest2a -----------------------------------------------------------------
  
  output$ttest2a_variab1<-renderUI({
    selectizeInput(inputId = "ttest2a_variab1"," ",
                   choices = dati$var_qt)})
  
  output$ttest2a_Test1<-renderText({
    validate(need(input$ttest2a_var==1,""))
    "z-test"
  })
  
  output$ttest2a_Test2<-renderText({
    validate(need(input$ttest2a_var==2,""))
    "t-test"
  })
  
  output$ttest2a_variab2<-renderUI({
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    selectizeInput(inputId = "ttest2a_variab2"," ",
                   choices = dati$var_qt[!dati$var_qt%in%input$ttest2a_variab1])})
  
  output$ttest2a_H0<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    numericInput("ttest2a_H0",label = "Media differenze ipotizzata",
                 value=0,width = "40%")
  })
  
  output$ttest2a_var_nota<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    req(input$ttest2a_var==1)
    numericInput("ttest2a_var_nota",label = "Dev. standard differenze nota",
                 value=round(sd(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1]),3),width = "40%")
  })
  
  output$ttest2a_H0_txt = renderUI({        
    HTML("H<SUB>0</SUB>: &mu;<SUB>d</SUB> =", input$ttest2a_H0,"<p> H<SUB>1</SUB>: &mu;<SUB>d</SUB> &ne;",input$ttest2a_H0)
  })
  
  output$ttest2a_graf_distr<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    vrb<-as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])
    
    x<-seq(-6, 6,by = 0.1)
    if(input$ttest2a_var==1){
      df<-cbind.data.frame(x=x,y=dnorm(x,mean=0,sd=1))
      if(input$ttest2a_alfa>0){
        q<-qnorm(input$ttest2a_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
        if(q>6) q<-6
        x.b<-seq(q,6,by = 0.1)
        x.a<- -x.b[order(x.b,decreasing = TRUE)]
        df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =0,sd = 1))
        df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =0,sd = 1))
        df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      }
      gr<-ggplot() +theme_classic()+
        geom_line(data = df,mapping = aes(x=x,y=y))+
        ylab("densità")+xlab(expression(frac(bar(d)-mu,sigma * sqrt(1/m))))+ggtitle("N(0,1)")+
        theme(plot.title = element_text(size = 20, face = "bold",
                                        hjust = 0.5))
      
      if(input$ttest2a_alfa>0){
        gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
      gr+geom_vline(xintercept = (mean(vrb[,1])-input$ttest2a_H0)/(input$ttest2a_var_nota*sqrt(1/nrow(vrb))),col="green")
    } else {
      dof<-nrow(vrb)-1
      if (dof==0){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"   Ci vuole almeno 1 grado di libertà \n
             numerosità del campione almeno 2 \n",col="red",cex=2)
      } else {
        ds<-sd(vrb[,1])
        df<-cbind.data.frame(x=x,y=dt(x,df = dof))
        if(input$ttest2a_alfa>0){
          q<-qt(input$ttest2a_alfa/2,df = dof,lower.tail = FALSE)
          if(q>6) q<-6
          x.b<-seq(q,6,by = 0.1)
          x.a<- -x.b[order(x.b,decreasing = TRUE)]
          df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
          df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
          df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
          df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        }
        
        gr<-ggplot() +theme_classic()+
          geom_line(data = df,mapping = aes(x=x,y=y))+
          ylab("densità")+xlab(expression(frac(bar(d)-mu,s * sqrt(1/m))))+ggtitle(paste("t(",dof,")",sep=""))+
          theme(plot.title = element_text(size = 20, face = "bold",
                                          hjust = 0.5))
        
        if(input$ttest2a_alfa>0){
          gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
            geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
        
        gr+geom_vline(xintercept = (mean(vrb[,1])-input$ttest2a_H0)/(ds*sqrt(1/nrow(vrb))),col="green") 
      }
    }
  })
  
  output$ttest2a_media_camp_titolo<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    "Stima puntuale"
  })
  
  output$ttest2a_media_camp<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    paste("media campionaria =",round(mean(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1]),3))
  })
  
  output$ttest2a_sd_camp<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    validate(need(input$ttest2a_var=="2",""))
    paste("dev. standard campionaria =",round(sd(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1]),3))
  })
  
  output$ttest2a_stat<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    if(input$ttest2_var=="1"){
      paste("statistica =",round((mean(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])-input$ttest2_H0)/
                                   (input$ttest2a_var_nota*sqrt(1/nrow(as.data.frame(dati$DS[,input$ttest2a_variab1])))),4)) 
    }else{
      paste("statistica =",round((mean(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])-input$ttest2a_H0)/
                                   (sd(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])*sqrt(1/nrow(as.data.frame(dati$DS[,input$ttest2a_variab1])))),4)) 
    }
  }) 
  
  output$ttest2a_pval<-renderText({
  dati$var_qt[!dati$var_qt%in%input$ttest2a_variab1]
  })
  
  output$ttest2a_pval<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    if(input$ttest2a_var=="1"){
      q<-(mean(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])-input$ttest2a_H0)/
        (input$ttest2a_var_nota*sqrt(1/nrow(as.data.frame(dati$DS[,input$ttest2a_variab1])))) 
      p<-pnorm(q = abs(q),mean = 0,sd = 1,lower.tail = FALSE)
      p<-format(2*p,digits = 4,format="e")
    }else{
      q<-(mean(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])-input$ttest2a_H0)/
        (sd(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])*sqrt(1/nrow(as.data.frame(dati$DS[,input$ttest2a_variab1]))))
      dof<-nrow(as.data.frame(dati$DS[,input$ttest2a_variab1]))-1
      p<-pt(q = abs(q),df = dof,lower.tail = FALSE)
      p<-format(2*p,digits = 4,format="e")
    }
    paste("p-value =",p)
  }) 
  
  output$ttest2a_ic_titolo<-renderText({
    validate(need(input$ttest2a_alfa>0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    "Stima per intervallo"
  })
  
  output$ttest2a_ic_inf<-renderText({
    validate(need(input$ttest2a_alfa>0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    media<-mean(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])
    m<-nrow(as.data.frame(dati$DS[,input$ttest2a_variab1]))
    if(input$ttest2a_var==1){
      s<-input$ttest2a_var_nota
      q<-qnorm(input$ttest2a_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
    } else {
      s<-sd(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])
      q<-qt(input$ttest2a_alfa/2,df = m-1,lower.tail = FALSE)
    }
    paste("estremo inferiore =",round(media-q*s*sqrt(1/m),4))
  })
  
  output$ttest2a_ic_sup<-renderText({
    validate(need(input$ttest2a_alfa>0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    media<-mean(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])
    m<-nrow(as.data.frame(dati$DS[,input$ttest2a_variab1]))
    if(input$ttest2a_var==1){
      s<-input$ttest2a_var_nota
      q<-qnorm(input$ttest2a_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
    } else {
      s<-sd(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])
      q<-qt(input$ttest2a_alfa/2,df = m-1,lower.tail = FALSE)
    }
    paste("estremo superiore =",round(media+q*s*sqrt(1/m),4))
  })
  
  output$ttest2a_qqplot<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    Diff<-dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2]
    ggplot(dati$DS,aes(sample=Diff))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="quantili teorici",  y = "quantili campione")+
      theme_classic()
  })
  
  
  output$ttest2a_shapiro<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    Differenze<-dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2]
    shapiro.test(Differenze) 
  })
  

  # ttest2 -----------------------------------------------------------------
  
  output$ttest2_variab1<-renderUI({
    selectizeInput(inputId = "ttest2_variab1"," ",
                   choices = dati$var_qt)})
  
  output$ttest2_Test1<-renderText({
    validate(need(input$ttest2_var==1,""))
    "z-test"
  })
  
  output$ttest2_Test2<-renderText({
    validate(need(input$ttest2_var==2,""))
    "t-test"
  })
  
  output$ttest2_variab2<-renderUI({
    selectizeInput(inputId = "ttest2_variab2",div("Variabile gruppo",style="font-weight: 400;"),
                   choices = dati$var_ql)})
  
  output$ttest2_H0<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    numericInput("ttest2_H0",label = "Differenza medie ipotizzata",
                 value=0,width = "40%")
  })
  
  output$ttest2_var_nota1<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    req(input$ttest2_var==1)
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    numericInput("ttest2_var_nota1",label = "Dev. standard nota gr. 1",
                 value=round(sd(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1]),3),width = "40%")
  })

  output$ttest2_var_nota2<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    req(input$ttest2_var==1)
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    numericInput("ttest2_var_nota2",label = "Dev. standard nota gr. 2",
                 value=round(sd(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1]),3),width = "40%")
  })
  
  output$ttest2_var_uguale<-renderUI({
    validate(need(input$ttest2_var==2," "))
    radioButtons("ttest2_var_uguale", label = "",
                 choices = list("Varianze uguali" = 1, "Varianze non uguali" = 2),
                 selected = 1)
  })
  
  output$ttest2_H0_txt = renderUI({        
    HTML("H<SUB>0</SUB>: &mu;<SUB>1</SUB>-&mu;<SUB>2</SUB> =", input$ttest2_H0,"<p> H<SUB>1</SUB>: &mu;<SUB>1</SUB>-&mu;<SUB>2</SUB> &ne;",input$ttest2_H0)
  })
  
  output$ttest2_errore<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(length(unique(dati$DS[,input$ttest2_variab2]))!=2,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    "La variabile gruppo deve avere 2 livelli "
  })
  
  output$ttest2_graf_distr<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(length(unique(dati$DS[,input$ttest2_variab2]))==2,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1])
    
    x<-seq(-6, 6,by = 0.1)
    if(input$ttest2_var==1){
      df<-cbind.data.frame(x=x,y=dnorm(x,mean=0,sd=1))
      if(input$ttest2_alfa>0){
        q<-qnorm(input$ttest2_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
        if(q>6) q<-6
        x.b<-seq(q,6,by = 0.1)
        x.a<- -x.b[order(x.b,decreasing = TRUE)]
        df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =0,sd = 1))
        df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =0,sd = 1))
        df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      }
      gr<-ggplot() +theme_classic()+
        geom_line(data = df,mapping = aes(x=x,y=y))+
        ylab("densità")+
        xlab(expression(frac((bar(x)[1]-bar(x)[2])-(mu[1]-mu[2]),sqrt(sigma[1]^2/m[1]+sigma[2]^2/m[2]))))+
        ggtitle("N(0,1)")+
        theme(plot.title = element_text(size = 20, face = "bold",
                                        hjust = 0.5))
      
      if(input$ttest2_alfa>0){
        gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
      gr+geom_vline(xintercept = ((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sqrt(input$ttest2_var_nota1^2/nrow(vrb1)+input$ttest2_var_nota2^2/nrow(vrb2))),col="green")
    } else {
      if (nrow(vrb1)==1 | nrow(vrb2) ==1){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Numerosità dei campioni almeno 2 \n",col="red",cex=2)
      } else {
        ds1<-sd(vrb1[,1])
        ds2<-sd(vrb2[,1])
        if(input$ttest2_var_uguale==1){
          dof<-nrow(vrb1)+nrow(vrb2)-2
        }else{
          dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
              (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
        }
        sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
        df<-cbind.data.frame(x=x,y=dt(x,df = dof))
        if(input$ttest2_alfa>0){
          q<-qt(input$ttest2_alfa/2,df = dof,lower.tail = FALSE)
          if(q>6) q<-6
          x.b<-seq(q,6,by = 0.1)
          x.a<- -x.b[order(x.b,decreasing = TRUE)]
          df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
          df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
          df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
          df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        }
        
        gr<-ggplot() +theme_classic()+
          geom_line(data = df,mapping = aes(x=x,y=y))+
          ylab("densità")+xlab(expression(frac((bar(x)[1]-bar(x)[2])-(mu[1]-mu[2]),s[c]*sqrt(1/m[1]+1/m[2]))))+ggtitle(paste("t(",round(dof,3),")",sep=""))+
          theme(plot.title = element_text(size = 20, face = "bold",
                                          hjust = 0.5))
        
        if(input$ttest2_alfa>0){
          gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
            geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
        
        gr+geom_vline(xintercept = ((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2))),col="green") 
      }
    }
  })
  
  output$ttest2_media_camp_titolo<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    "Stime puntuali"
  })
  
  output$ttest2_media_camp1<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    paste("media campionaria gr 1 =",round(mean(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1]),3))
  })
  
  output$ttest2_media_camp2<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    paste("media campionaria gr 2 =",round(mean(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1]),3))
  })
  
  output$ttest2_sd_camp1<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    validate(need(input$ttest2_var=="2",""))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    paste("dev. standard campionaria gr 1=",round(sd(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1]),3))
  })
  
  output$ttest2_sd_camp2<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    validate(need(input$ttest2_var=="2",""))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    paste("dev. standard campionaria gr 2=",round(sd(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1]),3))
  })
  
  output$ttest2_ds_c<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    validate(need(input$ttest2_var=="2",""))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
    paste("dev. standard combinata=",round(sc,3))
  })
  
  output$ttest2_stat<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
    if(input$ttest2_var=="1"){
      paste("statistica =",round(((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sqrt(input$ttest2_var_nota1^2/nrow(vrb1)+input$ttest2_var_nota2^2/nrow(vrb2))),4)) 
    }else{
      paste("statistica =",round(((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2))),4))
    }
  })  
  
  output$ttest2_pval<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
    if(input$ttest2_var=="1"){
      q<-((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sqrt(input$ttest2_var_nota1^2/nrow(vrb1)+input$ttest2_var_nota2^2/nrow(vrb2)))
      p<-pnorm(q = abs(q),mean = 0,sd = 1,lower.tail = FALSE)
      p<-format(2*p,digits = 4,format="e")
    }else{
      q<-((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2)))
      if(input$ttest2_var_uguale==1){
        dof<-nrow(vrb1)+nrow(vrb2)-2
      }else{
        dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
          (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
      }
      p<-pt(q = abs(q),df = dof,lower.tail = FALSE)
      p<-format(2*p,digits = 4,format="e")
    }
    paste("p-value =",p)
  }) 
  
  output$ttest2_ic_titolo<-renderText({
    validate(need(input$ttest2_alfa>0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    "Stima per intervallo"
  })
  
  output$ttest2_ic_inf<-renderText({
    validate(need(input$ttest2_alfa>0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1])
    media<-mean(vrb1[,1])-mean(vrb2[,1])
    m1<-nrow(vrb1)
    m2<-nrow(vrb2)
    if(input$ttest2_var==1){
      s1<-input$ttest2_var_nota1
      s2<-input$ttest2_var_nota2
      q<-qnorm(input$ttest2_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
      paste("estremo inferiore =",round(media-q*sqrt(s1^2/m1+s2^2/m2),4))
    } else {
      ds1<-sd(vrb1[,1])
      ds2<-sd(vrb2[,1])
      sc<-sqrt(((m1-1)*ds1^2+(m2-1)*ds2^2)/(m1+m2-2))
      if(input$ttest2_var_uguale==1){
        dof<-nrow(vrb1)+nrow(vrb2)-2
      }else{
        dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
          (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
      }
      q<-qt(input$ttest2_alfa/2,df = dof,lower.tail = FALSE)
      paste("estremo inferiore =",round(media-q*sc*sqrt(1/m1+1/m2),4))
    }
  })
  
  output$ttest2_ic_sup<-renderText({
    validate(need(input$ttest2_alfa>0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1])
    media<-mean(vrb1[,1])-mean(vrb2[,1])
    m1<-nrow(vrb1)
    m2<-nrow(vrb2)
    if(input$ttest2_var==1){
      s1<-input$ttest2_var_nota1
      s2<-input$ttest2_var_nota2
      q<-qnorm(input$ttest2_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
      paste("estremo superiore =",round(media+q*sqrt(s1^2/m1+s2^2/m2),4))
    } else {
      ds1<-sd(vrb1[,1])
      ds2<-sd(vrb2[,1])
      sc<-sqrt(((m1-1)*ds1^2+(m2-1)*ds2^2)/(m1+m2-2))
      if(input$ttest2_var_uguale==1){
        dof<-nrow(vrb1)+nrow(vrb2)-2
      }else{
        dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
          (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
      }
      q<-qt(input$ttest2_alfa/2,df = dof,lower.tail = FALSE)
      paste("estremo superiore =",round(media+q*sc*sqrt(1/m1+1/m2),4))
    }
  })
  
  output$ttest2_qqplot1<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    dati<-dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],]
    ggplot(dati,aes(sample=dati[,input$ttest2_variab1]))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="quantili teorici",  y = "quantili campione")+
      theme_classic()
  })
  
 output$ttest2_shapiro1<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    dati<-dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],]
    Campione.1<-dati[,input$ttest2_variab1]
    shapiro.test(Campione.1)
  })
  
  output$ttest2_qqplot2<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    dati<-dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],]
    ggplot(dati,aes(sample=dati[,input$ttest2_variab1]))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="quantili teorici",  y = "quantili campione")+
      theme_classic()
  })
  
  
  output$ttest2_shapiro2<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    dati<-dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],]
    Campione.2<-dati[,input$ttest2_variab1]
    shapiro.test(Campione.2) 
  })

  # ftest -----------------------------------------------------------------
  
  output$ftest_variab1<-renderUI({
    selectizeInput(inputId = "ftest_variab1"," ",
                   choices = dati$var_qt)})
  
  output$ftest_variab2<-renderUI({
    selectizeInput(inputId = "ftest_variab2",div("Variabile gruppo",style="font-weight: 400;"),
                   choices = dati$var_ql)})
  
  output$ftest_H0_txt = renderUI({        
    HTML("H<SUB>0</SUB>: &sigma;<SUB>1</SUB> = &sigma;<SUB>2</SUB> <p> H<SUB>1</SUB>: &sigma;<SUB>1</SUB> &ne; &sigma;<SUB>1</SUB>")
    
  })
  
  output$ftest_errore<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(length(unique(dati$DS[,input$ftest_variab2]))!=2,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    "La variabile gruppo deve avere 2 livelli "
  })
  
  output$ftest_graf_distr<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(length(unique(dati$DS[,input$ftest_variab2]))==2,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[1],input$ftest_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[2],input$ftest_variab1])
    
    x<-seq(0, 10,by = 0.1)
      if (nrow(vrb1)==1 | nrow(vrb2) ==1){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Numerosità dei campioni almeno 2 \n",col="red",cex=2)
      } else {
        ds1<-sd(vrb1[,1])
        ds2<-sd(vrb2[,1])
        dof1<-nrow(vrb1)-1
        dof2<-nrow(vrb2)-1
    
        df<-cbind.data.frame(x=x,y=df(x,df1 = dof1,df2 = dof2))
        if(input$ftest_alfa>0){
          q<-qf(input$ftest_alfa/2,df1 = dof1,df2 = dof2,lower.tail = FALSE)
          if(q>10) q<-10
          x.b<-seq(q,10,by = 0.1)
          x.a<- c(0,1/x.b[order(x.b,decreasing = TRUE)])
          df.a<-cbind.data.frame(x=x.a,y=df(x.a,df1 = dof1,df2 = dof2))
          df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
          df.b<-cbind.data.frame(x=x.b,y=df(x.b,df1 = dof1,df2 = dof2))
          df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        
        
        gr<-ggplot() +theme_classic()+
          geom_line(data = df,mapping = aes(x=x,y=y))+
          ylab("densità")+xlab(expression(frac(s[1]^2,s[2]^2)))+
          ggtitle(paste("F(",round(dof1,3),",",round(dof2,3),")",sep=""))+
          theme(plot.title = element_text(size = 20, face = "bold",
                                          hjust = 0.5))
        
        if(input$ftest_alfa>0){
          gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
            geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
        
        gr+geom_vline(xintercept = (ds1^2/ds2^2),col="green")
      
    }}
  })
  
  output$ftest_media_camp_titolo<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    "Stime puntuali"
  })
  
  output$ftest_sd_camp1<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    paste("dev. standard campionaria gr 1=",round(sd(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[1],input$ftest_variab1]),3))
  })
  
  output$ftest_sd_camp2<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    paste("dev. standard campionaria gr 2=",round(sd(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[2],input$ftest_variab1]),3))
  })
  
  output$ftest_stat<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[1],input$ftest_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[2],input$ftest_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    paste("statistica =",round(ds1^2/ds2^2,4)) 
  }) 
  
  output$ftest_pval<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[1],input$ftest_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[2],input$ftest_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    dof1<-nrow(vrb1)-1
    dof2<-nrow(vrb2)-1
    q<-ds1^2/ds2^2
    if(q<1) q<-1/q
    p<-pf(q,df1 = dof1 ,df2 = dof2,lower.tail = FALSE)+pf(1/q,df1 = dof1 ,df2 = dof2,lower.tail = TRUE)
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 
  
  output$ftest_ic_titolo<-renderText({
    validate(need(input$ftest_alfa>0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    "Stima per intervallo"
  })
  
  output$ftest_ic_inf<-renderText({
    validate(need(input$ftest_alfa>0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[1],input$ftest_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[2],input$ftest_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    dof1<-nrow(vrb1)-1
    dof2<-nrow(vrb2)-1
    q<-qf(input$ftest_alfa/2,df1 = dof1,df2 = dof2,lower.tail = FALSE)
    paste("estremo inferiore =",round((ds1^2/ds2^2)*(1/q),4))
  })
  
  output$ftest_ic_sup<-renderText({
    validate(need(input$ftest_alfa>0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[1],input$ftest_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[2],input$ftest_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    dof1<-nrow(vrb1)-1
    dof2<-nrow(vrb2)-1
    q<-qf(input$ftest_alfa/2,df1 = dof1,df2 = dof2,lower.tail = TRUE)
    paste("estremo superiore =",round((ds1^2/ds2^2)*(1/q),4))
  })
  
  output$ftest_qqplot1<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    dati<-dati$DS[dati$DS[,input$ftest_variab2]==gruppi[1],]
    ggplot(dati,aes(sample=dati[,input$ftest_variab1]))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="quantili teorici",  y = "quantili campione")+
      theme_classic()
  })
  
  output$ftest_shapiro1<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    dati<-dati$DS[dati$DS[,input$ftest_variab2]==gruppi[1],]
    Campione.1<-dati[,input$ftest_variab1]
    shapiro.test(Campione.1)
  })
  
  output$ftest_qqplot2<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    dati<-dati$DS[dati$DS[,input$ftest_variab2]==gruppi[2],]
    ggplot(dati,aes(sample=dati[,input$ftest_variab1]))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="quantili teorici",  y = "quantili campione")+
      theme_classic()
  })
  
  
  output$ftest_shapiro2<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    dati<-dati$DS[dati$DS[,input$ftest_variab2]==gruppi[2],]
    Campione.2<-dati[,input$ftest_variab1]
    shapiro.test(Campione.2) 
  })
  
  # Anova test-----------------------------------------------------------------
  output$anovatest_variab1<-renderUI({
    selectizeInput(inputId = "anovatest_variab1"," ",
                   choices = dati$var_qt)})
  
  output$anovatest_variab2<-renderUI({
    selectizeInput(inputId = "anovatest_variab2",div("Fattore",style="font-weight: 400;"),
                   choices = dati$var_ql)})
  
  output$anovatest_graf_distr<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anovatest_variab1%in%colnames(dati$DS))
    req(input$anovatest_variab2%in%colnames(dati$DS))
    
    df<-cbind.data.frame(x=dati$DS[,input$anovatest_variab1],gr=dati$DS[,input$anovatest_variab2])
    df$gr<-as.factor(df$gr)
    
    mod<-aov(x~gr,df)
    s<-summary(mod)
    dof1<-s[[1]][1,1]
    dof2<-s[[1]][2,1]
    F<-s[[1]][1,4]

    x<-seq(0, 10,by = 0.1)
    df<-cbind.data.frame(x=x,y=df(x,df1 = dof1,df2 = dof2))
      
    gr<-ggplot() +theme_classic()+
    geom_line(data = df,mapping = aes(x=x,y=y))+
    ylab("densità")+xlab("f")+
    ggtitle(paste("F(",round(dof1,3),",",round(dof2,3),")",sep=""))+
    theme(plot.title = element_text(size = 20, face = "bold",hjust = 0.5))  
      
    if(input$anovatest_alfa>0){
      q<-qf(input$anovatest_alfa,df1 = dof1,df2 = dof2,lower.tail = FALSE)
      if(q>10) q<-10
      x.b<-seq(q,10,by = 0.1)
        
      df.b<-cbind.data.frame(x=x.b,y=df(x.b,df1 = dof1,df2 = dof2))
      df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      gr<-gr + geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")}
        
   gr+geom_vline(xintercept = F,col="green")
  })

  output$anovatest_stat<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anovatest_variab1%in%colnames(dati$DS))
    req(input$anovatest_variab2%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anovatest_variab1],gr=dati$DS[,input$anovatest_variab2])
    df$gr<-as.factor(df$gr)
    mod<-aov(x~gr,df)
    s<-summary(mod)
    dof1<-s[[1]][1,1]
    dof2<-s[[1]][2,1]
    F<-s[[1]][1,4]
    paste("statistica =",round(F,4)) 
  }) 
  
  output$anovatest_pval<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anovatest_variab1%in%colnames(dati$DS))
    req(input$anovatest_variab2%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anovatest_variab1],gr=dati$DS[,input$anovatest_variab2])
    df$gr<-as.factor(df$gr)
    mod<-aov(x~gr,df)
    s<-summary(mod)
    dof1<-s[[1]][1,1]
    dof2<-s[[1]][2,1]
    p<-s[[1]][1,5]
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 

  output$anovatest_R<-renderPrint({
    req(input$anovatest_variab1%in%colnames(dati$DS))
    req(input$anovatest_variab2%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anovatest_variab1],gr=dati$DS[,input$anovatest_variab2])
    df$gr<-as.factor(df$gr)
    colnames(df)<-c(input$anovatest_variab1,input$anovatest_variab2)
    frm<-as.formula(paste(input$anovatest_variab1,"~",input$anovatest_variab2,sep=""))
    mod<-aov(frm,df)
    summary(mod)
  })

  output$anovatest_qqplot1<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anovatest_variab1%in%colnames(dati$DS))
    req(input$anovatest_variab2%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anovatest_variab1],gr=dati$DS[,input$anovatest_variab2])
    df$gr<-as.factor(df$gr)
    mod<-aov(x~gr,df)
    dati<-cbind.data.frame(res=mod$residuals)
    ggplot(dati,aes(sample=res))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="quantili teorici",  y = "quantili campione")+
      theme_classic()
  })
  
  output$anovatest_shapiro1<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anovatest_variab1%in%colnames(dati$DS))
    req(input$anovatest_variab2%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anovatest_variab1],gr=dati$DS[,input$anovatest_variab2])
    df$gr<-as.factor(df$gr)
    mod<-aov(x~gr,df)
    Residui<-mod$residuals
    shapiro.test(Residui)
  })

  output$anovatest_bartlett<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anovatest_variab1%in%colnames(dati$DS))
    req(input$anovatest_variab2%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anovatest_variab1],gr=dati$DS[,input$anovatest_variab2])
    df$gr<-as.factor(df$gr)
    colnames(df)<-c(input$anovatest_variab1,input$anovatest_variab2)
    frm<-as.formula(paste(input$anovatest_variab1,"~",input$anovatest_variab2,sep=""))
    bartlett.test(frm,df) 
  })
  
  output$anovatest_fligner<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anovatest_variab1%in%colnames(dati$DS))
    req(input$anovatest_variab2%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anovatest_variab1],gr=dati$DS[,input$anovatest_variab2])
    df$gr<-as.factor(df$gr)
    colnames(df)<-c(input$anovatest_variab1,input$anovatest_variab2)
    frm<-as.formula(paste(input$anovatest_variab1,"~",input$anovatest_variab2,sep=""))
    fligner.test(frm,df) 
  })
  
  output$anovatest_levene<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anovatest_variab1%in%colnames(dati$DS))
    req(input$anovatest_variab2%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anovatest_variab1],gr=dati$DS[,input$anovatest_variab2])
    df$gr<-as.factor(df$gr)
    colnames(df)<-c(input$anovatest_variab1,input$anovatest_variab2)
    frm<-as.formula(paste(input$anovatest_variab1,"~",input$anovatest_variab2,sep=""))
    car::leveneTest(frm,df) 
  })
  
  output$anovatest_bp<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anovatest_variab1%in%colnames(dati$DS))
    req(input$anovatest_variab2%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anovatest_variab1],gr=dati$DS[,input$anovatest_variab2])
    df$gr<-as.factor(df$gr)
    Modello.aov<-aov(x~gr,df)
    lmtest::bptest(Modello.aov) 
  })
  
  output$anovatest_cochran<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anovatest_variab1%in%colnames(dati$DS))
    req(input$anovatest_variab2%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anovatest_variab1],gr=dati$DS[,input$anovatest_variab2])
    df$gr<-as.factor(df$gr)
    colnames(df)<-c(input$anovatest_variab1,input$anovatest_variab2)
    Modello.aov<-as.formula(paste(input$anovatest_variab1,"~",input$anovatest_variab2,sep=""))
    outliers::cochran.test(Modello.aov,df) 
  })

  # Anova2 test-----------------------------------------------------------------
  output$anova2test_variab1<-renderUI({
    selectizeInput(inputId = "anova2test_variab1"," ",
                   choices = dati$var_qt)})
  
  output$anova2test_variab2<-renderUI({
    selectizeInput(inputId = "anova2test_variab2",div("Fattore 1",style="font-weight: 400;"),
                   choices = dati$var_ql)})
  
  output$anova2test_variab3<-renderUI({
    selectizeInput(inputId = "anova2test_variab3",div("Fattore 2",style="font-weight: 400;"),
                   choices = dati$var_ql[!dati$var_ql%in%input$anova2test_variab2])})
  
  output$anova2test_h12_ipotesi<-renderUI({
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if (max(smr)==1){
      h4(HTLM("Anova senza ripetizioni. <br>
              Non abbiamo gdl per eseguire test"))
    } else {
      HTML("<h4>Ipotesi 12:</h4>
      <h4>H<SUB>0,12</SUB>: (&alpha;&beta;)<SUB>i,j</SUB> = 0 per ogni (i,j) <br>
              H<SUB>1,12</SUB>:(&alpha;&beta;)<SUB>i,j</SUB> &ne;0 per almeno un (i,j)</h4>")
    }
  })

  output$anova2test_graf_distr1<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if(max(smr)==1){
      mod<-aov(x~gr1+gr2,df)
      s<-summary(mod)
    } else {
      mod<-aov(x~gr1*gr2,df)
      s<-summary(mod)
    }
    dof1<-s[[1]][1,1]
    dof2<-s[[1]][4,1]
    F<-s[[1]][1,4]
    
    x<-seq(0, 10,by = 0.1)
    df<-cbind.data.frame(x=x,y=df(x,df1 = dof1,df2 = dof2))

    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("densità")+xlab("f")+
      ggtitle(paste("F(",round(dof1,3),",",round(dof2,3),")",sep=""))+
      theme(plot.title = element_text(size = 20, face = "bold",hjust = 0.5))  
    
    if(input$anova2test_alfa>0){
      q<-qf(input$anova2test_alfa,df1 = dof1,df2 = dof2,lower.tail = FALSE)
      req(q)
      if(q>10) q<-10
      x.b<-seq(q,10,by = 0.1)
      df.b<-cbind.data.frame(x=x.b,y=df(x.b,df1 = dof1,df2 = dof2))
      df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      gr<-gr + geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")}
    gr+geom_vline(xintercept = F,col="green")
  })
  
  output$anova2test_stat1<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if(max(smr)==1){
      mod<-aov(x~gr1+gr2,df)
      s<-summary(mod)
    } else {
      mod<-aov(x~gr1*gr2,df)
      s<-summary(mod)
    }
    dof1<-s[[1]][1,1]
    dof2<-s[[1]][4,1]
    F<-s[[1]][1,4]
    paste("statistica =",round(F,4)) 
  }) 
  
  output$anova2test_pval1<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if(max(smr)==1){
      mod<-aov(x~gr1+gr2,df)
      s<-summary(mod)
    } else {
      mod<-aov(x~gr1*gr2,df)
      s<-summary(mod)
    }
    dof1<-s[[1]][1,1]
    dof2<-s[[1]][4,1]
    p<-s[[1]][1,5]
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 

  output$anova2test_graf_distr2<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if(max(smr)==1){
      mod<-aov(x~gr1+gr2,df)
      s<-summary(mod)
    } else {
      mod<-aov(x~gr1*gr2,df)
      s<-summary(mod)
    }
    dof1<-s[[1]][2,1]
    dof2<-s[[1]][4,1]
    F<-s[[1]][2,4]
    
    x<-seq(0, 10,by = 0.1)
    df<-cbind.data.frame(x=x,y=df(x,df1 = dof1,df2 = dof2))
    
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("densità")+xlab("f")+
      ggtitle(paste("F(",round(dof1,3),",",round(dof2,3),")",sep=""))+
      theme(plot.title = element_text(size = 20, face = "bold",hjust = 0.5))  
    
    if(input$anova2test_alfa>0){
      q<-qf(input$anova2test_alfa,df1 = dof1,df2 = dof2,lower.tail = FALSE)
      req(q)
      if(q>10) q<-10
      x.b<-seq(q,10,by = 0.1)
      df.b<-cbind.data.frame(x=x.b,y=df(x.b,df1 = dof1,df2 = dof2))
      df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      gr<-gr + geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")}
    gr+geom_vline(xintercept = F,col="green")
  })
  
  output$anova2test_stat2<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if(max(smr)==1){
      mod<-aov(x~gr1+gr2,df)
      s<-summary(mod)
    } else {
      mod<-aov(x~gr1*gr2,df)
      s<-summary(mod)
    }
    dof1<-s[[1]][2,1]
    dof2<-s[[1]][4,1]
    F<-s[[1]][2,4]
    paste("statistica =",round(F,4)) 
  }) 
  
  output$anova2test_pval2<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if(max(smr)==1){
      mod<-aov(x~gr1+gr2,df)
      s<-summary(mod)
    } else {
      mod<-aov(x~gr1*gr2,df)
      s<-summary(mod)
    }
    dof1<-s[[1]][2,1]
    dof2<-s[[1]][4,1]
    p<-s[[1]][2,5]
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 

  output$anova2test_graf_distr12<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if(max(smr)==1){
      mod<-aov(x~gr1+gr2,df)
      s<-summary(mod)
    } else {
      mod<-aov(x~gr1*gr2,df)
      s<-summary(mod)
    }
    dof1<-s[[1]][3,1]
    dof2<-s[[1]][4,1]
    F<-s[[1]][3,4]
    
    x<-seq(0, 10,by = 0.1)
    df<-cbind.data.frame(x=x,y=df(x,df1 = dof1,df2 = dof2))
    
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("densità")+xlab("f")+
      ggtitle(paste("F(",round(dof1,3),",",round(dof2,3),")",sep=""))+
      theme(plot.title = element_text(size = 20, face = "bold",hjust = 0.5))  
    if(input$anova2test_alfa>0){
      q<-qf(input$anova2test_alfa,df1 = dof1,df2 = dof2,lower.tail = FALSE)
      req(q)
      if(q>10) q<-10
      x.b<-seq(q,10,by = 0.1)
      df.b<-cbind.data.frame(x=x.b,y=df(x.b,df1 = dof1,df2 = dof2))
      df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      gr<-gr + geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")}
    gr+geom_vline(xintercept = F,col="green")
  })
  
  output$anova2test_stat12<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if(max(smr)==1){
      mod<-aov(x~gr1+gr2,df)
      s<-summary(mod)
    } else {
      mod<-aov(x~gr1*gr2,df)
      s<-summary(mod)
    }
    dof1<-s[[1]][3,1]
    dof2<-s[[1]][4,1]
    F<-s[[1]][3,4]
    paste("statistica =",round(F,4)) 
  }) 
  
  output$anova2test_pval12<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if(max(smr)==1){
      mod<-aov(x~gr1+gr2,df)
      s<-summary(mod)
    } else {
      mod<-aov(x~gr1*gr2,df)
      s<-summary(mod)
    }
    dof1<-s[[1]][3,1]
    dof2<-s[[1]][4,1]
    p<-s[[1]][3,5]
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 

  output$anova2test_R<-renderPrint({
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    colnames(df)<-c(input$anova2test_variab1,input$anova2test_variab2,input$anova2test_variab3)
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if(max(smr)==1){
      frm<-as.formula(paste(input$anova2test_variab1,"~",input$anova2test_variab2,"+",input$anova2test_variab3,sep=""))
    } else {
      frm<-as.formula(paste(input$anova2test_variab1,"~",input$anova2test_variab2,"*",input$anova2test_variab3,sep=""))
    }
    mod<-aov(frm,df)
    summary(mod)
  })

  output$anova2test_graf_interaz1<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)

    gr<-ggplot()+theme_classic()+
      stat_summary(mapping =aes(x=gr1,group=gr2,color=gr2,y=x),data = df, fun.y = mean,geom="point")+
      stat_summary(mapping =aes(x=gr1,group=gr2,color=gr2,y=x),data = df,fun.y = mean,geom="line")+
      xlab(input$anova2test_variab2)+ylab(input$anova2test_variab1)+labs(color = input$anova2test_variab3)
    gr
  })

  output$anova2test_graf_interaz2<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    
    gr<-ggplot()+theme_classic()+
      stat_summary(mapping =aes(x=gr2,group=gr1,color=gr1,y=x),data = df, fun.y = mean,geom="point")+
      stat_summary(mapping =aes(x=gr2,group=gr1,color=gr1,y=x),data = df,fun.y = mean,geom="line")+
      xlab(input$anova2test_variab3)+ylab(input$anova2test_variab1)+labs(color = input$anova2test_variab2)
    gr
  })
  
  output$anova2test_qqplot1<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],gr2=dati$DS[,input$anova2test_variab3])
    colnames(df)<-c(input$anova2test_variab1,input$anova2test_variab2,input$anova2test_variab3)
    smr<-summary(int)
    if(max(smr)==1){
      frm<-as.formula(paste(input$anova2test_variab1,"~",input$anova2test_variab2,"+",input$anova2test_variab3,sep=""))
    } else {
      frm<-as.formula(paste(input$anova2test_variab1,"~",input$anova2test_variab2,"*",input$anova2test_variab3,sep=""))
    }
    mod<-aov(frm,df)
    dati<-cbind.data.frame(res=mod$residuals)
    ggplot(dati,aes(sample=res))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="quantili teorici",  y = "quantili campione")+
      theme_classic()
  })
  
  output$anova2test_shapiro1<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],gr2=dati$DS[,input$anova2test_variab3])
    colnames(df)<-c(input$anova2test_variab1,input$anova2test_variab2,input$anova2test_variab3)
    smr<-summary(int)
    if(max(smr)==1){
      frm<-as.formula(paste(input$anova2test_variab1,"~",input$anova2test_variab2,"+",input$anova2test_variab3,sep=""))
    } else {
      frm<-as.formula(paste(input$anova2test_variab1,"~",input$anova2test_variab2,"*",input$anova2test_variab3,sep=""))
    }
    mod<-aov(frm,df)
    Residui<-mod$residuals
    shapiro.test(Residui)
  })

  output$anova2test_bartlett<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],int)
    colnames(df)<-c(input$anova2test_variab1,paste(input$anova2test_variab2,".",input$anova2test_variab3,sep=""))
    smr<-summary(int)
    if(max(smr)==1){
     cat("Anova senza ripetizioni. \n")
     cat("Non abbiamo gradi di libertà per eseguire il test.")
    } else {
      frm<-as.formula(paste(input$anova2test_variab1,"~",input$anova2test_variab2,".",input$anova2test_variab3,sep=""))
      bartlett.test(frm,df) 
    }
  })
  
  output$anova2test_fligner<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],int)
    colnames(df)<-c(input$anova2test_variab1,paste(input$anova2test_variab2,".",input$anova2test_variab3,sep=""))
    smr<-summary(int)
    if(max(smr)==1){
      cat("Anova senza ripetizioni. \n")
      cat("Non abbiamo gradi di libertà per eseguire il test.")
    } else {
      frm<-as.formula(paste(input$anova2test_variab1,"~",input$anova2test_variab2,".",input$anova2test_variab3,sep=""))
      fligner.test(frm,df) 
    }
  })
  
  output$anova2test_levene<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],int)
    colnames(df)<-c(input$anova2test_variab1,paste(input$anova2test_variab2,".",input$anova2test_variab3,sep=""))
    smr<-summary(int)
    if(max(smr)==1){
      cat("Anova senza ripetizioni. \n")
      cat("Non abbiamo gradi di libertà per eseguire il test.")
    } else {
      frm<-as.formula(paste(input$anova2test_variab1,"~",input$anova2test_variab2,".",input$anova2test_variab3,sep=""))
      car::leveneTest(frm,df) 
    }
  })
  
  output$anova2test_bp<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],int)
    colnames(df)<-c(input$anova2test_variab1,paste(input$anova2test_variab2,".",input$anova2test_variab3,sep=""))
    smr<-summary(int)
    if(max(smr)==1){
      cat("Anova senza ripetizioni. \n")
      cat("Non abbiamo gradi di libertà per eseguire il test.")
    } else {
      frm<-as.formula(paste(input$anova2test_variab1,"~",input$anova2test_variab2,".",input$anova2test_variab3,sep=""))
      Modello.aov<-aov(frm,df)
      lmtest::bptest(Modello.aov)  
    }
  })
  
  output$anova2test_cochran<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr=dati$DS[,input$anova2test_variab2])
    df$gr<-as.factor(df$gr)
    colnames(df)<-c(input$anova2test_variab1,input$anova2test_variab2)
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],int)
    colnames(df)<-c(input$anova2test_variab1,paste(input$anova2test_variab2,".",input$anova2test_variab3,sep=""))
    smr<-summary(int)
    if(max(smr)==1){
      cat("Anova senza ripetizioni. \n")
      cat("Non abbiamo gradi di libertà per eseguire il test.")
    } else {
      Modello.aov<-as.formula(paste(input$anova2test_variab1,"~",input$anova2test_variab2,".",input$anova2test_variab3,sep=""))
      outliers::cochran.test(Modello.aov,df)   
    }
  })

  # Anova3 test-----------------------------------------------------------------
  output$anova3test_variab1<-renderUI({
    selectizeInput(inputId = "anova3test_variab1"," ",
                   choices = dati$var_qt)})
  
  output$anova3test_variab2<-renderUI({
    selectizeInput(inputId = "anova3test_variab2",div("Fattore 1",style="font-weight: 400;"),
                   choices = dati$var_ql)})
  
  output$anova3test_variab3<-renderUI({
    selectizeInput(inputId = "anova3test_variab3",div("Fattore 2",style="font-weight: 400;"),
                   choices = dati$var_ql[!dati$var_ql%in%input$anova3test_variab2])})
  
  output$anova3test_variab4<-renderUI({
    selectizeInput(inputId = "anova3test_variab4",div("Fattore 3",style="font-weight: 400;"),
                   choices = dati$var_ql[!(dati$var_ql%in%input$anova3test_variab2 | dati$var_ql%in%input$anova3test_variab3)])})
  
  output$anova3test_R<-renderPrint({
    req(input$anova3test_variab1%in%colnames(dati$DS))
    req(input$anova3test_variab2%in%colnames(dati$DS))
    req(input$anova3test_variab3%in%colnames(dati$DS))
    req(input$anova3test_variab4%in%colnames(dati$DS))

    df<-cbind.data.frame(x=dati$DS[,input$anova3test_variab1],gr1=dati$DS[,input$anova3test_variab2],
                         gr2=dati$DS[,input$anova3test_variab3],gr3=dati$DS[,input$anova3test_variab4])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    df$gr3<-as.factor(df$gr3)
    colnames(df)<-c(input$anova3test_variab1,input$anova3test_variab2,input$anova3test_variab3,input$anova3test_variab4)
    frm<-as.formula(paste(input$anova3test_variab1,"~",input$anova3test_variab2,"*",input$anova3test_variab3,"*",input$anova3test_variab4,sep=""))
    mod<-aov(frm,df)
    summary(mod)
  })
  
  
  output$anova3test_graf_interaz_txt<-renderText({
    req(input$anova3test_variab4%in%colnames(dati$DS))
    input$anova3test_variab4
  })

  output$anova3test_graf_interaz1<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova3test_variab1%in%colnames(dati$DS))
    req(input$anova3test_variab2%in%colnames(dati$DS))
    req(input$anova3test_variab3%in%colnames(dati$DS))
    req(input$anova3test_variab4%in%colnames(dati$DS))
    
    df<-cbind.data.frame(x=dati$DS[,input$anova3test_variab1],gr1=dati$DS[,input$anova3test_variab2],
                         gr2=dati$DS[,input$anova3test_variab3],gr3=dati$DS[,input$anova3test_variab4])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    df$gr3<-as.factor(df$gr3)
    
    gr<-ggplot()+theme_classic()+
      stat_summary(mapping =aes(x=gr1,group=gr2,color=gr2,y=x),data = df, fun.y = mean,geom="point")+
      stat_summary(mapping =aes(x=gr1,group=gr2,color=gr2,y=x),data = df,fun.y = mean,geom="line")+
      xlab(input$anova3test_variab2)+ylab(input$anova3test_variab1)+labs(color = input$anova3test_variab3)
    gr+facet_grid(~gr3)
  })
  
  output$anova3test_graf_interaz2<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova3test_variab1%in%colnames(dati$DS))
    req(input$anova3test_variab2%in%colnames(dati$DS))
    req(input$anova3test_variab3%in%colnames(dati$DS))
    req(input$anova3test_variab4%in%colnames(dati$DS))
    
    df<-cbind.data.frame(x=dati$DS[,input$anova3test_variab1],gr1=dati$DS[,input$anova3test_variab2],
                         gr2=dati$DS[,input$anova3test_variab3],gr3=dati$DS[,input$anova3test_variab4])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    df$gr3<-as.factor(df$gr3)
    
    gr<-ggplot()+theme_classic()+
      stat_summary(mapping =aes(x=gr2,group=gr1,color=gr1,y=x),data = df, fun.y = mean,geom="point")+
      stat_summary(mapping =aes(x=gr2,group=gr1,color=gr1,y=x),data = df,fun.y = mean,geom="line")+
      xlab(input$anova3test_variab3)+ylab(input$anova3test_variab1)+labs(color = input$anova3test_variab2)
    gr+facet_grid(~gr3)
  })

# Outliers-----------------------------------------------------------------  
  output$outlierstest_variab<-renderUI({
    selectizeInput(inputId = "outlierstest_variab"," ",
                   choices = dati$var_qt)})
  
  output$outlierstest_dixon_magg<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$outlierstest_variab%in%colnames(dati$DS))
    x<-dati$DS[,input$outlierstest_variab]
    outliers::dixon.test(x)
  })
  
  output$outlierstest_dixon_min<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$outlierstest_variab%in%colnames(dati$DS))
    x<-dati$DS[,input$outlierstest_variab]
    outliers::dixon.test(x,opposite = TRUE)
  })
  
  output$outlierstest_grubbs_magg<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$outlierstest_variab%in%colnames(dati$DS))
    x<-dati$DS[,input$outlierstest_variab]
    outliers::grubbs.test(x)
  })
  
  output$outlierstest_grubbs_min<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$outlierstest_variab%in%colnames(dati$DS))
    x<-dati$DS[,input$outlierstest_variab]
    outliers::grubbs.test(x,opposite = TRUE)
  })
  
# Regressione semplice-----------------------------------------------------------------
  output$regrsemplice_variaby<-renderUI({
    selectizeInput(inputId = "regrsemplice_variaby",div("Variabile dipendente (y)",style="font-weight: 400;"),
                   choices = dati$var_qt)})
  
  output$regrsemplice_variabx<-renderUI({
    selectizeInput(inputId = "regrsemplice_variabx",div("Variabile indipendente (x)",style="font-weight: 400;"),
                   choices = dati$var_qt[!dati$var_qt%in%input$regrsemplice_variaby])})  
  
  output$regrsemplice_graf<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c("x","y")
    mod<-lm(y~x,df)
    require(ggplot2)
    ggplot(data = df,aes(x=x,y=y))+xlab(input$regrsemplice_variabx)+ylab(input$regrsemplice_variaby)+
      geom_point()+theme_light()+
      stat_smooth(method = "lm", col = "red")
  })
  
  output$regrsemplice_parpt<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    mod<-lm(frm,df)
    mod$coefficients
  })
  
  output$regrsemplice_parint<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    mod<-lm(frm,df)
    confint(object = mod,level = 0.95)
  })
  
  output$regrsemplice_prev<-renderPrint({
    validate(need(nrow(dati$DS)!=0 & input$regrsemplice_prevx!="",""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    mod<-lm(frm,df)
    nd<-cbind.data.frame(x=input$regrsemplice_prevx)
    colnames(nd)<-input$regrsemplice_variabx
    predict(object = mod,newdata=nd,interval="confidence")
  })
  
  output$regrsemplice_summary<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    mod<-lm(frm,df)
    summary(mod)
  })
  
  output$regrsemplice_verifhp_ttest<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    mod<-lm(frm,df)
    t.test(mod$residuals)
  })
  
  output$regrsemplice_verifhp_grlin<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    mod<-lm(frm,df)
    df_xy<-cbind.data.frame(x=mod$fitted.values,y=mod$residuals)
    ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
      geom_hline(yintercept = 0,col="blue",lty=2)+
      ylab("residui")+xlab("valori predetti")
  })
  
  output$regrsemplice_verifhp_shapiro<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    mod<-lm(frm,df)
    residui=mod$residuals
    shapiro.test(x = residui) 
  })

  output$regrsemplice_verifhp_qqplot<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    mod<-lm(frm,df)
    df_res<-cbind.data.frame(residui=mod$residuals)
    ggplot(df_res,aes(sample=residui))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="quantili teorici",  y = "quantili campione")+
      theme_classic()
  })
  
  output$regrsemplice_verifhp_bp<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    modello<-lm(frm,df)
    lmtest::bptest(modello)
  })

  output$regrsemplice_verifhp_omosch<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    mod<-lm(frm,df)
    df_xy<-cbind.data.frame(x=mod$fitted.values,y=sqrt(abs(mod$residuals)))
    ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
      geom_hline(yintercept = 0,col="blue",lty=2)+
      ylab(expression(sqrt(residui)))+xlab("valori predetti")
  })
  
  output$regrsemplice_verifhp_dw<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    modello<-lm(frm,df)
    lmtest::dwtest(modello)
  })
  
  output$regrsemplice_verifhp_corr<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm<-as.formula(paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep=""))
    mod<-lm(frm,df)
    n<-length(mod$residuals)
    df_xy<-cbind.data.frame(x=mod$residuals[-n],y=mod$residuals[-1])
    ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
      geom_hline(yintercept = 0,col="blue",lty=2)+
      ylab(expression(residui[n]))+xlab(expression(residui[n-1]))
  })

  # Regressione polinomiale-----------------------------------------------------------------
  output$regrpoli_variaby<-renderUI({
    selectizeInput(inputId = "regrpoli_variaby",div("Variabile dipendente (y)",style="font-weight: 400;"),
                   choices = dati$var_qt)})
  
  output$regrpoli_variabx<-renderUI({
    selectizeInput(inputId = "regrpoli_variabx",div("Variabile indipendente (x)",style="font-weight: 400;"),
                   choices = dati$var_qt[!dati$var_qt%in%input$regrpoli_variaby])})  
  
  output$regrpoli_graf<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c("x","y")
    pol<-NULL
    if(input$regrpoli_grado>1){
      for(i in 2:input$regrpoli_grado){
      frm<-paste(pol,"+I(x^",i,")",sep="")
     }
    }
    frm<-as.formula(paste("y~x",pol))
    mod<-lm(frm,df)
    require(ggplot2)
    ggplot(data = df,aes(x=x,y=y))+xlab(input$regrpoli_variabx)+ylab(input$regrpoli_variaby)+
      geom_point()+theme_light()+
      stat_smooth(method = "lm", col = "red",formula = y~poly(x,input$regrpoli_grado))
  })
  
  output$regrpoli_parpt<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    mod<-lm(frm,df)
    mod$coefficients
  })
  
  output$regrpoli_parint<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    mod<-lm(frm,df)
    confint(object = mod,level = 0.95)
  })
  
  output$regrpoli_prev<-renderPrint({
    validate(need(nrow(dati$DS)!=0 & input$regrpoli_prevx!="",""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    mod<-lm(frm,df)
    nd<-cbind.data.frame(x=input$regrpoli_prevx)
    colnames(nd)<-input$regrpoli_variabx
    predict(object = mod,newdata=nd,interval="confidence")
  })
  
  output$regrpoli_summary<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    mod<-lm(frm,df)
    summary(mod)
  })
  
  output$regrpoli_verifhp_ttest<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    mod<-lm(frm,df)
    t.test(mod$residuals)
  })
  
  output$regrpoli_verifhp_grlin<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    mod<-lm(frm,df)
    df_xy<-cbind.data.frame(x=mod$fitted.values,y=mod$residuals)
    ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
      geom_hline(yintercept = 0,col="blue",lty=2)+
      ylab("residui")+xlab("valori predetti")
  })
  
  output$regrpoli_verifhp_shapiro<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    mod<-lm(frm,df)
    residui=mod$residuals
    shapiro.test(x = residui) 
  })
  
  output$regrpoli_verifhp_qqplot<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    mod<-lm(frm,df)
    df_res<-cbind.data.frame(residui=mod$residuals)
    ggplot(df_res,aes(sample=residui))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="quantili teorici",  y = "quantili campione")+
      theme_classic()
  })
  
  output$regrpoli_verifhp_bp<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    modello<-lm(frm,df)
    lmtest::bptest(modello)
  })
  
  output$regrpoli_verifhp_omosch<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    mod<-lm(frm,df)
    df_xy<-cbind.data.frame(x=mod$fitted.values,y=sqrt(abs(mod$residuals)))
    ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
      geom_hline(yintercept = 0,col="blue",lty=2)+
      ylab(expression(sqrt(residui)))+xlab("valori predetti")
  })
  
  output$regrpoli_verifhp_dw<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    modello<-lm(frm,df)
    lmtest::dwtest(modello)
  })
  
  output$regrpoli_verifhp_corr<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c(input$regrpoli_variabx,input$regrpoli_variaby)
    pol<-NULL
    if(input$regrpoli_grado>1){
      
      for(i in 2:input$regrpoli_grado){
        pol<-paste(pol,"+I(",input$regrpoli_variabx,"^",i,")",sep="")
      }
    }
    frm<-as.formula(paste(input$regrpoli_variaby,"~",input$regrpoli_variabx,pol))
    mod<-lm(frm,df)
    n<-length(mod$residuals)
    df_xy<-cbind.data.frame(x=mod$residuals[-1],y=mod$residuals[-n])
    ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
      geom_hline(yintercept = 0,col="blue",lty=2)+
      ylab(expression(residui[n]))+xlab(expression(residui[n-1]))
  }) 

# Regressione multipla-----------------------------------------------------------------
output$regrmulti_variaby<-renderUI({
  selectizeInput(inputId = "regrmulti_variaby",div("Variabile dipendente (y)",style="font-weight: 400;"),
                 choices = dati$var_qt)})

output$regrmulti_variabx<-renderUI({
  selectizeInput(inputId = "regrmulti_variabx",div("Variabili indipendenti (x)",style="font-weight: 400;"),
                 choices = dati$var_qt[!dati$var_qt%in%input$regrmulti_variaby],
                 multiple = TRUE)})  

output$regrmulti_graf<-renderPlot({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  mod<-lm(frm,df)
  require(ggplot2)
  df_coeff<-data.frame(names(mod$coefficients),mod$coefficients,confint(mod))
  ggplot(data = df_coeff,aes(x =df_coeff$names.mod.coefficients.,
                             y=df_coeff$mod.coefficients))+
    xlab("")+ylab("")+theme_light()+
    geom_bar(fill="red",stat="identity")+
    geom_errorbar(aes(ymin=df_coeff$X2.5.., ymax=df_coeff$X97.5..),
                  width=0.2, colour="green3")+
    scale_x_discrete(limits=df_coeff$names.modello.coefficients.)
})

output$regrmulti_parpt<-renderPrint({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
 mod<-lm(frm,df)
 mod$coefficients
})

output$regrmulti_parint<-renderPrint({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  mod<-lm(frm,df)
  confint(object = mod,level = 0.95)
})

output$regrmulti_prev<-renderPrint({
  validate(need(nrow(dati$DS)!=0 & length(as.numeric(unlist(strsplit(input$regrmulti_prevx," "))))==length(input$regrmulti_variabx),""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  mod<-lm(frm,df)
  x<- as.numeric(unlist(strsplit(input$regrmulti_prevx," ")))
  nd<-rbind.data.frame(x)
  colnames(nd)<-input$regrmulti_variabx
  predict(object = mod,newdata=nd,interval="confidence")
})

output$regrmulti_summary<-renderPrint({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  mod<-lm(frm,df)
  summary(mod,cor=TRUE)
})

output$regrmulti_verifhp_ttest<-renderPrint({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  mod<-lm(frm,df)
  t.test(mod$residuals)
})

output$regrmulti_verifhp_grlin<-renderPlot({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  mod<-lm(frm,df)
  df_xy<-cbind.data.frame(x=mod$fitted.values,y=mod$residuals)
  ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
    geom_hline(yintercept = 0,col="blue",lty=2)+
    ylab("residui")+xlab("valori predetti")
})

output$regrmulti_verifhp_shapiro<-renderPrint({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  mod<-lm(frm,df)
  residui=mod$residuals
  shapiro.test(x = residui) 
})

output$regrmulti_verifhp_qqplot<-renderPlot({
  require(ggplot2)
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  mod<-lm(frm,df)
  df_res<-cbind.data.frame(residui=mod$residuals)
  ggplot(df_res,aes(sample=residui))+
    stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
    labs(x="quantili teorici",  y = "quantili campione")+
    theme_classic()
})

output$regrmulti_verifhp_bp<-renderPrint({
  require(ggplot2)
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  modello<-lm(frm,df)
  lmtest::bptest(modello)
})

output$regrmulti_verifhp_omosch<-renderPlot({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  mod<-lm(frm,df)
  df_xy<-cbind.data.frame(x=mod$fitted.values,y=sqrt(abs(mod$residuals)))
  ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
    geom_hline(yintercept = 0,col="blue",lty=2)+
    ylab(expression(sqrt(residui)))+xlab("valori predetti")
})

output$regrmulti_verifhp_dw<-renderPrint({
  require(ggplot2)
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  modello<-lm(frm,df)
  lmtest::dwtest(modello)
})

output$regrmulti_verifhp_corr<-renderPlot({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  m<-length(input$regrmulti_variabx)
  lin<-NULL
  if(m>1){
    for(i in 2:m){
      if(input$regrmulti_addi==1){
        lin<-paste(lin,"+",input$regrmulti_variabx[i])
      }else{
        lin<-paste(lin,"*",input$regrmulti_variabx[i])
      }
    }
  }
  frm<-formula(paste(input$regrmulti_variaby,"~",input$regrmulti_variabx[1],lin))
  mod<-lm(frm,df)
  n<-length(mod$residuals)
  df_xy<-cbind.data.frame(x=mod$residuals[-1],y=mod$residuals[-n])
  ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
    geom_hline(yintercept = 0,col="blue",lty=2)+
    ylab(expression(residui[n]))+xlab(expression(residui[n-1]))
}) 


# Normale -----------------------------------------------------------------

  output$graf_norm_a<-renderUI({
    validate(need(input$graf_norm_area!="nessuna",""))
    sliderInput(inputId="graf_norm_a",label = "a",min = -10,max = 10,value = 0,
                step=0.1)
  })
  
  output$graf_norm_b<-renderUI({
    validate(need(input$graf_norm_area=="both" | input$graf_norm_area=="middle",""))
    sliderInput(inputId="graf_norm_b",label = "b",min = -10,max = 10,value = 0,
                step=0.1)
  })
  
  output$graf_norm_camp<-renderUI({
    validate(need(input$graf_norm_area=="nessuna",""))
    checkboxInput("graf_norm_camp", label = "Campione", value = FALSE)
  })
  
  output$graf_norm_camp_num<-renderUI({
    validate(need(input$graf_norm_camp==TRUE,""))
    sliderInput(inputId="graf_norm_camp_num",label = "Numerosità campione",min = 1,max = 10000,value = 10,
                step=10)
  })
  
  output$graf_normale<-renderPlot({
    require(ggplot2)
    x<-seq(-10, 10,by = 0.1)
    df<-cbind.data.frame(x=x,y=dnorm(x,mean=input$graf_norm_media,sd=input$graf_norm_ds))
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("densità")+xlab("x")
    if(input$graf_norm_area=="nessuna" & length(input$graf_norm_camp)!=0){
     if(input$graf_norm_camp==TRUE & !is.null(input$graf_norm_camp_num)){
      df_ist<-as.data.frame(x = rnorm(n = input$graf_norm_camp_num,mean=input$graf_norm_media,sd=input$graf_norm_ds))
      names(df_ist)="x"
       gr +
        geom_histogram(df_ist, mapping=aes(x = x,y = ..density..),fill="blue",col="white",
                       binwidth =(max(df_ist$x)-min(df_ist$x))/sqrt(nrow(df_ist)) )
      } else {
        gr
      }
    } else if (input$graf_norm_area=="lower" & !is.null(input$graf_norm_a)){
      x.a<-seq(-10, input$graf_norm_a,by = 0.1)
      df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =input$graf_norm_media,sd = input$graf_norm_ds))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
    } else if (input$graf_norm_area=="upper" & !is.null(input$graf_norm_a)){
      x.a<-seq(input$graf_norm_a,10,by = 0.1)
      df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =input$graf_norm_media,sd = input$graf_norm_ds))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
    } else if (input$graf_norm_area=="both" & !is.null(input$graf_norm_a) & !is.null(input$graf_norm_b)){
      if(input$graf_norm_b<input$graf_norm_a){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Errore: b deve essere maggiore di a",col="red",cex=2)
      } else {
         x.a<-seq(-10, input$graf_norm_a,by = 0.1)
      x.b<-seq(input$graf_norm_b,10,by = 0.1)
      df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =input$graf_norm_media,sd = input$graf_norm_ds))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =input$graf_norm_media,sd = input$graf_norm_ds))
      df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0))
      gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
        geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")     
      }
    } else if (input$graf_norm_area=="middle" & !is.null(input$graf_norm_a) & !is.null(input$graf_norm_b)){
      if(input$graf_norm_b<input$graf_norm_a){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Errore: b deve essere maggiore di a",col="red",cex=2)
      } else {
      x.ab<-seq(input$graf_norm_a,input$graf_norm_b,by = 0.1)
      df.ab<-cbind.data.frame(x=x.ab,y=dnorm(x.ab,mean =input$graf_norm_media,sd = input$graf_norm_ds))
      df.ab<-rbind(c(min(x.ab), 0), df.ab, c(max(x.ab), 0))
      gr+geom_polygon(df.ab,mapping = aes(x=x,y=y),fill="blue")
      }
    }
  })  
      
  output$norm_txt<-renderText({
    validate(need(!is.null(input$graf_norm_a),""))
    if (input$graf_norm_area=="lower" & !is.null(input$graf_norm_a)){
      "P[x<a]"
    } else if (input$graf_norm_area=="upper" & !is.null(input$graf_norm_a)){
      "P[x>a]"
    } else if (input$graf_norm_area=="both" & !is.null(input$graf_norm_a) & !is.null(input$graf_norm_b)){
      "P[x<a e x>b]"
    } else if (input$graf_norm_area=="middle" & !is.null(input$graf_norm_a) & !is.null(input$graf_norm_b)){
      "P[a<x<b]"
    }
  })
    
  output$norm_testo<-renderPrint({
   validate(need(!is.null(input$graf_norm_a),""))
    if (input$graf_norm_area=="lower" & !is.null(input$graf_norm_a)){
      pnorm(q = input$graf_norm_a,mean =input$graf_norm_media,sd = input$graf_norm_ds,lower.tail = TRUE)
    } else if (input$graf_norm_area=="upper" & !is.null(input$graf_norm_a)){
      pnorm(q = input$graf_norm_a,mean =input$graf_norm_media,sd = input$graf_norm_ds,lower.tail = FALSE)
    } else if (input$graf_norm_area=="both" & !is.null(input$graf_norm_a) & !is.null(input$graf_norm_b)){
      pnorm(q = input$graf_norm_a,mean =input$graf_norm_media,sd = input$graf_norm_ds)+
      pnorm(q = input$graf_norm_b,mean =input$graf_norm_media,sd = input$graf_norm_ds,lower.tail = FALSE)
    } else if (input$graf_norm_area=="middle" & !is.null(input$graf_norm_a) & !is.null(input$graf_norm_b)){
      "P[a<x<b]"
      pnorm(q = input$graf_norm_b,mean =input$graf_norm_media,sd = input$graf_norm_ds)-
      pnorm(q = input$graf_norm_a,mean =input$graf_norm_media,sd = input$graf_norm_ds) 
    }
  })
  
# t student ---------------------------------------------------------------

  output$graf_tstudent_a<-renderUI({
    validate(need(input$graf_tstudent_area!="nessuna",""))
    sliderInput(inputId="graf_tstudent_a",label = "a",min = -10,max = 10,value = 0,
                step=0.1)
  })
  
  output$graf_tstudent_b<-renderUI({
    validate(need(input$graf_tstudent_area=="both" | input$graf_tstudent_area=="middle",""))
    sliderInput(inputId="graf_tstudent_b",label = "b",min = -10,max = 10,value = 0,
                step=0.1)
  })
  
  output$graf_tstudent_camp<-renderUI({
    validate(need(input$graf_tstudent_area=="nessuna",""))
    checkboxInput("graf_tstudent_camp", label = "Campione", value = FALSE)
  })
  
  output$graf_tstudent_camp_num<-renderUI({
    validate(need(input$graf_tstudent_camp==TRUE,""))
    sliderInput(inputId="graf_tstudent_camp_num",label = "Numerosità campione",min = 1,max = 10000,value = 10,
                step=10)
  })
  
  output$graf_tstudent<-renderPlot({
    require(ggplot2)
    x<-seq(-10, 10,by = 0.1)
    df<-cbind.data.frame(x=x,y=dt(x,df = input$graf_tstudent_dof))
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("densità")+xlab("t")
    if(input$graf_tstudent_area=="nessuna" & length(input$graf_tstudent_camp)!=0){
      if(input$graf_tstudent_camp==TRUE & !is.null(input$graf_tstudent_camp_num)){
        df_ist<-as.data.frame(x = rt(n = input$graf_tstudent_camp_num,df =input$graf_tstudent_dof ))
        names(df_ist)="x"
        gr +
          geom_histogram(df_ist, mapping=aes(x = x,y = ..density..),fill="blue",col="white",
                         binwidth =(max(df_ist$x)-min(df_ist$x))/sqrt(nrow(df_ist)) )
      } else {
        gr
      }
    } else if (input$graf_tstudent_area=="lower" & !is.null(input$graf_tstudent_a)){
      x.a<-seq(-10, input$graf_tstudent_a,by = 0.1)
      df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = input$graf_tstudent_dof))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
    } else if (input$graf_tstudent_area=="upper" & !is.null(input$graf_tstudent_a)){
      x.a<-seq(input$graf_tstudent_a,10,by = 0.1)
      df.a<-cbind.data.frame(x=x.a,y=dt(x.a,input$graf_tstudent_dof))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
    } else if (input$graf_tstudent_area=="both" & !is.null(input$graf_tstudent_a) & !is.null(input$graf_tstudent_b)){
      if(input$graf_tstudent_b<input$graf_tstudent_a){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Errore: b deve essere maggiore di a",col="red",cex=2)
      } else {
        x.a<-seq(-10, input$graf_tstudent_a,by = 0.1)
        x.b<-seq(input$graf_tstudent_b,10,by = 0.1)
        df.a<-cbind.data.frame(x=x.a,y=dt(x.a,input$graf_tstudent_dof))
        df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        df.b<-cbind.data.frame(x=x.b,y=dt(x.b,input$graf_tstudent_dof))
        df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0))
        gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")     
      }
    } else if (input$graf_tstudent_area=="middle" & !is.null(input$graf_tstudent_a) & !is.null(input$graf_tstudent_b)){
      if(input$graf_tstudent_b<input$graf_tstudent_a){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Errore: b deve essere maggiore di a",col="red",cex=2)
      } else {
        x.ab<-seq(input$graf_tstudent_a,input$graf_tstudent_b,by = 0.1)
        df.ab<-cbind.data.frame(x=x.ab,y=dt(x.ab,input$graf_tstudent_dof))
        df.ab<-rbind(c(min(x.ab), 0), df.ab, c(max(x.ab), 0))
        gr+geom_polygon(df.ab,mapping = aes(x=x,y=y),fill="blue")
      }
    }
  }) 

  output$tstudent_txt<-renderText({
    validate(need(!is.null(input$graf_tstudent_a),""))
    if (input$graf_tstudent_area=="lower" & !is.null(input$graf_tstudent_a)){
      "P[t<a]"
    } else if (input$graf_tstudent_area=="upper" & !is.null(input$graf_tstudent_a)){
      "P[t>a]"
    } else if (input$graf_tstudent_area=="both" & !is.null(input$graf_tstudent_a) & !is.null(input$graf_tstudent_b)){
      "P[t<a e t>b]"
    } else if (input$graf_tstudent_area=="middle" & !is.null(input$graf_tstudent_a) & !is.null(input$graf_tstudent_b)){
      "P[a<t<b]"
    }
  })
  
  output$tstudent_testo<-renderPrint({
    validate(need(!is.null(input$graf_tstudent_a),""))
    if (input$graf_tstudent_area=="lower" & !is.null(input$graf_tstudent_a)){
      pt(q = input$graf_tstudent_a,df =input$graf_tstudent_dof,lower.tail = TRUE)
    } else if (input$graf_tstudent_area=="upper" & !is.null(input$graf_tstudent_a)){
      pt(q = input$graf_tstudent_a,df =input$graf_tstudent_dof,lower.tail = FALSE)
    } else if (input$graf_tstudent_area=="both" & !is.null(input$graf_tstudent_a) & !is.null(input$graf_tstudent_b)){
      pt(q = input$graf_tstudent_a,df =input$graf_tstudent_dof)+
        pt(q = input$graf_tstudent_b,df =input$graf_tstudent_dof,lower.tail = FALSE)
    } else if (input$graf_tstudent_area=="middle" & !is.null(input$graf_tstudent_a) & !is.null(input$graf_tstudent_b)){
      pt(q = input$graf_tstudent_b,df =input$graf_tstudent_dof)-
        pt(q = input$graf_tstudent_a,df =input$graf_tstudent_dof) 
    }
  }) 

# chi quadro --------------------------------------------------------------

  output$graf_chi_a<-renderUI({
    validate(need(input$graf_chi_area!="nessuna",""))
    sliderInput(inputId="graf_chi_a",label = "a",min = 0,max = 20,value = 5,
                step=0.1)
  })
  
  output$graf_chi_b<-renderUI({
    validate(need(input$graf_chi_area=="both" | input$graf_chi_area=="middle",""))
    sliderInput(inputId="graf_chi_b",label = "b",min = 0,max = 20,value = 15,
                step=0.1)
  })
  
  output$graf_chi_camp<-renderUI({
    validate(need(input$graf_chi_area=="nessuna",""))
    checkboxInput("graf_chi_camp", label = "Campione", value = FALSE)
  })
  
  output$graf_chi_camp_num<-renderUI({
    validate(need(input$graf_chi_camp==TRUE,""))
    sliderInput(inputId="graf_chi_camp_num",label = "Numerosità campione",min = 1,max = 10000,value = 10,
                step=10)
  })
  
  output$graf_chi<-renderPlot({
    require(ggplot2)
    x<-seq(0, 20,by = 0.1)
    df<-cbind.data.frame(x=x,y=dchisq(x,df = input$graf_chi_dof))
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("densità")+xlab(expression(chi^2))
    if(input$graf_chi_area=="nessuna" & length(input$graf_chi_camp)!=0){
      if(input$graf_chi_camp==TRUE & !is.null(input$graf_chi_camp_num)){
        df_ist<-as.data.frame(x = rchisq(n = input$graf_chi_camp_num,df =input$graf_chi_dof ))
        names(df_ist)="x"
        gr +
          geom_histogram(df_ist, mapping=aes(x = x,y = ..density..),fill="blue",col="white",
                         binwidth =(max(df_ist$x)-min(df_ist$x))/sqrt(nrow(df_ist)) )
      } else {
        gr
      }
    } else if (input$graf_chi_area=="lower" & !is.null(input$graf_chi_a)){
      x.a<-seq(0, input$graf_chi_a,by = 0.1)
      df.a<-cbind.data.frame(x=x.a,y=dchisq(x.a,df = input$graf_chi_dof))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
    } else if (input$graf_chi_area=="upper" & !is.null(input$graf_chi_a)){
      x.a<-seq(input$graf_chi_a,20,by = 0.1)
      df.a<-cbind.data.frame(x=x.a,y=dchisq(x.a,input$graf_chi_dof))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
    } else if (input$graf_chi_area=="both" & !is.null(input$graf_chi_a) & !is.null(input$graf_chi_b)){
      if(input$graf_chi_b<input$graf_chi_a){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Errore: b deve essere maggiore di a",col="red",cex=2)
      } else {
        x.a<-seq(0, input$graf_chi_a,by = 0.1)
        x.b<-seq(input$graf_chi_b,20,by = 0.1)
        df.a<-cbind.data.frame(x=x.a,y=dchisq(x.a,input$graf_chi_dof))
        df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        df.b<-cbind.data.frame(x=x.b,y=dchisq(x.b,input$graf_chi_dof))
        df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0))
        gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")     
      }
    } else if (input$graf_chi_area=="middle" & !is.null(input$graf_chi_a) & !is.null(input$graf_chi_b)){
      if(input$graf_chi_b<input$graf_chi_a){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Errore: b deve essere maggiore di a",col="red",cex=2)
      } else {
        x.ab<-seq(input$graf_chi_a,input$graf_chi_b,by = 0.1)
        df.ab<-cbind.data.frame(x=x.ab,y=dchisq(x.ab,input$graf_chi_dof))
        df.ab<-rbind(c(min(x.ab), 0), df.ab, c(max(x.ab), 0))
        gr+geom_polygon(df.ab,mapping = aes(x=x,y=y),fill="blue")
      }
    }
  }) 
  
  output$chi_txt<-renderUI({
    validate(need(!is.null(input$graf_chi_a),""))
    if (input$graf_chi_area=="lower" & !is.null(input$graf_chi_a)){
      HTML("P[&chi;<sup>2</sup> < a]")
    } else if (input$graf_chi_area=="upper" & !is.null(input$graf_chi_a)){
      HTML("P[&chi;<sup>2</sup> > a]")
    } else if (input$graf_chi_area=="both" & !is.null(input$graf_chi_a) & !is.null(input$graf_chi_b)){
      HTML("P[&chi;<sup>2</sup> < a e &chi;<sup>2</sup> < b]")
    } else if (input$graf_chi_area=="middle" & !is.null(input$graf_chi_a) & !is.null(input$graf_chi_b)){
      HTML(" P[a < &chi;<sup>2</sup> < b]")
    }
  })
  
  output$chi_testo<-renderPrint({
    validate(need(!is.null(input$graf_chi_a),""))
    if (input$graf_chi_area=="lower" & !is.null(input$graf_chi_a)){
      pchisq(q = input$graf_chi_a,df =input$graf_chi_dof,lower.tail = TRUE)
    } else if (input$graf_chi_area=="upper" & !is.null(input$graf_chi_a)){
      pchisq(q = input$graf_chi_a,df =input$graf_chi_dof,lower.tail = FALSE)
    } else if (input$graf_chi_area=="both" & !is.null(input$graf_chi_a) & !is.null(input$graf_chi_b)){
      pchisq(q = input$graf_chi_a,df =input$graf_chi_dof)+
        pchisq(q = input$graf_chi_b,df =input$graf_chi_dof,lower.tail = FALSE)
    } else if (input$graf_chi_area=="middle" & !is.null(input$graf_chi_a) & !is.null(input$graf_chi_b)){
      pchisq(q = input$graf_chi_b,df =input$graf_chi_dof)-
        pchisq(q = input$graf_chi_a,df =input$graf_chi_dof) 
    }
  }) 
  
# f --------------------------------------------------------------
  
  output$graf_f_a<-renderUI({
    validate(need(input$graf_f_area!="nessuna",""))
    sliderInput(inputId="graf_f_a",label = "a",min = 0,max = 20,value = 5,
                step=0.1)
  })
  
  output$graf_f_b<-renderUI({
    validate(need(input$graf_f_area=="both" | input$graf_f_area=="middle",""))
    sliderInput(inputId="graf_f_b",label = "b",min = 0,max = 20,value = 15,
                step=0.1)
  })
  
  output$graf_f_camp<-renderUI({
    validate(need(input$graf_f_area=="nessuna",""))
    checkboxInput("graf_f_camp", label = "Campione", value = FALSE)
  })
  
  output$graf_f_camp_num<-renderUI({
    validate(need(input$graf_f_camp==TRUE,""))
    sliderInput(inputId="graf_f_camp_num",label = "Numerosità campione",min = 1,max = 10000,value = 10,
                step=10)
  })
  
  output$graf_f<-renderPlot({
    require(ggplot2)
    x<-seq(0, 20,by = 0.1)
    df<-cbind.data.frame(x=x,y=df(x,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2))
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("densità")+xlab("f")
    if(input$graf_f_area=="nessuna" & length(input$graf_f_camp)!=0){
      if(input$graf_f_camp==TRUE & !is.null(input$graf_f_camp_num)){
        df_ist<-as.data.frame(x = rf(n = input$graf_f_camp_num,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2 ))
        names(df_ist)="x"
        gr +
          geom_histogram(df_ist, mapping=aes(x = x,y = ..density..),fill="blue",col="white",
                         binwidth =(max(df_ist$x)-min(df_ist$x))/sqrt(nrow(df_ist)) )
      } else {
        gr
      }
    } else if (input$graf_f_area=="lower" & !is.null(input$graf_f_a)){
      x.a<-seq(0, input$graf_f_a,by = 0.1)
      df.a<-cbind.data.frame(x=x.a,y=df(x.a,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
    } else if (input$graf_f_area=="upper" & !is.null(input$graf_f_a)){
      x.a<-seq(input$graf_f_a,20,by = 0.1)
      df.a<-cbind.data.frame(x=x.a,y=df(x.a,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
    } else if (input$graf_f_area=="both" & !is.null(input$graf_f_a) & !is.null(input$graf_f_b)){
      if(input$graf_f_b<input$graf_f_a){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Errore: b deve essere maggiore di a",col="red",cex=2)
      } else {
        x.a<-seq(0, input$graf_f_a,by = 0.1)
        x.b<-seq(input$graf_f_b,20,by = 0.1)
        df.a<-cbind.data.frame(x=x.a,y=df(x.a,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2))
        df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        df.b<-cbind.data.frame(x=x.b,y=df(x.b,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2))
        df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0))
        gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")     
      }
    } else if (input$graf_f_area=="middle" & !is.null(input$graf_f_a) & !is.null(input$graf_f_b)){
      if(input$graf_f_b<input$graf_f_a){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Errore: b deve essere maggiore di a",col="red",cex=2)
      } else {
        x.ab<-seq(input$graf_f_a,input$graf_f_b,by = 0.1)
        df.ab<-cbind.data.frame(x=x.ab,y=df(x.ab,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2))
        df.ab<-rbind(c(min(x.ab), 0), df.ab, c(max(x.ab), 0))
        gr+geom_polygon(df.ab,mapping = aes(x=x,y=y),fill="blue")
      }
    }
  }) 
  
  output$f_txt<-renderUI({
    validate(need(!is.null(input$graf_f_a),""))
    if (input$graf_f_area=="lower" & !is.null(input$graf_f_a)){
      HTML("P[F < a]")
    } else if (input$graf_f_area=="upper" & !is.null(input$graf_f_a)){
      HTML("P[F > a]")
    } else if (input$graf_f_area=="both" & !is.null(input$graf_f_a) & !is.null(input$graf_f_b)){
      HTML("P[F < a e &chi;F < b]")
    } else if (input$graf_f_area=="middle" & !is.null(input$graf_f_a) & !is.null(input$graf_f_b)){
      HTML(" P[ a< F < b]")
    }
  })
  
  output$f_testo<-renderPrint({
    validate(need(!is.null(input$graf_f_a),""))
    if (input$graf_f_area=="lower" & !is.null(input$graf_f_a)){
      pf(q = input$graf_f_a,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2,lower.tail = TRUE)
    } else if (input$graf_f_area=="upper" & !is.null(input$graf_f_a)){
      pf(q = input$graf_f_a,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2,lower.tail = FALSE)
    } else if (input$graf_f_area=="both" & !is.null(input$graf_f_a) & !is.null(input$graf_f_b)){
      pf(q = input$graf_f_a,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2)+
        pf(q = input$graf_f_b,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2,lower.tail = FALSE)
    } else if (input$graf_f_area=="middle" & !is.null(input$graf_f_a) & !is.null(input$graf_f_b)){
      pf(q = input$graf_f_b,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2)-
        pf(q = input$graf_f_a,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2) 
    }
  }) 

# Teorema del limite centrale ---------------------------------------------

  output$graf_lc_pop<-renderPlot({
    require(ggplot2)
    gr=as.factor(c(-1,1))
    y=dbinom(x=c(0,1),prob = input$graf_lc_prob,size = 1)*100
    df<-cbind.data.frame(gr,y)
   ggplot(df,mapping = aes(gr))+geom_bar(aes(weight = y),fill="blue",width=0.005)+
     theme_classic()+xlab("x")+ylab("probabilità (%)")
  })
  
  output$lc_pop_media<-renderText({
    paste("media =",2*input$graf_lc_prob-1)
  })
  
  output$lc_pop_var<-renderText({
    paste("varianza =",4*input$graf_lc_prob*(1-input$graf_lc_prob))
  })
  
  output$graf_lc_titolo<-renderText({
   paste("distribuzione della media di",input$graf_lc_numta_camp,"variabili")
   })
  
  output$graf_lc<-renderPlot({
    require(ggplot2)
    df<-c(NULL)
    for(i in 1: input$graf_lc_num_camp){
      df[i]<-mean(rbinom(n = input$graf_lc_numta_camp,size = 1,prob = input$graf_lc_prob))
    }
    df<-as.data.frame(df)
    
    df<-2*df-1
    names(df)<-"x"

    ggplot()+theme_classic()+
      geom_histogram(df, mapping=aes(x = x,y = ..density..),fill="blue",col="white",
                     
                    # binwidth =(max(df$x)-min(df$x))/sqrt(nrow(df))
                    binwidth =0.01
                     )+
        xlab(expression(bar(x)))+ylab("probalità (%)")+xlim(-1.1,1.1)
  })
  
 
# Intervallo di confidenza ---------------------------------------------------------------- 
  int_conf_camp<-reactive({
    input$resample
    set.seed(as.numeric(Sys.time()))
    rnorm(n = input$int_conf_numta_camp,mean = input$int_conf_media,sd = input$int_conf_ds)
  })
  
  output$int_conf_graf_distr<-renderPlot({
    require(ggplot2)
    x<-seq(-6, 6,by = 0.1)
    if(input$int_conf_var==1){
      df<-cbind.data.frame(x=x,y=dnorm(x,mean=0,sd=1))
      if(input$int_conf_alfa>0){
       q<-qnorm(input$int_conf_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
       if(q>6) q<-6
       x.b<-seq(q,6,by = 0.1)
       x.a<- -x.b[order(x.b,decreasing = TRUE)]
       df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =0,sd = 1))
       df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
       df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =0,sd = 1))
       df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
       }
 
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("densità")+xlab(expression(frac(bar(x)-mu,sigma * sqrt(1/m))))+ggtitle("N(0,1)")+
      theme(plot.title = element_text(size = 20, face = "bold",
                                      hjust = 0.5))
    
    if(input$int_conf_alfa>0){
      gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
        geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
      gr+geom_vline(xintercept = (mean(int_conf_camp())-input$int_conf_media)/(input$int_conf_ds*sqrt(1/input$int_conf_numta_camp)),col="green")
    } else {
      dof<-length(int_conf_camp())-1
      if (dof==0){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"   Ci vuole almeno 1 grado di libertà \n
        numerosità del campione almeno 2 \n",col="red",cex=2)
      } else {
       ds<-sd(int_conf_camp())
       df<-cbind.data.frame(x=x,y=dt(x,df = dof))
       if(input$int_conf_alfa>0){
         q<-qt(input$int_conf_alfa/2,df = dof,lower.tail = FALSE)
         if(q>6) q<-6
         x.b<-seq(q,6,by = 0.1)
         x.a<- -x.b[order(x.b,decreasing = TRUE)]
         df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
         df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
         df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
         df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
       }
      
      gr<-ggplot() +theme_classic()+
        geom_line(data = df,mapping = aes(x=x,y=y))+
        ylab("densità")+xlab(expression(frac(bar(x)-mu,s * sqrt(1/m))))+ggtitle(paste("t(",dof,")",sep=""))+
        theme(plot.title = element_text(size = 20, face = "bold",
                                        hjust = 0.5))
      
      if(input$int_conf_alfa>0){
        gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
      
      gr+geom_vline(xintercept = (mean(int_conf_camp())-input$int_conf_media)/(ds*sqrt(1/input$int_conf_numta_camp)),col="green") 
      }
    }
  })
  
  output$int_conf_media_camp<-renderText({
    paste("media campionaria =",round(mean(int_conf_camp()),3))
  })
  
  output$int_conf_sd_camp<-renderText({
    validate(need(input$int_conf_var=="2",""))
    paste("dev. standard campionaria =",round(sd(int_conf_camp()),2))
  })
  
  output$int_conf_stat<-renderText({ 
    if(input$int_conf_var==1){
      st<-(mean(int_conf_camp())-input$int_conf_media)/(input$int_conf_ds*sqrt(1/input$int_conf_numta_camp))
      paste("statistica =",round(st,3))
    } else {
      st<-(mean(int_conf_camp())-input$int_conf_media)/(sd(int_conf_camp())*sqrt(1/input$int_conf_numta_camp))
      paste("statistica =",round(st,3))
    }
    })
  
  output$int_conf_graf_ic<-renderPlot({
    validate(need(input$int_conf_alfa>0,""))
    library(lattice)
    media<-mean(int_conf_camp())
    m<-length(int_conf_camp())
    if(input$int_conf_var==1){
      s<-input$int_conf_ds
      q<-qnorm(input$int_conf_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
    } else {
      s<-sd(int_conf_camp())
      q<-qt(input$int_conf_alfa/2,df = m-1,lower.tail = FALSE)
    }
    x=media;y=0
    gr<-xyplot(y~x,type="n",xlim=c(input$int_conf_media - 4*q*s*sqrt(1/m),
                                   input$int_conf_media + 4*q*s*sqrt(1/m)),ylim=c(-1,2),
           par.settings=list(axis.line=list(col=NA), axis.text=list(col=NA)),xlab=NULL, ylab=NULL)
    print(gr)
    trellis.focus("panel", 1, 1, highlight=FALSE)
    panel.arrows(input$int_conf_media - 4*q*s*sqrt(1/m),0,
                 input$int_conf_media + 4*q*s*sqrt(1/m),0,angle=20,length=0,lwd=0.1)
    panel.text(x=input$int_conf_media,y=-0.3,expression(mu))
    panel.arrows(input$int_conf_media,0,input$int_conf_media,2,lty=2,length=0)
    
    panel.arrows(media,1,media-q*s*sqrt(1/m),1,angle=90,length=0.05,col="green4")
    panel.arrows(media,1,media+q*s*sqrt(1/m),1,angle=90,length=0.05,col="green4")
    trellis.unfocus()
  })
  
  
  output$int_conf_IC_txt<-renderText({
    validate(need(input$int_conf_alfa>0," "))
    "Intervallo di confidenza"
  })
  
  output$int_conf_ic_inf<-renderText({
    validate(need(input$int_conf_alfa>0," "))
    media<-mean(int_conf_camp())
    m<-length(int_conf_camp())
    if(input$int_conf_var==1){
      s<-1
      q<-qnorm(input$int_conf_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
    } else {
      s<-sd(int_conf_camp())
      q<-qt(input$int_conf_alfa/2,df = m-1,lower.tail = FALSE)
    }
    paste("estremo inferiore =",round(media-q*s*sqrt(1/m),3))
  })
  
  
  output$int_conf_ic_sup<-renderText({
    validate(need(input$int_conf_alfa>0," "))
    media<-mean(int_conf_camp())
    m<-length(int_conf_camp())
    if(input$int_conf_var==1){
      s<-1
      q<-qnorm(input$int_conf_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
    } else {
      s<-sd(int_conf_camp())
      q<-qt(input$int_conf_alfa/2,df = m-1,lower.tail = FALSE)
    }
    paste("estremo superiore =",round(media+q*s*sqrt(1/m),3))
  })
  
  
# test ipotesi -------------------------------------------------------------- 
  h0_camp<-reactive({
    input$h0_resample
    set.seed(as.numeric(Sys.time()))
    rnorm(n = input$h0_numta_camp,mean = input$h0_media,sd = input$h0_ds)
  })
  
  output$h0_Test1<-renderText({
    validate(need(input$h0_var==1,""))
    "z-test"
  })
  
  output$h0_Test2<-renderText({
    validate(need(input$h0_var==2,""))
    "t-test"
  })
  
  output$h0_H0<-renderUI({
    req(input$h0_media)
    numericInput("h0_H0",label = "Media ipotizzata",
                 value=input$h0_media,width = "40%")
  })

  output$h0_H0_txt = renderUI({        
    HTML("H<SUB>0</SUB>: &mu; =", input$h0_H0,"<p> H<SUB>1</SUB>: &mu; &ne;",input$h0_H0)
  })
  
  output$h0_graf_distr<-renderPlot({
    require(ggplot2)
    
    vrb<-as.data.frame(h0_camp())
    
    x<-seq(-6, 6,by = 0.1)
    if(input$h0_var==1){
      df<-cbind.data.frame(x=x,y=dnorm(x,mean=0,sd=1))
      if(input$h0_alfa>0){
        q<-qnorm(input$h0_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
        if(q>6) q<-6
        x.b<-seq(q,6,by = 0.1)
        x.a<- -x.b[order(x.b,decreasing = TRUE)]
        df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =0,sd = 1))
        df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =0,sd = 1))
        df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      }
      gr<-ggplot() +theme_classic()+
        geom_line(data = df,mapping = aes(x=x,y=y))+
        ylab("densità")+xlab(expression(frac(bar(x)-mu,sigma * sqrt(1/m))))+ggtitle("N(0,1)")+
        theme(plot.title = element_text(size = 20, face = "bold",
                                        hjust = 0.5))
      
      if(input$h0_alfa>0){
        gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 

      if(input$h0_graf_pvalue){
        q<-(mean(vrb[,1])-input$h0_H0)/(input$h0_ds*sqrt(1/nrow(vrb)))
        q<-abs(q)
        x.b<-seq(q,6,by = 0.1)
        x.a<- -x.b[order(x.b,decreasing = TRUE)]
        df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =0,sd = 1))
        df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =0,sd = 1))
        df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="green")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="green")
      }
      
      gr+geom_vline(xintercept = (mean(vrb[,1])-input$h0_H0)/(input$h0_ds*sqrt(1/nrow(vrb))),col="green")
      
    } else {
      dof<-nrow(vrb)-1
      if (dof==0){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"   Ci vuole almeno 1 grado di libertà \n
             numerosità del campione almeno 2 \n",col="red",cex=2)
      } else {
        ds<-sd(vrb[,1])
        df<-cbind.data.frame(x=x,y=dt(x,df = dof))
        if(input$h0_alfa>0){
          q<-qt(input$h0_alfa/2,df = dof,lower.tail = FALSE)
          if(q>6) q<-6
          x.b<-seq(q,6,by = 0.1)
          x.a<- -x.b[order(x.b,decreasing = TRUE)]
          df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
          df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
          df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
          df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        }
        
        gr<-ggplot() +theme_classic()+
          geom_line(data = df,mapping = aes(x=x,y=y))+
          ylab("densità")+xlab(expression(frac(bar(x)-mu,s * sqrt(1/m))))+ggtitle(paste("t(",dof,")",sep=""))+
          theme(plot.title = element_text(size = 20, face = "bold",
                                          hjust = 0.5))
        
        if(input$h0_alfa>0){
          gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
            geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
        
        if(input$h0_graf_pvalue){
          q<-(mean(vrb[,1])-input$h0_H0)/(ds*sqrt(1/nrow(vrb)))
          q<-abs(q)
          if(q>6) q<-6
          x.b<-seq(q,6,by = 0.1)
          x.a<- -x.b[order(x.b,decreasing = TRUE)]
          df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
          df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
          df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
          df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
          gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="green")+
            geom_polygon(df.b,mapping = aes(x=x,y=y),fill="green")
        }
        
        gr+geom_vline(xintercept = (mean(vrb[,1])-input$h0_H0)/(ds*sqrt(1/nrow(vrb))),col="green") 
      }
    }
  })
  
  output$h0_stat<-renderText({
    vrb<-as.data.frame(h0_camp())
    if(input$h0_var=="1"){
      paste("statistica =",round((mean(vrb[,1])-input$h0_H0)/(input$h0_ds*sqrt(1/nrow(vrb))),4)) 
    }else{
      paste("statistica =",round((mean(vrb[,1])-input$h0_H0)/(sd(vrb[,1])*sqrt(1/nrow(vrb))),4)) 
    }
  }) 
  
  output$h0_pval<-renderText({
    vrb<-as.data.frame(h0_camp())
    if(input$h0_var=="1"){
      q<-(mean(vrb[,1])-input$h0_H0)/(input$h0_ds*sqrt(1/nrow(vrb)))
      p<-pnorm(q = abs(q),mean = 0,sd = 1,lower.tail = FALSE)
      p<-format(2*p,digits = 4,format="e")
    }else{
      q<-(mean(vrb[,1])-input$h0_H0)/(sd(vrb[,1])*sqrt(1/nrow(vrb)))
      dof<-nrow(vrb)-1
      p<-pt(q = abs(q),df = dof,lower.tail = FALSE)
      p<-format(2*p,digits = 4,format="e")
    }
    paste("p-value =",p)
  }) 
  
  output$h0_potenza_txt<-renderText({
    validate(need(input$h0_alfa>0," "))
    "Potenza del test"
  })
  
  output$h0_beta<-renderUI({
    validate(need(input$h0_alfa>0," "))
    req(input$h0_alfa)
    req(input$h0_H0)
    req(input$h0_media)
    
    d<-input$h0_H0-input$h0_media
    ds<-input$h0_ds
    vrb<-as.data.frame(h0_camp())
    m<-nrow(vrb)
    if(input$h0_var==1){
      q<-qnorm(input$h0_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
      beta<-pnorm(q=q,mean = d/(ds*sqrt(1/m)),sd = 1,lower.tail = TRUE)-
        pnorm(q=-q,mean = d/(ds*sqrt(1/m)),sd = 1,lower.tail = TRUE)
    } else {
      q0<-qt(p = input$h0_alfa/2,df = m-1,lower.tail = FALSE)
      beta<-pt(q = q0+d/(ds*sqrt(1/m)),df = m-1,lower.tail = TRUE)-
        pt(q = -q0+d/(ds*sqrt(1/m)),df = m-1,lower.tail = TRUE)
    }
    HTML("1-&beta; =",round(1-beta,3))
  })
  
  
# Potenza ----------------------------------------------------------------
  output$potenza_graf_distr<-renderPlot({
    require(ggplot2)
    req(input$potenza_num_pop)
    x<-seq(-10, 10,by = 0.1)
    
    if(input$potenza_test==1){
      df<-cbind.data.frame(x=x,y=dnorm(x,mean=0,sd=1))
      q<-qnorm(input$potenza_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
      if(q>10) q<-10
      gr<-ggplot() +theme_classic()+
        geom_line(data = df,mapping = aes(x=x,y=y))+
        ylab("densità")+xlab(expression(frac(bar(x)-mu,sigma * sqrt(1/m))))+ggtitle("N(0,1)")+
        theme(plot.title = element_text(size = 20, face = "bold",
                                        hjust = 0.5))+
        annotate(geom="text", x=-2.5, y=0.2, label=expression(H[0]),size=10)
    } else {
      df<-cbind.data.frame(x=x,y=dt(x,df = input$potenza_num_pop-1))
      q<-qt(input$potenza_alfa/2,df = input$potenza_num_pop-1,lower.tail = FALSE)
      if(q>10) q<-10
      gr<-ggplot() +theme_classic()+
        geom_line(data = df,mapping = aes(x=x,y=y))+
        ylab("densità")+xlab(expression(frac(bar(x)-mu,s * sqrt(1/m))))+
        ggtitle(paste("t(",input$potenza_num_pop-1,")",sep=""))+
        theme(plot.title = element_text(size = 20, face = "bold",
                                        hjust = 0.5))+
        annotate(geom="text", x=-2.5, y=0.2, label=expression(H[0]),size=10)
    }
    
    if(input$potenza_alfa>0){
      if(input$potenza_test==1){
        x.b<-seq(q,10,by = 0.1)
        x.a<- -x.b[order(x.b,decreasing = TRUE)]
        df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =0,sd = 1))
        df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =0,sd = 1))
        df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")
      } else {
        x.b<-seq(q,10,by = 0.1)
        x.a<- -x.b[order(x.b,decreasing = TRUE)]
        df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = input$potenza_num_pop-1))
        df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = input$potenza_num_pop-1))
        df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")
      }
    }
    if(input$potenza_delta>0){
      if(input$potenza_test==1){
        x.b<-seq(-q,q,by = 0.1)
        df.b<-cbind.data.frame(x=c(-q,x.b,q),
                               y=c(0,dnorm(x.b,mean=input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop)),sd = 1),0))
        df1<-cbind.data.frame(x=x,y=dnorm(x,mean=input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop)),sd=1))
        gr<-gr+geom_line(data = df1,mapping = aes(x=x,y=y))+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="green")+
          annotate(geom="text", x=input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop))+2.5, y=0.2, label=expression(H[1]),size=10)
      } else {
        delta<-input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop))
        x.b<-seq(-q,q,by = 0.1)
        df.b<-cbind.data.frame(x=c(-q,x.b,q),
                               y=c(0,dt(x.b,ncp = delta,df =input$potenza_num_pop-1),0))
        df1<-cbind.data.frame(x=x,y=dt(x,ncp = delta,df =input$potenza_num_pop-1))
        gr<-gr+geom_line(data = df1,mapping = aes(x=x,y=y))+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="green")+
          annotate(geom="text", x=input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop))+2.5, y=0.2, label=expression(H[1]),size=10)
      }
    }
    gr
  })
  
  output$potenza_err2<-renderText({
    validate(need(input$potenza_delta>0," "))
    "Errore di tipo II"
  })
  
  output$potenza_beta<-renderUI({
    validate(need(input$potenza_delta>0," "))
    req(input$potenza_alfa)
    req(input$potenza_ds)
    req(input$potenza_num_pop)
    delta<-input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop))
    
    if(input$potenza_test==1){
      q<-qnorm(input$potenza_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
      beta<-pnorm(q=q,mean = delta,sd = 1,lower.tail = TRUE)-
        pnorm(q=-q,mean = delta,sd = 1,lower.tail = TRUE)
    } else {
      q<-qt(input$potenza_alfa/2,df = input$potenza_num_pop-1,lower.tail = FALSE)
      beta<-pt(q = q,ncp = delta,df = input$potenza_num_pop-1,lower.tail = TRUE)-
        pt(q = -q,ncp = delta,df = input$potenza_num_pop-1,lower.tail = TRUE)
    }
    HTML("&beta; =",round(beta,3))
  })
  
  output$potenza_pot_txt<-renderText({
    validate(need(input$potenza_delta>0," "))
    "Potenza"
  })
  
  output$potenza_pot<-renderUI({
    validate(need(input$potenza_delta>0," "))
    req(input$potenza_alfa)
    req(input$potenza_ds)
    req(input$potenza_num_pop)
    delta<-input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop))
    if(input$potenza_test==1){
      q<-qnorm(input$potenza_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
      beta<-pnorm(q=q,mean = delta,sd = 1,lower.tail = TRUE)-
        pnorm(q=-q,mean = delta,sd = 1,lower.tail = TRUE)
    } else {
      q<-qt(input$potenza_alfa/2,df = input$potenza_num_pop-1,lower.tail = FALSE)
      beta<-pt(q = q,ncp = delta,df = input$potenza_num_pop-1,lower.tail = TRUE)-
        pt(q = -q,ncp = delta,df = input$potenza_num_pop-1,lower.tail = TRUE)
    }
    HTML("1-&beta; =",round(1-beta,3))
      
  })
  
  
  
# Anova ----------------------------------------------------------------  
  output$anova_graf_distr<-renderPlot({
    require(ggplot2)
    x<-seq(-10, 10,by = 0.1)
    df1<-cbind.data.frame(x=x,y=dnorm(x,mean=input$anova_media1,sd=input$anova_ds))
    df2<-cbind.data.frame(x=x,y=dnorm(x,mean=input$anova_media2,sd=input$anova_ds))
    df3<-cbind.data.frame(x=x,y=dnorm(x,mean=input$anova_media3,sd=input$anova_ds))
    
    gr<-ggplot() +theme_classic()+
      geom_line(data = df1,mapping = aes(x=x,y=y))+
      ylab("densità")+xlab("x")+ggtitle("Distribuzione popolazioni")+
      theme(plot.title = element_text(size = 20, face = "bold",
                                      hjust = 0.5))+
      geom_polygon(df1,mapping = aes(x=x,y=y),fill="blue",alpha=.5)+
      geom_line(data = df2,mapping = aes(x=x,y=y))+
      geom_polygon(df2,mapping = aes(x=x,y=y),fill="green",alpha=.5)+
      geom_line(data = df3,mapping = aes(x=x,y=y))+
      geom_polygon(df3,mapping = aes(x=x,y=y),fill="coral",alpha=.5)
    gr
  })
  
   anova_camp1<-reactive({
    input$anova_resample
    set.seed(as.numeric(Sys.time()))
    rnorm(n = input$anova_numta_camp,mean = input$anova_media1,sd = input$anova_ds)
  })
  
  anova_camp2<-reactive({
    input$anova_resample
    set.seed(as.numeric(Sys.time())/2)
    rnorm(n = input$anova_numta_camp,mean = input$anova_media2,sd = input$anova_ds)
  })
  
  anova_camp3<-reactive({
    input$anova_resample
    set.seed(as.numeric(Sys.time())/4)
    rnorm(n = input$anova_numta_camp,mean = input$anova_media3,sd = input$anova_ds)
  })
  
  output$anova_graf_var_in<-renderPlot({
    require(ggplot2)
    
    m<-input$anova_numta_camp
    df<-data.frame(x=c(anova_camp1(),anova_camp2(),anova_camp3()),gr=c(rep(1,m),rep(2,m),rep(3,m)))
    df$gr<-as.factor(df$gr)
    
    p<-ggplot(df, aes(x=gr, y=x)) + theme_light()+xlab("gruppo")+ylim(-7,7)+
      geom_dotplot(binaxis='y', stackdir='center',dotsize=4,fill=c("blue","green","coral")[df$gr],
                   binwidth = 0.1, alpha=0.4)
    p<-p + coord_flip()
    p<-p + stat_summary(fun.data=mean_sdl, fun.args = list(mult=1), 
                     geom="pointrange", color="red",size=1.2)
    p
  })
  
  output$anova_graf_var_in_txt_ss<-renderUI({
    m.a<-mean(anova_camp1())
    m.b<-mean(anova_camp2())
    m.c<-mean(anova_camp3())
    ss<-sum((anova_camp1()-m.a)^2)+sum((anova_camp2()-m.b)^2)+sum((anova_camp3()-m.c)^2)
    HTML("SS<SUB>in</SUB> =",round(ss,3),"<br>
         gradi di libertà =",3*input$anova_numta_camp-3,"<br>
         MS<SUB>in</SUB> =",round(ss/(3*input$anova_numta_camp-3),3))
  })

  output$anova_graf_var_tra<-renderPlot({
    m.a<-mean(anova_camp1())
    m.b<-mean(anova_camp2())
    m.c<-mean(anova_camp3())
    
    df<-data.frame(m=c(m.a,m.b,m.c),gr=c(1,2,3),y=c("0","0","0"))
    df$gr<-as.factor(df$gr)
    
    p<-ggplot(df, aes(x=y, y=m)) + theme_light()+xlab("")+ylab("medie gruppi")+ylim(-7,7)+
      theme(axis.text.y = element_text(size = 0))+
      geom_dotplot(binaxis='y', stackdir='center',dotsize=6,fill=c("blue","green","coral")[df$gr],
                   binwidth = 0.1, alpha=0.4)
    p<-p + coord_flip()

    p<-p + stat_summary(fun.data=mean_sdl, fun.args = list(mult=1), 
                     geom="pointrange", color="red",size=1.2)
    p
  })
  
  output$anova_graf_var_tra_txt_ss<-renderUI({
    m.a<-mean(anova_camp1())
    m.b<-mean(anova_camp2())
    m.c<-mean(anova_camp3())
    m<-mean(c(anova_camp1(),anova_camp2(),anova_camp3()))
    n<-input$anova_numta_camp
    ss<- n*sum((m.a-m)^2)+n*sum((m.b-m)^2)+n*sum((m.c-m)^2)
    HTML("SS<SUB>tra</SUB> = ",round(ss,3),"<br>
         gradi di libertà = 2 <br>
         MS<SUB>tra</SUB> =",round(ss/2,3))
  })
  
  output$anova_graf_var_tot<-renderPlot({
    m<-input$anova_numta_camp
    df<-data.frame(x=c(anova_camp1(),anova_camp2(),anova_camp3()),y=rep("0",3*m),gr=c(rep(1,m),rep(2,m),rep(3,m)))
    df$gr<-as.factor(df$gr)
    
    p<-ggplot(df, aes(x=y, y=x)) + theme_light()+xlab("")+ylim(-7,7)+
      theme(axis.text.y = element_text(size = 0))+
      geom_dotplot(binaxis='y', stackdir='center',dotsize=4,fill=c("blue","green","coral")[df$gr],
                   binwidth = 0.1, alpha=0.4)
    p<-p + coord_flip()
    p<-p + stat_summary(fun.data=mean_sdl, fun.args = list(mult=1), 
                     geom="pointrange", color="red",size=1.2)
    
    p
    
  })
  
  output$anova_graf_var_tot_txt_ss<-renderUI({
    m.a<-mean(anova_camp1())
    m.b<-mean(anova_camp2())
    m.c<-mean(anova_camp3())
    m<-mean(c(anova_camp1(),anova_camp2(),anova_camp3()))
    ss<- sum((c(anova_camp1(),anova_camp2(),anova_camp3())-m)^2)
    HTML("SS<SUB>tot</SUB> = ",round(ss,3),"<br>
         gradi di libertà = ",3*input$anova_numta_camp-1,"<br>
         MS<SUB>tot</SUB> =",round(ss/(3*input$anova_numta_camp-1),3))
  })

  output$anova_stat<-renderText({
    m.a<-mean(anova_camp1())
    m.b<-mean(anova_camp2())
    m.c<-mean(anova_camp3())
    m<-mean(c(anova_camp1(),anova_camp2(),anova_camp3()))
    n<-input$anova_numta_camp
    ms_in<-(sum((anova_camp1()-m.a)^2)+sum((anova_camp2()-m.b)^2)+sum((anova_camp3()-m.c)^2))/(3*n-3)
    ms_tra<- (n*sum((m.a-m)^2)+n*sum((m.b-m)^2)+n*sum((m.c-m)^2))/2
    paste("statistica =",round(ms_tra/ms_in,4)) 
})
  
  output$anova_pval<-renderText({
    m.a<-mean(anova_camp1())
    m.b<-mean(anova_camp2())
    m.c<-mean(anova_camp3())
    m<-mean(c(anova_camp1(),anova_camp2(),anova_camp3()))
    n<-input$anova_numta_camp
    ms_in<-(sum((anova_camp1()-m.a)^2)+sum((anova_camp2()-m.b)^2)+sum((anova_camp3()-m.c)^2))/(3*n-3)
    ms_tra<- (n*sum((m.a-m)^2)+n*sum((m.b-m)^2)+n*sum((m.c-m)^2))/2
    q<-ms_tra/ms_in
    p<-pf(q = q,df1 = 2,df2 = 3*n-3,lower.tail = FALSE)
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 
  
  output$anova_graf_distr_test<-renderPlot({
    require(ggplot2)
    m.a<-mean(anova_camp1())
    m.b<-mean(anova_camp2())
    m.c<-mean(anova_camp3())
    m<-mean(c(anova_camp1(),anova_camp2(),anova_camp3()))
    n<-input$anova_numta_camp
    dof1<-2
    dof2<-3*n-3
    ms_in<-(sum((anova_camp1()-m.a)^2)+sum((anova_camp2()-m.b)^2)+sum((anova_camp3()-m.c)^2))/(3*n-3)
    ms_tra<- (n*sum((m.a-m)^2)+n*sum((m.b-m)^2)+n*sum((m.c-m)^2))/2
    f<-ms_tra/ms_in
    
    x<-seq(0, 12,by = 0.1)
    
    df<-cbind.data.frame(x=x,y=df(x,df1 = dof1,df2=dof2))
    if(input$anova_alfa>0){
      q<-qf(input$anova_alfa,df1 = dof1,df2=dof2,lower.tail = FALSE)
      if(q>12) q<-12
      x.b<-seq(q,12,by = 0.1)
      df.b<-cbind.data.frame(x=x.b,y=df(x.b,df1 = dof1,df2=dof2))
      df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
    }
    
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("densità")+xlab("f")+
      ggtitle(paste("F(",2,",",3*n-3,")"))+
      theme(plot.title = element_text(size = 20, face = "bold",
                                      hjust = 0.5))
    
    if(input$anova_alfa>0){
      gr<-gr+geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
    
    if(input$anova_graf_pvalue & f<12){
      x.b<-seq(f,12,by = 0.1)
      df.b<-cbind.data.frame(x=x.b,y=df(x.b,df1 = dof1,df2=dof2))
      df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      gr<-gr+geom_polygon(df.b,mapping = aes(x=x,y=y),fill="green")
    }
    gr+geom_vline(xintercept = f,col="green")
  })

  output$anova_R<-renderPrint({
    m<-input$anova_numta_camp
    df<-data.frame(x=c(anova_camp1(),anova_camp2(),anova_camp3()),Fattore=c(rep(1,m),rep(2,m),rep(3,m)))
    df$Fattore<-as.factor(df$Fattore)
    mod<-lm(x~Fattore,df)
    anova(mod)
  })

# Regressione ----------------------------------------------------------------
  output$regr_mq_titolo<-renderText({
    a<-input$regr_mq_a
    b<-input$regr_mq_b
    if(a==0 & b==1){
      "Retta da stimare: y = x"
    } else if (a!=0 & b==1){
      paste("Retta da stimare: y = ",input$regr_mq_a," + x",sep="")
    } else if(a==0 & b!=1){
      paste("Retta da stimare: y = ",input$regr_mq_b,"x",sep="")
    } else if (a!=0 & b!=1){
      paste("Retta da stimare: y = ",input$regr_mq_a," + ",input$regr_mq_b,"x",sep="")
    }
  })
  
  regr_mq_camp<-reactive({
    input$regr_mq_resample
    x<- as.numeric(unlist(strsplit(input$regr_mq_dis," ")))
    m<-length(x)
    set.seed(as.numeric(Sys.time()))
    rnorm(n = m,mean = 0,sd = input$regr_mq_var)
  })
  
  output$regr_mq_matrexp<-renderTable({
    req(input$regr_mq_dis)
    req(input$regr_mq_a)
    req(input$regr_mq_b)
    x<- as.numeric(unlist(strsplit(input$regr_mq_dis," ")))
    m<-length(x)
    y<-input$regr_mq_a+input$regr_mq_b*x+regr_mq_camp()
    df<-cbind.data.frame(x,y)
    df
  })
  
  output$regr_mq_graf<-renderPlot({
    req(input$regr_mq_dis)
    req(input$regr_mq_a)
    req(input$regr_mq_b)
    req(input$regr_mq_aman)
    req(input$regr_mq_bman)

    require(ggplot2)
    x<- as.numeric(unlist(strsplit(input$regr_mq_dis," ")))
    m<-length(x)
    y<-input$regr_mq_a+input$regr_mq_b*x+regr_mq_camp()
    r<-input$regr_mq_a+input$regr_mq_b*x
    df<-cbind.data.frame(x,y)
    y.prev=input$regr_mq_aman+input$regr_mq_bman*x
    df<-cbind.data.frame(df,y.prev,res=abs(y-y.prev))
    mod<-lm(y~x,df)
    
    deltay<-(max(r)+3*input$regr_mq_var)-(min(r)-3*input$regr_mq_var)
    deltax<-(max(x)-min(x))
    delta<-max(deltax,deltay)

    gr<-ggplot(df,mapping = aes(x=x,y=y))+labs(x="x",y="y")+
      xlim(min(x)-deltay/2,max(x)+deltay)+
      ylim(min(r)-3*input$regr_mq_var,max(r)+3*input$regr_mq_var)+
      theme_classic()+geom_point(cex=2,col="blue")+
      geom_abline(intercept = input$regr_mq_aman,slope = input$regr_mq_bman,col="blue")+
      coord_fixed(ratio=1)

     if(input$regr_mq_rstim==TRUE){
       gr<-gr+geom_abline(intercept = input$regr_mq_a,slope = input$regr_mq_b,col="red",lty=2)
     } 
 
    if(input$regr_mq_rregr==TRUE){
      gr<-gr+geom_abline(intercept = mod$coefficients[1],slope = mod$coefficients[2],col="red")
    }

    if(!is.null(input$regr_mq_dq)){
      if(1 %in% input$regr_mq_dq & !(2 %in% input$regr_mq_dq)){
        gr<-gr+ geom_segment(data = df, aes(x = x, y = y, xend = x, yend = y.prev),col="blue", size=1.05)
      }
      else if(2 %in% input$regr_mq_dq & !(1 %in% input$regr_mq_dq)){
        if(df$y>df$y.prev){
          gr<-gr+geom_rect(data = df, mapping=aes(xmin=x, ymin=y.prev, xmax= x+res,ymax=y),alpha=0.4,fill="blue")
        } else {
          gr<-gr+geom_rect(data = df, mapping=aes(xmin=x, ymin=y, xmax= x+res,ymax=y.prev),alpha=0.4,fill="blue")
        }}
      else if(2 %in% input$regr_mq_dq & 1 %in% input$regr_mq_dq ){
        gr<-gr+ geom_segment(data = df, aes(x = x, y = y, xend = x, yend = y.prev),col="blue", size=1.1)
        if(df$y>df$y.prev){
          gr<-gr+geom_rect(data = df, mapping=aes(xmin=x, ymin=y.prev, xmax= x+res,ymax=y),alpha=0.4,fill="blue")
        } else {
          gr<-gr+geom_rect(data = df, mapping=aes(xmin=x, ymin=y, xmax= x+res,ymax=y.prev),alpha=0.4,fill="blue")
        }
      }
      }
    gr
  })

  output$regr_mq_rregr_interc<-renderText({
    validate(need(input$regr_mq_rregr==1,""))
    x<- as.numeric(unlist(strsplit(input$regr_mq_dis," ")))
    m<-length(x)
    y<-input$regr_mq_a+input$regr_mq_b*x+regr_mq_camp()
    r<-input$regr_mq_a+input$regr_mq_b*x
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    paste("Intercetta = ",round(mod$coefficients[1],2),sep="")
  })

  output$regr_mq_rregr_pdz<-renderText({
    validate(need(input$regr_mq_rregr==1,""))
    x<- as.numeric(unlist(strsplit(input$regr_mq_dis," ")))
    m<-length(x)
    y<-input$regr_mq_a+input$regr_mq_b*x+regr_mq_camp()
    r<-input$regr_mq_a+input$regr_mq_b*x
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    paste("Pendenza = ",round(mod$coefficients[2],2),sep="")
  })

  output$regr_mq_grss<-renderPlot({
    validate(need(input$regr_mq_dq==2,""))
    x<- as.numeric(unlist(strsplit(input$regr_mq_dis," ")))
    m<-length(x)
    y<-input$regr_mq_a+input$regr_mq_b*x+regr_mq_camp()
    r<-input$regr_mq_a+input$regr_mq_b*x
    df<-cbind.data.frame(x,y)
    y.prev=input$regr_mq_aman+input$regr_mq_bman*x
    df<-cbind.data.frame(df,y.prev,res=abs(y-y.prev))
    SS<-sum(df$res^2)
    mod<-lm(y~x,df)
    SS_res<-sum(mod$residuals^2)
    if(SS>SS_res*25)SS<-SS_res*25
    
    require(ggplot2)
    gr<-ggplot()+geom_rect(aes(xmin=0,ymin=0,xmax=SS,ymax=0.1),fill="blue")+
      ylim(0,0.2)+xlim(0,SS_res*25)+
      theme(axis.text.y=element_blank(),axis.ticks=element_blank(),
            axis.title.y=element_blank(),legend.position="none",
            panel.background=element_blank(),panel.border=element_blank(),
            panel.grid.major=element_blank(),
            panel.grid.minor=element_blank(),plot.background=element_blank())
    
    if(input$regr_mq_rregr==TRUE){
      gr<-gr+geom_rect(aes(xmin=0,ymin=0,xmax=SS_res,ymax=0.1),fill="red")
    }
    gr
  })
  
  output$regr_mq_numss<-renderText({
    validate(need(input$regr_mq_dq==2,""))
    x<- as.numeric(unlist(strsplit(input$regr_mq_dis," ")))
    m<-length(x)
    y<-input$regr_mq_a+input$regr_mq_b*x+regr_mq_camp()
    r<-input$regr_mq_a+input$regr_mq_b*x
    df<-cbind.data.frame(x,y)
    y.prev=input$regr_mq_aman+input$regr_mq_bman*x
    df<-cbind.data.frame(df,y.prev,res=abs(y-y.prev))
    SS<-sum(df$res^2)
    paste("SS = ",round(SS,3),sep="")
  })

  output$regr_sp_titolo<-renderText({
    "Parametri da stimare:"
  })
  
  regr_sp_camp<-reactive({
    input$regr_sp_resample
    input$regr_sp_resample1
    input$regr_sp_resample2
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    set.seed(as.numeric(Sys.time()))
    rnorm(n = m,mean = 0,sd = input$regr_sp_var)
  })
  
  output$regr_sp_matrexp<-renderTable({
    req(input$regr_sp_dis)
    req(input$regr_sp_a)
    req(input$regr_sp_b)
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_sp_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    df
  })
  
  output$regr_sp_graf<-renderPlot({
    req(input$regr_sp_dis)
    req(input$regr_sp_a)
    req(input$regr_sp_b)
    
    require(ggplot2)
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_sp_b*x+regr_sp_camp()
    r<-input$regr_sp_a+input$regr_sp_b*x
    df<-cbind.data.frame(x,y)

    mod<-lm(y~x,df)
    
    deltay<-(max(r)+3*input$regr_sp_var)-(min(r)-3*input$regr_sp_var)
    deltax<-(max(x)-min(x))
    delta<-max(deltax,deltay)
    
    gr<-ggplot(df,mapping = aes(x=x,y=y))+labs(x="x",y="y")+
      xlim(min(x)-deltay/2,max(x)+deltay)+
      ylim(min(r)-3*input$regr_sp_var,max(r)+3*input$regr_sp_var)+
      theme_classic()+geom_point(cex=2,col="blue")+
      coord_fixed(ratio=1)
    
    if(input$regr_sp_rstim==TRUE){
      gr<-gr+geom_abline(intercept = input$regr_sp_a,slope = input$regr_sp_b,col="red",lty=2)
    } 
    
    if(input$regr_sp_rregr==TRUE){
      gr<-gr+geom_abline(intercept = mod$coefficients[1],slope = mod$coefficients[2],col="red")
    }

    gr
  })
  
  output$regr_sp_rregr_interc<-renderText({
    validate(need(input$regr_sp_rregr==1,""))
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_sp_b*x+regr_sp_camp()
    r<-input$regr_sp_a+input$regr_sp_b*x
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    paste("Intercetta = ",round(mod$coefficients[1],2),sep="")
  })
  
  output$regr_sp_rregr_pdz<-renderText({
    validate(need(input$regr_sp_rregr==1,""))
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_sp_b*x+regr_sp_camp()
    r<-input$regr_sp_a+input$regr_sp_b*x
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    paste("Pendenza = ",round(mod$coefficients[2],2),sep="")
  })

  output$regr_sp_graf_distr<-renderPlot({
    req(input$regr_sp_dis)
    req(input$regr_sp_a)
    req(input$regr_sp_b)

    require(ggplot2)
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    dof<-m-2

    x<-seq(-6, 6,by = 0.1)
    df<-cbind.data.frame(x=x,y=dt(x,df = dof))
    
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("densità")+
      xlab(expression(frac(b[0],s * sqrt(1/m+bar(x)/ss))))+ # da sistemare
      ggtitle(paste("t(",dof,")",sep=""))+
      theme(plot.title = element_text(size = 20, face = "bold",
                                      hjust = 0.5))
    
    if(input$regr_sp_alfa>0){
      q<-qt(input$regr_sp_alfa/2,df = dof,lower.tail = FALSE)
      if(q>6) q<-6
      x.b<-seq(q,6,by = 0.1)
      x.a<- -x.b[order(x.b,decreasing = TRUE)]
      df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
      df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
        geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
    
    if(input$regr_sp_pvalue){
      q<-s$coefficients[1,3]
      q<-abs(q)
      if(q>6) q<-6
      x.b<-seq(q,6,by = 0.1)
      x.a<- -x.b[order(x.b,decreasing = TRUE)]
      df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
      df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="green")+
        geom_polygon(df.b,mapping = aes(x=x,y=y),fill="green")
    }
    
    gr+geom_vline(xintercept = s$coefficients[1,3],col="green") 
  })

  output$regr_sp_int_stat<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    paste("statistica =",round(s$coefficients[1,3],3))
  })

  output$regr_sp_int_pval<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    paste("p-value =",format(s$coefficients[1,4],digits = 4,format="e"))
  })
  
  output$regr_sp_int_stima<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    paste("intercetta =",round(s$coefficients[1,1],digits = 3))
  })
  
  output$regr_sp_int_es<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    paste("errore std. =",round(s$coefficients[1,2],digits = 3))
  })

  output$regr_sp_int_ic_inf<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    q<-qt(input$regr_sp_alfa/2,df = m-2,lower.tail = FALSE)
    paste("estremo inferiore =",round(s$coefficients[1,1]-q*s$coefficients[1,2],digits = 3))
  })
  
  output$regr_sp_int_ic_sup<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    q<-qt(input$regr_sp_alfa/2,df = m-2,lower.tail = FALSE)
    paste("estremo superiore =",round(s$coefficients[1,1]+q*s$coefficients[1,2],digits = 3))
  })

  output$regr_sp_graf_distr_pen<-renderPlot({
    req(input$regr_sp_dis)
    req(input$regr_sp_a)
    req(input$regr_sp_b)
    
    require(ggplot2)
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    dof<-m-2
    
    x<-seq(-6, 6,by = 0.1)
    df<-cbind.data.frame(x=x,y=dt(x,df = dof))
    
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("densità")+
      xlab(expression(frac(b[1],s * sqrt(1/ss))))+ # da sistemare
      ggtitle(paste("t(",dof,")",sep=""))+
      theme(plot.title = element_text(size = 20, face = "bold",
                                      hjust = 0.5))
    
    if(input$regr_sp_alfa>0){
      q<-qt(input$regr_sp_alfa/2,df = dof,lower.tail = FALSE)
      if(q>6) q<-6
      x.b<-seq(q,6,by = 0.1)
      x.a<- -x.b[order(x.b,decreasing = TRUE)]
      df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
      df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
        geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
    
    if(input$regr_sp_pvalue2){
      q<-s$coefficients[2,3]
      q<-abs(q)
      if(q>6) q<-6
      x.b<-seq(q,6,by = 0.1)
      x.a<- -x.b[order(x.b,decreasing = TRUE)]
      df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
      df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
      df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
      df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="green")+
        geom_polygon(df.b,mapping = aes(x=x,y=y),fill="green")
    }
    
    gr+geom_vline(xintercept = s$coefficients[2,3],col="green") 
  })
  
  output$regr_sp_pen_stat<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    paste("statistica =",round(s$coefficients[2,3],3))
  })
  
  output$regr_sp_pen_pval<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    paste("p-value =",format(s$coefficients[2,4],digits = 4,format="e"))
  })
  
  output$regr_sp_pen_stima<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    paste("pendenza =",round(s$coefficients[2,1],digits = 3))
  })
  
  output$regr_sp_pen_es<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    paste("errore std. =",round(s$coefficients[2,2],digits = 3))
  })
  
  output$regr_sp_pen_ic_inf<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    q<-qt(input$regr_sp_alfa/2,df = m-2,lower.tail = FALSE)
    paste("estremo inferiore =",round(s$coefficients[2,1]-q*s$coefficients[2,2],digits = 3))
  })
  
  output$regr_sp_pen_ic_sup<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    q<-qt(input$regr_sp_alfa/2,df = m-2,lower.tail = FALSE)
    paste("estremo superiore =",round(s$coefficients[2,1]+q*s$coefficients[2,2],digits = 3))
  }) 

  output$regr_prev_titolo<-renderText({
    a<-input$regr_prev_a
    b<-input$regr_prev_b
    paste("Valore da stimare = ",input$regr_prev_a+input$regr_prev_b*input$regr_prev_x0,sep="")
  })
  
  regr_prev_camp<-reactive({
    input$regr_prev_resample
    x<- as.numeric(unlist(strsplit(input$regr_prev_dis," ")))
    m<-length(x)
    set.seed(as.numeric(Sys.time()))
    rnorm(n = m,mean = 0,sd = input$regr_prev_var)
  })
  
  output$regr_prev_matrexp<-renderTable({
    req(input$regr_prev_dis)
    req(input$regr_prev_a)
    req(input$regr_prev_b)
    x<- as.numeric(unlist(strsplit(input$regr_prev_dis," ")))
    m<-length(x)
    y<-input$regr_prev_a+input$regr_prev_b*x+regr_prev_camp()
    df<-cbind.data.frame(x,y)
    df
  })
  
  output$regr_prev_graf<-renderPlot({
    req(input$regr_prev_dis)
    req(input$regr_prev_a)
    req(input$regr_prev_b)
    
    require(ggplot2)
    x<- as.numeric(unlist(strsplit(input$regr_prev_dis," ")))
    m<-length(x)
    y<-input$regr_prev_a+input$regr_prev_b*x+regr_prev_camp()
    r<-input$regr_prev_a+input$regr_prev_b*x
    df<-cbind.data.frame(x,y)
    
    mod<-lm(y~x,df)
    
    deltay<-(max(r)+3*input$regr_prev_var)-(min(r)-3*input$regr_prev_var)
    deltax<-(max(x)-min(x))
    delta<-max(deltax,deltay)
    
    gr<-ggplot(df,mapping = aes(x=x,y=y))+labs(x="x",y="y")+
      xlim(min(x)-deltay/2,max(x)+deltay)+
      ylim(min(r)-3*input$regr_prev_var,max(r)+3*input$regr_prev_var)+
      theme_classic()+geom_point(cex=2,col="blue")+
      coord_fixed(ratio=1)
    
    if(input$regr_prev_rstim==TRUE){
      gr<-gr+geom_abline(intercept = input$regr_prev_a,slope = input$regr_prev_b,col="red",lty=2)+
        geom_segment(aes(x=input$regr_prev_x0,y=-Inf,
                         xend=input$regr_prev_x0,
                         yend=input$regr_prev_a+input$regr_prev_b*input$regr_prev_x0),
                     col="green",lty=2)+
        geom_segment(aes(x=-Inf,y=input$regr_prev_a+input$regr_prev_b*input$regr_prev_x0,
                         xend=input$regr_prev_x0,
                         yend=input$regr_prev_a+input$regr_prev_b*input$regr_prev_x0),
                     col="green",lty=2)
    } 
    if(input$regr_prev_rregr==TRUE){
      gr<-gr+geom_abline(intercept = mod$coefficients[1],slope = mod$coefficients[2],col="red")+
        geom_segment(aes(x=input$regr_prev_x0,y=-Inf,
                         xend=input$regr_prev_x0,
                         yend=mod$coefficients[1]+mod$coefficients[2]*input$regr_prev_x0),
                     col="green")+
        geom_segment(aes(x=-Inf,y=mod$coefficients[1]+mod$coefficients[2]*input$regr_prev_x0,
                         xend=input$regr_prev_x0,
                         yend=mod$coefficients[1]+mod$coefficients[2]*input$regr_prev_x0),
                     col="green")
    }
    if(input$regr_prev_intconf==TRUE){
      gr<-gr+stat_smooth(method = "lm", col = "red")
    }
   gr
  })
  
  output$regr_prev_stimaprev<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_prev_dis," ")))
    y<-input$regr_prev_a+input$regr_prev_b*x+regr_prev_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    paste("previsione = ",round(mod$coefficients[1]+mod$coefficients[2]*input$regr_prev_x0,3),sep="")
  })

  output$regr_prev_esprev<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_prev_dis," ")))
    m<-length(x)
    y<-input$regr_prev_a+input$regr_prev_b*x+regr_prev_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    sq<-(sum(mod$residuals^2))/(m-2)
    x.medio<-mean(x)
    SS.x<-sum((x-x.medio)^2)
    h=1/m+((input$regr_prev_x0-x.medio)^2)/SS.x
    paste("errore std. = ",round(sqrt(h*sq),3),sep="")
  })

  output$regr_prev_icinf<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_prev_dis," ")))
    m<-length(x)
    y<-input$regr_prev_a+input$regr_prev_b*x+regr_prev_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    sq<-(sum(mod$residuals^2))/(m-2)
    x.medio<-mean(x)
    SS.x<-sum((x-x.medio)^2)
    h=1/m+((input$regr_prev_x0-x.medio)^2)/SS.x
    q<-qt(p = 0.025,df = m-2,lower.tail = FALSE)
    p<-mod$coefficients[1]+mod$coefficients[2]*input$regr_prev_x0
    paste("estremo inferiore = ",round(p-q*sqrt(h*sq),3),sep="")
  }) 

  output$regr_prev_icsup<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_prev_dis," ")))
    m<-length(x)
    y<-input$regr_prev_a+input$regr_prev_b*x+regr_prev_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    sq<-(sum(mod$residuals^2))/(m-2)
    x.medio<-mean(x)
    SS.x<-sum((x-x.medio)^2)
    h=1/m+((input$regr_prev_x0-x.medio)^2)/SS.x
    q<-qt(p = 0.025,df = m-2,lower.tail = FALSE)
    p<-mod$coefficients[1]+mod$coefficients[2]*input$regr_prev_x0
    paste("estremo superiore = ",round(p+q*sqrt(h*sq),3),sep="")
  }) 

  regr_lev_camp<-reactive({
    input$regr_lev_resample
    x<- as.numeric(unlist(strsplit(input$regr_lev_dis," ")))
    m<-length(x)
    set.seed(as.numeric(Sys.time()))
    rnorm(n = m,mean = 0,sd = input$regr_lev_var)
  })
  
  output$regr_lev_matrexp<-renderTable({
    req(input$regr_lev_dis)
    req(input$regr_lev_a)
    req(input$regr_lev_b)
    x<- as.numeric(unlist(strsplit(input$regr_lev_dis," ")))
    m<-length(x)
    y<-input$regr_lev_a+input$regr_lev_b*x+regr_lev_camp()
    df<-cbind.data.frame(x,y)
    df
  })

  output$regr_lev<-renderPlot({
    x<- as.numeric(unlist(strsplit(input$regr_lev_dis," ")))
    if(!NA%in%x){
      X=seq(min(x),max(x),0.1)
      m<-length(x)
      x.medio<-mean(x)
      SS.x<-sum((x-x.medio)^2)
      h=1/m+((X-x.medio)^2)/SS.x
      df<-cbind.data.frame(x=X,h=h)
      require(ggplot2)
      ggplot()+labs(x="x",y="leverage")+ylim(0,1)+
        geom_line(df,mapping = aes(x=x,y=h),col="red")+theme_classic()
    }
  })
  
  

# Introduzione ----------------------------------------------------------------
  #output$Intro_G<-renderUI({includeHTML("Introduzione/Introduzione.html")})

# Dispense ----------------------------------------------------------------
  #output$dispensa_descr<-renderUI({
  #  withMathJax(includeHTML("Dispense/Statistica_inferenziale.html"))
  #    })
  #output$dispensa_infer<-renderUI({includeHTML("Dispense/02_Statistica_inferenziale.html")})
  #output$dispensa_inferfileInput('Dispense/02_Statistica_inferenziale.pdf', 'upload file ( . pdf format only)', accept = c('.pdf'))
  #output$dispensa_infer<-renderUI({includeMarkdown("Dispense/02_Statistica_inferenziale.Rmd")})
  #output$dispensa_regr<-renderUI({
  #  withMathJax(includeHTML("Dispense/03_Regressione.html"))
  #  })


 
}





