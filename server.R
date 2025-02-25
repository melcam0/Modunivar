rm(list = ls())

server <- function (input , output, session ){
  
  observeEvent(input$openModal, {
    showModal(
      modalDialog(title = "Authors:",size = 's',easyClose = TRUE,footer = NULL,
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

    shinyjs::reset("lista_esempi")
    shinyjs::reset("file_xlsx")
    shinyjs::reset("file_csv")
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
      dati$DS<-data.frame(df)
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
      # suppressWarnings(colnames(df)[!is.na(as.numeric(colnames(df)))]
      #                  <-as.numeric(colnames(df)[!is.na(as.numeric(colnames(df)))]))
      dati$DS<-data.frame(df)
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

  output$dati<-DT::renderDataTable(                            {
    validate(need(nrow(dati$DS)!=0,""))
    #if(length(dati$nr)==0){
    DT::datatable(dati$DS  ,editable = TRUE,class = 'cell-border stripe',rownames = TRUE,extensions = 'ColReorder',
                  options = list(
                    autoWidth = TRUE,
                    columnDefs = list(list(width = '100px', 
                                           targets = "_all"
                                           )),
                    colReorder = TRUE)
                  )
   # } else {
    #  dati$DS_nr[!dati$righe%in%dati$righe_tolte,]}
      })
  
  # proxy = dataTableProxy("dati")

  observeEvent(input$dati_cell_edit, {
    info = input$dati_cell_edit
    
    i = info$row
    j = info$col
    k = info$value
    
    dati$DS[i, j] <<- DT::coerceValue(k, dati$DS[i, j])
    
    # replaceData(proxy, dati$DS, resetPaging = FALSE)  # replaces data displayed by the updated table
  })
  
  observeEvent(input$dati_ripristina,ignoreNULL = FALSE, {
    dati$DS<-dati$DS_righe
  })
  
  
  # output$a <- rhandsontable::renderRHandsontable({
  #   rhandsontable::rhandsontable(dati$DS)%>%
  #     rhandsontable::hot_context_menu(allowRowEdit = FALSE, allowColEdit = FALSE)%>%
  #     rhandsontable::hot_cols(columnSorting = TRUE)%>% 
  #     hot_cols(format = "0.000000")
  # })
  
  
  
# variabili qualitative ---------------------------------------------------
  
  output$var_quali<-renderUI({
    checkboxGroupInput(inputId = "var_ql",label = "Select qualitative variables",
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
      "No quantitative variables"
    }
  })
  

# variabile nomi righe ---------------------------------------------------

  output$var_nomi<-renderUI({
    selectizeInput(inputId = "var_nr"," ",
                       choices = dati$var_nr,
                   options = list(
                     placeholder = 'Select row names variable',
                     onInitialize = I('function() { this.setValue(""); }')
                   ))
  })
  
  observeEvent(input$var_nr,ignoreNULL = FALSE,{
    req(input$var_nr)
    if(length(input$var_nr)!=0){
      if(sum(duplicated(dati$DS[,input$var_nr]))==0){
        dati$col_nr<-input$var_n
        dati$DS<-as.data.frame(dati$DS_nr[,!dati$var_nr%in%input$var_nr])
        if(length(dati$var_nr)==2) names(dati$DS)<-dati$var_nr[input$var_nr!=dati$var_nr]
        dati$DS_righe<-as.data.frame(dati$DS_nr[,!dati$var_nr%in%input$var_nr])
        dati$nr<-dati$DS_nr[,dati$var_nr%in%input$var_nr]
        row.names(dati$DS)<-dati$nr
        dati$var<-colnames(dati$DS)
        dati$var_qt<-colnames(dati$DS)
        dati$righe<-dati$DS_nr[,dati$var_nr%in%input$var_nr]
      }else{
        sendSweetAlert(session, title = "Input Error",
                       text = 'Duplicate row names are not allowed!',
                       type = "error",btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
      }
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
      "No row names variable"
    } else {
      dati$nr
      }
    })
  
  
# summary -----------------------------------------------------------------
  
  output$var_gruppo<-renderUI({
    req(!is.null(dati$var_ql))
    checkboxGroupInput(inputId = "var_gr",label = "select the factors",
                       choices = dati$var_ql,selected =dati$var_gr)
  })
  
  observeEvent(input$var_gr,ignoreNULL = FALSE,{
    dati$var_gr<-input$var_gr
  })
  
  output$sum_dati <- renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    varqual <- tryCatch({
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
        print("Maximum 3 groups")
      } 
    },
    error = function(e) {
      # print("selezionare le variabili qualitative")
    })
    if(is.null(varqual)){
      sendSweetAlert(session, title = "Warning",
                     text = 'Select qualitative variables!',
                     type = "warning",btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
    }else{
      print(varqual)
    }
  })
  
# oggetti  ------------------------------------------------
  
  output$righe_tolte<-renderUI({
    checkboxGroupInput(inputId = "righe_tolte",label = "Select rows to delete",
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
     "No rows deleted"
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
    checkboxGroupInput(inputId = "graf_disp_var_gr",label = "select the factors",
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
      checkboxGroupInput(inputId = "graf_disp_gr",label = "deselect the levels you are not interested in",
                         choices = unique(dati$DS[,input$graf_disp_var_gr]),selected =unique(dati$DS[,input$graf_disp_var_gr]))
    } else if (length(graf$var_gr)==2){
      lv<-unique(interaction(dati$DS[,input$graf_disp_var_gr[1]],dati$DS[,input$graf_disp_var_gr[2]]))
      checkboxGroupInput(inputId = "graf_disp_gr",label = "deselect the levels you are not interested in",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)==3){
      lv<-unique(interaction(dati$DS[,input$graf_disp_var_gr[1]],dati$DS[,input$graf_disp_var_gr[2]],dati$DS[,input$graf_disp_var_gr[3]]))
      checkboxGroupInput(inputId = "graf_disp_gr",label = "deselect the levels you are not interested in",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)>3){
      print("Maximum 3 factors")}
  })
  
  observeEvent(input$graf_disp_gr,ignoreNULL = FALSE,{
    graf$gr<-input$graf_disp_gr
  })

  output$graf_disp<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$graf_disp_var%in%colnames(dati$DS))
    
    if(is.numeric(as.data.frame(dati$DS[,input$graf_disp_var,drop=FALSE])[,1])){
      
      df<-cbind.data.frame(dati$DS[,input$graf_disp_var,drop=FALSE],c(1:length(dati$DS[,input$graf_disp_var])))
      colnames(df)<-c("y","index")
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
      gr<-ggplot(df,mapping = aes(x=index,y=y))+labs(x="index",y=input$graf_disp_var)+
        theme_light()+ coord_cartesian(xlim = graf$xlim, ylim = graf$ylim, expand = TRUE)+
        scale_x_continuous(breaks=df$indice)
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
    }else{
      sendSweetAlert(session, title = "Input Error",
                     text = 'Select a quantitative variable!',
                     type = "error",btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
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

  # grafico a punti (dotplot) -----------------------------------------------------------
  
  output$graf_pt_var<-renderUI({
    selectizeInput(inputId = "graf_pt_var"," ",
                   choices = dati$var_qt)})
  
  output$graf_pt_var_gr<-renderUI({
    req(dati$var_ql)
    checkboxGroupInput(inputId = "graf_pt_var_gr",label = "select the factors",
                       choices = dati$var_ql,selected =dati$var_gr)
  })
  
  observeEvent(input$graf_pt_var_gr,ignoreNULL = FALSE,{
    graf$var_gr<-input$graf_pt_var_gr
    if(is.null(input$graf_pt_var_gr)){
      graf$gr<-NULL
    } else {
      graf$gr<-input$graf_pt_gr
    }
  })
 
  output$graf_pt_gr<-renderUI({
    req(input$graf_pt_var_gr)
    req(graf$var_gr)
    if(length(graf$var_gr)==1){
      checkboxGroupInput(inputId = "graf_pt_gr",label = "deselect the levels you are not interested in",
                         choices = unique(dati$DS[,input$graf_pt_var_gr]),selected =unique(dati$DS[,input$graf_pt_var_gr]))
    } else if (length(graf$var_gr)==2){
      lv<-unique(interaction(dati$DS[,input$graf_pt_var_gr[1]],dati$DS[,input$graf_pt_var_gr[2]]))
      checkboxGroupInput(inputId = "graf_pt_gr",label = "deselect the levels you are not interested in",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)==3){
      lv<-unique(interaction(dati$DS[,input$graf_pt_var_gr[1]],dati$DS[,input$graf_pt_var_gr[2]],dati$DS[,input$graf_pt_var_gr[3]]))
      checkboxGroupInput(inputId = "graf_pt_gr",label = "deselect the levels you are not interested in",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)>3){
      print("Maximum 3 factors")}
  })
  
  observeEvent(input$graf_pt_gr,ignoreNULL = FALSE,{
    graf$gr<-input$graf_pt_gr
  })
  
  output$graf_pt<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$graf_pt_var%in%colnames(dati$DS))
    
    if(is.numeric(as.data.frame(dati$DS[,input$graf_pt_var,drop=FALSE])[,1])){
      
      df<-cbind.data.frame(dati$DS[,input$graf_pt_var,drop=FALSE],c(1:length(dati$DS[,input$graf_pt_var])))
      colnames(df)<-c("y","index")
      if(!is.null(graf$var_gr)){
        if (length(graf$var_gr)==1){
          lab<-as.factor(dati$DS[,input$graf_pt_var_gr])
        } else if (length(graf$var_gr)==2){
          lab<-as.factor(interaction(dati$DS[,input$graf_pt_var_gr[1]],dati$DS[,input$graf_pt_var_gr[2]]))
        } else if (length(graf$var_gr)==3){
          lab<-as.factor(interaction(dati$DS[,input$graf_pt_var_gr[1]],dati$DS[,input$graf_pt_var_gr[2]],dati$DS[,input$graf_pt_var_gr[3]]))
        }
      } else {
        lab<-rep("0",nrow(df))
      }
      df<-cbind.data.frame(df,gruppo=lab)
      row.names(df)<-row.names(dati$DS)

      gr<-ggplot(df,mapping = aes(x=y))+labs(x="data value",y=" ")+
        theme_light()
      if(is.null(graf$gr)){
        gr<-gr+geom_dotplot(dotsize = .75, stackratio = 1.2, fill = "steelblue",colour = "steelblue")
        gr <- gr+scale_y_continuous(NULL, breaks = NULL)
        print(gr)
      } else {
        gr<-gr+geom_dotplot(dotsize = .75, stackratio = 1.2,mapping = aes(colour=gruppo,fill=gruppo))
        gr<-gr%+%subset(df,df$gruppo%in%graf$gr)
        print(gr)
      }
    }else{
      sendSweetAlert(session, title = "Input Error",
                     text = 'Select a quantitaive variable!',
                     type = "error",btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
    }
  })

# Istogramma --------------------------------------------------------------
  
  output$graf_hist_var<-renderUI({
    selectizeInput(inputId = "graf_hist_var"," ",
                   choices = dati$var_qt)})
  
  output$graf_hist_var_gr<-renderUI({
    req(dati$var_ql)
    checkboxGroupInput(inputId = "graf_hist_var_gr",label = "select the factors",
                       choices = dati$var_ql,selected =dati$var_gr)
  })

  output$graf_hist_var_gr_dodge<-renderUI({
    req(dati$var_ql)
    req(input$graf_hist_var_gr)
    req(graf$var_gr)
    checkboxInput(inputId = "graf_hist_var_gr_dodge", label = "dodge", value = FALSE)
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
      checkboxGroupInput(inputId = "graf_hist_gr",label = "deselect the levels you are not interested in",
                         choices = unique(dati$DS[,input$graf_hist_var_gr]),selected =unique(dati$DS[,input$graf_hist_var_gr]))
    } else if (length(graf$var_gr)==2){
      lv<-unique(interaction(dati$DS[,input$graf_hist_var_gr[1]],dati$DS[,input$graf_hist_var_gr[2]]))
      checkboxGroupInput(inputId = "graf_hist_gr",label = "deselect the levels you are not interested in",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)==3){
      lv<-unique(interaction(dati$DS[,input$graf_hist_var_gr[1]],dati$DS[,input$graf_hist_var_gr[2]],dati$DS[,input$graf_hist_var_gr[3]]))
      checkboxGroupInput(inputId = "graf_hist_gr",label = "deselect the levels you are not interested in",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)>3){
      print("Maximum 3 factors")}
  })
  
  observeEvent(input$graf_hist_gr,ignoreNULL = FALSE,{
    graf$gr<-input$graf_hist_gr
  })

  output$graf_hist_bin<-renderUI({
    req(input$graf_hist_var%in%colnames(dati$DS))
    if(is.numeric(as.data.frame(dati$DS[,input$graf_hist_var,drop=FALSE])[,1])){

      sliderInput(inputId = "graf_hist_bin",label = "bar width",ticks = FALSE,
                  min = round((1/4)*(max(abs(dati$DS[,input$graf_hist_var]))-min(abs(dati$DS[,input$graf_hist_var])))/sqrt(nrow(dati$DS)),3),
                  max = round((7/4)*(max(abs(dati$DS[,input$graf_hist_var]))-min(abs(dati$DS[,input$graf_hist_var])))/sqrt(nrow(dati$DS)),3),
                  step = round((3/20)*(max(abs(dati$DS[,input$graf_hist_var]))-min(abs(dati$DS[,input$graf_hist_var])))/sqrt(nrow(dati$DS)),3),
                  value = round((max(dati$DS[,input$graf_hist_var])-min(dati$DS[,input$graf_hist_var]))/sqrt(nrow(dati$DS)),3)
                  )
    }else{
      sendSweetAlert(session, title = "Input Error",
                     text = 'Select a quantitative variable!',
                     type = "error",btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
    }
  })

  output$graf_hist<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0 & input$graf_hist_var%in%colnames(dati$DS),""))
    req(input$graf_hist_var)
    req(input$graf_hist_bin)
    req(is.numeric(as.data.frame(dati$DS[,input$graf_hist_var,drop=FALSE])[,1]))
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
    colnames(df)<-c("x","group")
    row.names(df)<-row.names(dati$DS)
    gr<-ggplot(df,mapping = aes(x=x))+labs(x=input$graf_hist_var)+theme_light()
    if(input$graf_hist_tipo=="count"){
      if(is.null(graf$gr)){
        gr+geom_histogram(binwidth = input$graf_hist_bin,fill="blue",col="white",aes(y = ..count..))+labs(y="count")
      } else {
        if(input$graf_hist_var_gr_dodge==FALSE){
          gr<-gr+geom_histogram(binwidth = input$graf_hist_bin,col="blue",aes(y = ..count..,fill=gruppo),position='identity',alpha=0.5)+labs(y="count")
          gr%+%subset(df,df$gruppo%in%graf$gr)
        }else{
          gr<-gr+geom_histogram(binwidth = input$graf_hist_bin,col="blue",aes(y = ..count..,fill=gruppo),position='dodge')+labs(y="count")
          gr%+%subset(df,df$gruppo%in%graf$gr)
        }
      }
    } else if (input$graf_hist_tipo=="percentage"){
      if(is.null(graf$gr)){
        gr+geom_histogram(binwidth = input$graf_hist_bin,fill="blue",col="white",aes(y = 100*(..count..)/sum(..count..)))+labs(y="percentage")
      } else {
        if(input$graf_hist_var_gr_dodge==FALSE){
          gr+geom_histogram(binwidth = input$graf_hist_bin,col="blue",aes(y = 100*(..count..)/sum(..count..),fill=gruppo),position='identity',alpha=0.5)+labs(y="percentage")
        }else{
          gr+geom_histogram(binwidth = input$graf_hist_bin,col="blue",aes(y = 100*(..count..)/sum(..count..),fill=gruppo),position='dodge')+labs(y="percentage")
        }
      }
    } else if (input$graf_hist_tipo=="density"){
      if(is.null(graf$gr)){
        gr+geom_histogram(binwidth = input$graf_hist_bin,fill="blue",col="white",aes(y = ..density..))+labs(y="density")
      } else {
        if(input$graf_hist_var_gr_dodge==FALSE){
          gr+geom_histogram(binwidth = input$graf_hist_bin,col="blue",aes(y = ..density..,fill=gruppo),position='identity',alpha=0.5)+labs(y="density")
        
        }else{
          gr+geom_histogram(binwidth = input$graf_hist_bin,col="blue",aes(y = ..density..,fill=gruppo),position='dodge')+labs(y="density")
        }
      }
    }
  })

# BoxPlot -----------------------------------------------------------------

  output$graf_box_var<-renderUI({
    selectizeInput(inputId = "graf_box_var"," ",
                   choices = dati$var_qt)})
  
  output$graf_box_var_gr<-renderUI({
    req(dati$var_ql)
    checkboxGroupInput(inputId = "graf_box_var_gr",label = "select the factors",
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
      checkboxGroupInput(inputId = "graf_box_gr",label = "deselect the levels you are not interested in",
                         choices = unique(dati$DS[,input$graf_box_var_gr]),selected =unique(dati$DS[,input$graf_box_var_gr]))
    } else if (length(graf$var_gr)==2){
      lv<-unique(interaction(dati$DS[,input$graf_box_var_gr[1]],dati$DS[,input$graf_box_var_gr[2]]))
      checkboxGroupInput(inputId = "graf_box_gr",label = "deselect the levels you are not interested in",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)==3){
      lv<-unique(interaction(dati$DS[,input$graf_box_var_gr[1]],dati$DS[,input$graf_box_var_gr[2]],dati$DS[,input$graf_box_var_gr[3]]))
      checkboxGroupInput(inputId = "graf_box_gr",label = "deselect the levels you are not interested in",
                         choices = lv,selected =lv)
    } else if (length(graf$var_gr)>3){
      print("Maximum 3 factors")}
  })

  observeEvent(input$graf_box_gr,ignoreNULL = FALSE,{
    graf$gr<-input$graf_box_gr
  })
  
  output$graf_box<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$graf_box_var%in%colnames(dati$DS))
    
    if(is.numeric(as.data.frame(dati$DS[,input$graf_box_var,drop=FALSE])[,1])){
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
        lab<-rep(" ",nrow(df))
      }
      df<-cbind.data.frame(df,lab)
      colnames(df)<-c("y","group")
      row.names(df)<-row.names(dati$DS)
      gr<-ggplot(df,mapping = aes(x=group,y=y))+labs(y=input$graf_box_var)+ theme_light()
      if(is.null(graf$gr)){
        gr+geom_boxplot(notch = input$graf_box_notch,fill="blue",width=0.5)+labs(x="")
      } else {
        gr<-gr+geom_boxplot(notch = input$graf_box_notch,mapping = aes(fill=group))+
          scale_x_discrete(limits=graf$gr)+theme(legend.position="none")
        gr%+%subset(df,df$group%in%graf$gr)
      }
      
    }else{
      sendSweetAlert(session, title = "Input Error",
                     text = 'Select a quantitative variable!',
                     type = "error",btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
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
    "Z-test"
  })
  
  output$ttest1_Test2<-renderText({
    validate(need(input$ttest1_var==2,""))
    "T-test"
  })
  
  output$ttest1_H0<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    if(is.numeric(as.data.frame(dati$DS[,input$ttest1_variab,drop=FALSE])[,1])){
      numericInput("ttest1_H0",label = "Assumed mean",
                   value=round(mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1]),3),width = "40%")
    }else{
      sendSweetAlert(session, title = "Input Error",
                     text = 'Select a quantitative variable!',
                     type = "error",btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
    }
  })
  
  output$ttest1_var_nota<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    req(input$ttest1_var==1)
    numericInput("ttest1_var_nota",label = "Known standard dev.",
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
        ylab("density")+xlab(expression(frac(bar(Y)[m]-mu,sigma * sqrt(1/m))))+ggtitle("N(0,1)")+
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
        text(0,0,"   At least 1 degree of freedom is needed \n
             sample size at least 2 \n",col="red",cex=2)
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
          ylab("density")+xlab(expression(frac(bar(Y)[m]-mu,S[m] * sqrt(1/m))))+ggtitle(paste("T(",dof,")",sep=""))+
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
    "Point estimate"
  })
  
  output$ttest1_media_camp<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    paste("sample mean =",round(mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1]),3))
  })
  
  output$ttest1_sd_camp<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    validate(need(input$ttest1_var=="2",""))
    paste("sample standard dev. =",round(sd(as.data.frame(dati$DS[,input$ttest1_variab])[,1]),3))
  })
  
  output$ttest1_stat<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    if(input$ttest1_var=="1"){
      paste("statistic =",round((mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1])-input$ttest1_H0)/
              (input$ttest1_var_nota*sqrt(1/nrow(as.data.frame(dati$DS[,input$ttest1_variab])))),4)) 
    }else{
     paste("statistic =",round((mean(as.data.frame(dati$DS[,input$ttest1_variab])[,1])-input$ttest1_H0)/
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
    "Interval estimation"
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
    paste("lower extreme =",round(media-q*s*sqrt(1/m),4))
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
    paste("upper extreme =",round(media+q*s*sqrt(1/m),4))
  })
  
  output$ttest1_qqplot<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest1_variab%in%colnames(dati$DS))
    ggplot(dati$DS,aes(sample=dati$DS[,input$ttest1_variab]))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="theoretical quantiles ",  y = "sample quantiles")+
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
    "Z-test"
  })
  
  output$ttest2a_Test2<-renderText({
    validate(need(input$ttest2a_var==2,""))
    "T-test"
  })
  
  output$ttest2a_variab2<-renderUI({
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    selectizeInput(inputId = "ttest2a_variab2"," ",
                   choices = dati$var_qt[!dati$var_qt%in%input$ttest2a_variab1])})
  
  output$ttest2a_H0<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    numericInput("ttest2a_H0",label = "Assumed mean differences",
                 value=0,width = "40%")
  })
  
  output$ttest2a_var_nota<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    req(input$ttest2a_var==1)
    numericInput("ttest2a_var_nota",label = "Known standard dev. differences",
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
    if(is.numeric(dati$DS[,input$ttest2a_variab1])&is.numeric(dati$DS[,input$ttest2a_variab2])){
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
          ylab("density")+xlab(expression(frac(bar(D)[m]-mu,sigma * sqrt(1/m))))+ggtitle("N(0,1)")+
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
          text(0,0,"   At least 1 degree of freedom is needed \n
             sample size at least 2 \n",col="red",cex=2)
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
            ylab("density")+xlab(expression(frac(bar(D)[m]-mu,S[m] * sqrt(1/m))))+ggtitle(paste("T(",dof,")",sep=""))+
            theme(plot.title = element_text(size = 20, face = "bold",
                                            hjust = 0.5))
          
          if(input$ttest2a_alfa>0){
            gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
              geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
          
          gr+geom_vline(xintercept = (mean(vrb[,1])-input$ttest2a_H0)/(ds*sqrt(1/nrow(vrb))),col="green") 
        }
      }
    }else{
      sendSweetAlert(session, title = "Input Error",
                     text = 'Select two quantitative variables!',
                     type = "error",btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
    }
  })
  
  output$ttest2a_media_camp_titolo<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    "Point estimate"
  })
  
  output$ttest2a_media_camp<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    paste("sample mean =",round(mean(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1]),3))
  })
  
  output$ttest2a_sd_camp<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    validate(need(input$ttest2a_var=="2",""))
    paste("sample standard dev. =",round(sd(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1]),3))
  })
  
  output$ttest2a_stat<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    if(input$ttest2_var=="1"){
      paste("statistic =",round((mean(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])-input$ttest2_H0)/
                                   (input$ttest2a_var_nota*sqrt(1/nrow(as.data.frame(dati$DS[,input$ttest2a_variab1])))),4)) 
    }else{
      paste("statistic =",round((mean(as.data.frame(dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2])[,1])-input$ttest2a_H0)/
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
    "Interval estimation"
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
    paste("lower extreme =",round(media-q*s*sqrt(1/m),4))
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
    paste("upper extreme =",round(media+q*s*sqrt(1/m),4))
  })
  
  output$ttest2a_qqplot<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2a_variab1%in%colnames(dati$DS))
    req(input$ttest2a_variab2%in%colnames(dati$DS))
    Diff<-dati$DS[,input$ttest2a_variab1]-dati$DS[,input$ttest2a_variab2]
    ggplot(dati$DS,aes(sample=Diff))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="theoretical quantiles",  y = "sample quantiles")+
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
    "Z-test"
  })
  
  output$ttest2_Test2<-renderText({
    validate(need(input$ttest2_var==2,""))
    "T-test"
  })
  
  output$ttest2_variab2<-renderUI({
    selectizeInput(inputId = "ttest2_variab2",div("Group variable",style="font-weight: 400;"),
                   choices = dati$var_ql)})
  
  output$ttest2_H0<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    numericInput("ttest2_H0",label = "Assumed mean differences",
                 value=0,width = "40%")
  })
  
  output$ttest2_var_nota1<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    req(input$ttest2_var==1)
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    numericInput("ttest2_var_nota1",label = "Known standard dev. gr. 1",
                 value=round(sd(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1]),3),width = "40%")
  })

  output$ttest2_var_nota2<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    req(input$ttest2_var==1)
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    numericInput("ttest2_var_nota2",label = "Known standard dev. gr. 2",
                 value=round(sd(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1]),3),width = "40%")
  })
  
  output$ttest2_var_uguale<-renderUI({
    validate(need(input$ttest2_var==2," "))
    radioButtons("ttest2_var_uguale", label = "",
                 choices = list("Equal variances" = 1, "Unequal variances" = 2),
                 selected = 2)
  })
  
  output$ttest2_H0_txt = renderUI({        
    HTML("H<SUB>0</SUB>: &mu;<SUB>1</SUB>-&mu;<SUB>2</SUB> =", input$ttest2_H0,"<p> H<SUB>1</SUB>: &mu;<SUB>1</SUB>-&mu;<SUB>2</SUB> &ne;",input$ttest2_H0)
  })
  
  output$ttest2_errore<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(!is.null(dati$var_ql),""))
    validate(need(length(unique(dati$DS[,input$ttest2_variab2]))!=2,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    "The group variable must have 2 levels"
  })

  output$ttest2_graf_distr<-renderPlot({
    require(ggplot2)
    validate(need(!is.null(dati$var_ql),""))
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
        ylab("density")+
        xlab(expression(frac((bar(Y)[m[1]]-bar(Y)[m[2]])-(mu[1]-mu[2]),sqrt(sigma[1]^2/m[1]+sigma[2]^2/m[2]))))+
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
        text(0,0,"Sample size at least 2 \n",col="red",cex=2)
      } else {
        ds1<-sd(vrb1[,1])
        ds2<-sd(vrb2[,1])
        if(input$ttest2_var_uguale==1){
          dof<-nrow(vrb1)+nrow(vrb2)-2
          x.text <- expression(frac((bar(Y)[m[1]]-bar(Y)[m[2]])-(mu[1]-mu[2]),S[c]*sqrt(1/m[1]+1/m[2])))
          sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
          stat <- ((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2)))
        }else{
          dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
            (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
          x.text <- expression(frac((bar(Y)[m[1]]-bar(Y)[m[2]])-(mu[1]-mu[2]),sqrt(S[m[1]]^2/m[1]+S[m[2]]^2/m[2])))
          stat <- ((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sqrt(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2)))
        }
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
          ylab("density")+xlab(x.text)+ggtitle(paste("T(",round(dof,3),")",sep=""))+
          theme(plot.title = element_text(size = 20, face = "bold",
                                          hjust = 0.5))
        
        if(input$ttest2_alfa>0){
          gr<-gr+geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
            geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
        
        gr+geom_vline(xintercept = stat,col="green") 
      }
    }

  })
  
  output$ttest2_media_camp_titolo<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    "Point estimate"
  })
  
  output$ttest2_media_camp1<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    paste("sample mean gr 1 =",round(mean(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1]),3))
  })
  
  output$ttest2_media_camp2<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    paste("sample mean gr 2 =",round(mean(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1]),3))
  })
  
  output$ttest2_sd_camp1<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    validate(need(input$ttest2_var=="2",""))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    paste("sample standard dev. gr 1=",round(sd(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1]),3))
  })
  
  output$ttest2_sd_camp2<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    validate(need(input$ttest2_var=="2",""))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    paste("sample standard dev. gr 2=",round(sd(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1]),3))
  })
  
  output$ttest2_ds_c<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(input$ttest2_var_uguale==1,""))
    req(input$ttest2_variab1%in%colnames(dati$DS))
    req(input$ttest2_variab2%in%colnames(dati$DS))
    validate(need(input$ttest2_var=="2",""))
    gruppi<-unique(dati$DS[,input$ttest2_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[1],input$ttest2_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$ttest2_variab2]==gruppi[2],input$ttest2_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
    paste("pooled standard dev. =",round(sc,3))
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
      paste("statistic =",round(((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sqrt(input$ttest2_var_nota1^2/nrow(vrb1)+input$ttest2_var_nota2^2/nrow(vrb2))),4)) 
    }else{
      if(input$ttest2_var_uguale==1){
        paste("statistic =",round(((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2))),4))
      }else{
        paste("statistic =",round(((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sqrt(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))),4))
      }
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
      if(input$ttest2_var_uguale==1){
        q<-((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2)))
        dof<-nrow(vrb1)+nrow(vrb2)-2
      }else{
        q<-((mean(vrb1[,1])-mean(vrb2[,1]))-input$ttest2_H0)/(sqrt(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2)))
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
    "Interval estimation"
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
      paste("lower extreme =",round(media-q*sqrt(s1^2/m1+s2^2/m2),4))
    } else {
      ds1<-sd(vrb1[,1])
      ds2<-sd(vrb2[,1])
      sc<-sqrt(((m1-1)*ds1^2+(m2-1)*ds2^2)/(m1+m2-2))
      if(input$ttest2_var_uguale==1){
        dof<-nrow(vrb1)+nrow(vrb2)-2
        q<-qt(input$ttest2_alfa/2,df = dof,lower.tail = FALSE)
        paste("lower extreme =",round(media-q*sc*sqrt(1/m1+1/m2),4))
      }else{
        dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
          (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
        q<-qt(input$ttest2_alfa/2,df = dof,lower.tail = FALSE)
        paste("lower extreme =",round(media-q*sqrt(ds1^2/m1+ds2^2/m2),4))
      }
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
      paste("upper extreme =",round(media+q*sqrt(s1^2/m1+s2^2/m2),4))
    } else {
      ds1<-sd(vrb1[,1])
      ds2<-sd(vrb2[,1])
      sc<-sqrt(((m1-1)*ds1^2+(m2-1)*ds2^2)/(m1+m2-2))
      if(input$ttest2_var_uguale==1){
        dof<-nrow(vrb1)+nrow(vrb2)-2
        q<-qt(input$ttest2_alfa/2,df = dof,lower.tail = FALSE)
        paste("upper extreme =",round(media+q*sc*sqrt(1/m1+1/m2),4))
      }else{
        dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
          (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
        q<-qt(input$ttest2_alfa/2,df = dof,lower.tail = FALSE)
        paste("upper extreme =",round(media+q*sqrt(ds1^2/m1+ds2^2/m2),4))
      }
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
      labs(x="theoretical quantiles",  y = "sample quantiles")+
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
      labs(x="theoretical quantiles",  y = "sample quantiles")+
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

  # equiv_test -----------------------------------------------------------------
  
  output$equiv_variab1<-renderUI({
    selectizeInput(inputId = "equiv_variab1"," ",
                   choices = dati$var_qt)
    })
  
  output$equiv_variab2<-renderUI({
    selectizeInput(inputId = "equiv_variab2",div("Group variable",style="font-weight: 400;"),
                   choices = dati$var_ql)
    })
  
  output$equiv_H0<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    numericInput("equiv_H0",label = HTML("Critical difference for equivalence &delta;"),
                 value=1,width = "40%")
    })
  
  output$equiv_var_nota1<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    req(input$equiv_var==1)
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    numericInput("equiv_var_nota1",label = "Known standard dev. gr. 1",
                 value=round(sd(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[1],input$equiv_variab1]),3),width = "40%")
    })
  
  output$equiv_var_nota2<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    req(input$equiv_var==1)
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    numericInput("equiv_var_nota2",label = "Known standard dev. gr. 2",
                 value=round(sd(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[2],input$equiv_variab1]),3),width = "40%")
  })
  
  output$equiv_var_uguale<-renderUI({
    validate(need(input$equiv_var==2," "))
    radioButtons("equiv_var_uguale", label = "",
                 choices = list("Equal variances" = 1, "Unequal variances" = 2),
                 selected = 2)
  })

  output$equiv_Test1_1<-renderText({
    validate(need(input$equiv_var==1,""))
    "Z-test 1"
  })
  
  output$equiv_Test1_2<-renderText({
    validate(need(input$equiv_var==2,""))
    "T-test 1"
  })
  
  output$equiv_H0_txt1 = renderUI({        
    HTML("H<SUB>0</SUB>: &mu;<SUB>1</SUB>-&mu;<SUB>2</SUB> = -", input$equiv_H0,"<p> H<SUB>1</SUB>: &mu;<SUB>1</SUB>-&mu;<SUB>2</SUB> &gt; -",input$equiv_H0)
  })

  output$equiv_errore1<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(!is.null(dati$var_ql),""))
    validate(need(length(unique(dati$DS[,input$equiv_variab2]))!=2,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    "The group variable must have 2 levels"
  })
  
  output$equiv_graf_distr1<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(!is.null(dati$var_ql),""))
    validate(need(length(unique(dati$DS[,input$equiv_variab2]))==2,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[1],input$equiv_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[2],input$equiv_variab1])
    
    x<-seq(-6, 6,by = 0.1)
    if(input$equiv_var==1){
      df<-cbind.data.frame(x=x,y=dnorm(x,mean=0,sd=1))
      if(input$equiv_alfa>0){
        q<-qnorm(input$equiv_alfa,mean = 0,sd = 1,lower.tail = FALSE)
        if(q>6) q<-6
        x.b<-seq(q,6,by = 0.1)
        # x.a<- -x.b[order(x.b,decreasing = TRUE)]
        # df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =0,sd = 1))
        # df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =0,sd = 1))
        df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      }
      gr<-ggplot() +theme_classic()+
        geom_line(data = df,mapping = aes(x=x,y=y))+
        ylab("density")+
        xlab(expression(frac((bar(Y)[m[1]]-bar(Y)[m[2]])+ delta,sqrt(sigma[1]^2/m[1]+sigma[2]^2/m[2]))))+
        ggtitle("N(0,1)")+
        theme(plot.title = element_text(size = 20, face = "bold",
                                        hjust = 0.5))
      
      if(input$equiv_alfa>0){
        gr<-gr+
          # geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
      gr+geom_vline(xintercept = ((mean(vrb1[,1])-mean(vrb2[,1]))+input$equiv_H0)/(sqrt(input$equiv_var_nota1^2/nrow(vrb1)+input$equiv_var_nota2^2/nrow(vrb2))),col="green")
    } else {
      if (nrow(vrb1)==1 | nrow(vrb2) ==1){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Sample size at least 2 \n",col="red",cex=2)
      } else {
        ds1<-sd(vrb1[,1])
        ds2<-sd(vrb2[,1])
        if(input$equiv_var_uguale==1){
          dof<-nrow(vrb1)+nrow(vrb2)-2
          x.text <- expression(frac((bar(Y)[m[1]]-bar(Y)[m[2]])+ delta,S[c]*sqrt(1/m[1]+1/m[2])))
          sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
          stat <- ((mean(vrb1[,1])-mean(vrb2[,1]))+input$equiv_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2)))
        }else{
          dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
            (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
          x.text <- expression(frac((bar(Y)[m[1]]-bar(Y)[m[2]])+delta,sqrt(S[m[1]]^2/m[1]+S[m[2]]^2/m[2])))
          stat <- ((mean(vrb1[,1])-mean(vrb2[,1]))+input$equiv_H0)/(sqrt(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2)))
        }
        df<-cbind.data.frame(x=x,y=dt(x,df = dof))
        if(input$equiv_alfa>0){
          q<-qt(input$equiv_alfa,df = dof,lower.tail = FALSE)
          if(q>6) q<-6
          x.b<-seq(q,6,by = 0.1)
          # x.a<- -x.b[order(x.b,decreasing = TRUE)]
          # df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
          # df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
          df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
          df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        }
        
        gr<-ggplot() +theme_classic()+
          geom_line(data = df,mapping = aes(x=x,y=y))+
          ylab("density")+xlab(x.text)+ggtitle(paste("T(",round(dof,3),")",sep=""))+
          theme(plot.title = element_text(size = 20, face = "bold",
                                          hjust = 0.5))
        
        if(input$equiv_alfa>0){
          gr<-gr+
            # geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
            geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
        
        gr+geom_vline(xintercept = stat,col="green") 
      }
    }
  })

  output$equiv_stat1<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[1],input$equiv_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[2],input$equiv_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
    if(input$equiv_var=="1"){
      paste("statistic =",round(((mean(vrb1[,1])-mean(vrb2[,1]))+input$equiv_H0)/(sqrt(input$equiv_var_nota1^2/nrow(vrb1)+input$equiv_var_nota2^2/nrow(vrb2))),4)) 
    }else{
      if(input$equiv_var_uguale==1){
        paste("statistic =",round(((mean(vrb1[,1])-mean(vrb2[,1]))+input$equiv_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2))),4))
      }else{
        paste("statistic =",round(((mean(vrb1[,1])-mean(vrb2[,1]))+input$equiv_H0)/(sqrt(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))),4))
      }
    }
  })  

  equiv_pval1 <- reactive({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[1],input$equiv_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[2],input$equiv_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
    if(input$equiv_var=="1"){
      q<-((mean(vrb1[,1])-mean(vrb2[,1]))+input$equiv_H0)/(sqrt(input$equiv_var_nota1^2/nrow(vrb1)+input$equiv_var_nota2^2/nrow(vrb2)))
      p<-pnorm(q = q,mean = 0,sd = 1,lower.tail = FALSE)
      # p<-format(p,digits = 4,format="e")
    }else{
      if(input$equiv_var_uguale==1){
        q<-((mean(vrb1[,1])-mean(vrb2[,1]))+input$equiv_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2)))
        dof<-nrow(vrb1)+nrow(vrb2)-2
      }else{
        q<-((mean(vrb1[,1])-mean(vrb2[,1]))+input$equiv_H0)/(sqrt(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2)))
        dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
          (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
      }
      p<-pt(q = q,df = dof,lower.tail = FALSE)
      # p<-format(p,digits = 4,format="e")
    }
    p
  })

  output$equiv_pval1<-renderText({
    p <- equiv_pval1()
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 

  output$equiv_Test2_1<-renderText({
    validate(need(input$equiv_var==1,""))
    "Z-test 2"
  })
  
  output$equiv_Test2_2<-renderText({
    validate(need(input$equiv_var==2,""))
    "T-test 2"
  })
  
  output$equiv_H0_txt2 = renderUI({        
    HTML("H<SUB>0</SUB>: &mu;<SUB>1</SUB>-&mu;<SUB>2</SUB> = ", input$equiv_H0,"<p> H<SUB>1</SUB>: &mu;<SUB>1</SUB>-&mu;<SUB>2</SUB> &lt; ",input$equiv_H0)
  })
  
  output$equiv_errore2<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(!is.null(dati$var_ql),""))
    validate(need(length(unique(dati$DS[,input$equiv_variab2]))!=2,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    "The group variable must have 2 levels"
  })
  
  output$equiv_graf_distr2<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(!is.null(dati$var_ql),""))
    validate(need(length(unique(dati$DS[,input$equiv_variab2]))==2,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[1],input$equiv_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[2],input$equiv_variab1])
    
    x<-seq(-6, 6,by = 0.1)
    if(input$equiv_var==1){
      df<-cbind.data.frame(x=x,y=dnorm(x,mean=0,sd=1))
      if(input$equiv_alfa>0){
        q<-qnorm(input$equiv_alfa,mean = 0,sd = 1,lower.tail = FALSE)
        if(q>6) q<-6
        x.b<-seq(q,6,by = 0.1)
        x.a<- -x.b[order(x.b,decreasing = TRUE)]
        df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =0,sd = 1))
        df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
        # df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =0,sd = 1))
        # df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
      }
      gr<-ggplot() +theme_classic()+
        geom_line(data = df,mapping = aes(x=x,y=y))+
        ylab("density")+
        xlab(expression(frac((bar(Y)[m[1]]-bar(Y)[m[2]])- delta,sqrt(sigma[1]^2/m[1]+sigma[2]^2/m[2]))))+
        ggtitle("N(0,1)")+
        theme(plot.title = element_text(size = 20, face = "bold",
                                        hjust = 0.5))
      
      if(input$equiv_alfa>0){
        gr<-gr+
          geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
        # +
          # geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")
        } 
      gr+geom_vline(xintercept = ((mean(vrb1[,1])-mean(vrb2[,1]))-input$equiv_H0)/(sqrt(input$equiv_var_nota1^2/nrow(vrb1)+input$equiv_var_nota2^2/nrow(vrb2))),col="green")
    } else {
      if (nrow(vrb1)==1 | nrow(vrb2) ==1){
        plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
        text(0,0,"Sample size at least 2 \n",col="red",cex=2)
      } else {
        ds1<-sd(vrb1[,1])
        ds2<-sd(vrb2[,1])
        if(input$equiv_var_uguale==1){
          dof<-nrow(vrb1)+nrow(vrb2)-2
          x.text <- expression(frac((bar(Y)[m[1]]-bar(Y)[m[2]])-delta,S[c]*sqrt(1/m[1]+1/m[2])))
          sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
          stat <- ((mean(vrb1[,1])-mean(vrb2[,1]))-input$equiv_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2)))
        }else{
          dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
            (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
          x.text <- expression(frac((bar(Y)[m[1]]-bar(Y)[m[2]])-delta,sqrt(S[m[1]]^2/m[1]+S[m[2]]^2/m[2])))
          stat <- ((mean(vrb1[,1])-mean(vrb2[,1]))-input$equiv_H0)/(sqrt(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2)))
        }
        
        df<-cbind.data.frame(x=x,y=dt(x,df = dof))
        if(input$equiv_alfa>0){
          q<-qt(input$equiv_alfa,df = dof,lower.tail = FALSE)
          if(q>6) q<-6
          x.b<-seq(q,6,by = 0.1)
          x.a<- -x.b[order(x.b,decreasing = TRUE)]
          df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
          df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
          # df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
          # df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        }
        
        gr<-ggplot() +theme_classic()+
          geom_line(data = df,mapping = aes(x=x,y=y))+
          ylab("density")+xlab(x.text)+ggtitle(paste("T(",round(dof,3),")",sep=""))+
          theme(plot.title = element_text(size = 20, face = "bold",
                                          hjust = 0.5))
        
        if(input$equiv_alfa>0){
          gr<-gr+
            geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
            # +
            # geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")
            } 
        
        gr+geom_vline(xintercept = stat,col="green") 
      }
    }
  })

  output$equiv_stat2<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[1],input$equiv_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[2],input$equiv_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
    if(input$equiv_var=="1"){
      paste("statistic =",round(((mean(vrb1[,1])-mean(vrb2[,1]))-input$equiv_H0)/(sqrt(input$equiv_var_nota1^2/nrow(vrb1)+input$equiv_var_nota2^2/nrow(vrb2))),4)) 
    }else{
      if(input$equiv_var_uguale==1){
        paste("statistic =",round(((mean(vrb1[,1])-mean(vrb2[,1]))-input$equiv_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2))),4))
      }else{
        paste("statistic =",round(((mean(vrb1[,1])-mean(vrb2[,1]))-input$equiv_H0)/(sqrt(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))),4))
      }
    }
  })  

  equiv_pval2 <- reactive({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[1],input$equiv_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[2],input$equiv_variab1])
    ds1<-sd(vrb1[,1])
    ds2<-sd(vrb2[,1])
    sc<-sqrt(((nrow(vrb1)-1)*ds1^2+(nrow(vrb2)-1)*ds2^2)/(nrow(vrb1)+nrow(vrb2)-2))
    if(input$equiv_var=="1"){
      q<-((mean(vrb1[,1])-mean(vrb2[,1]))-input$equiv_H0)/(sqrt(input$equiv_var_nota1^2/nrow(vrb1)+input$equiv_var_nota2^2/nrow(vrb2)))
      p<-pnorm(q = q,mean = 0,sd = 1,lower.tail = TRUE)
      # p<-format(p,digits = 4,format="e")
    }else{
      if(input$equiv_var_uguale==1){
        q<-((mean(vrb1[,1])-mean(vrb2[,1]))-input$equiv_H0)/(sc*sqrt(1/nrow(vrb1)+1/nrow(vrb2)))
        dof<-nrow(vrb1)+nrow(vrb2)-2
      }else{
        q<-((mean(vrb1[,1])-mean(vrb2[,1]))-input$equiv_H0)/(sqrt(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2)))
        dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
          (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
      }
      p<-pt(q = q,df = dof,lower.tail = TRUE)
      # p<-format(p,digits = 4,format="e")
    }
    p
  })

  output$equiv_pval2<-renderText({
    p <- equiv_pval2()
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 

  output$equiv_ic_titolo<-renderText({
    validate(need(input$equiv_alfa>0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    "Confidence interval"
  })
  
  equiv_ic_inf <- reactive({
    validate(need(input$equiv_alfa>0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[1],input$equiv_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[2],input$equiv_variab1])
    media<-mean(vrb1[,1])-mean(vrb2[,1])
    m1<-nrow(vrb1)
    m2<-nrow(vrb2)
    if(input$equiv_var==1){
      s1<-input$equiv_var_nota1
      s2<-input$equiv_var_nota2
      q<-qnorm(input$equiv_alfa,mean = 0,sd = 1,lower.tail = FALSE)
      ei <- media-q*sqrt(s1^2/m1+s2^2/m2)
    } else {
      ds1<-sd(vrb1[,1])
      ds2<-sd(vrb2[,1])
      sc<-sqrt(((m1-1)*ds1^2+(m2-1)*ds2^2)/(m1+m2-2))
      if(input$equiv_var_uguale==1){
        dof<-nrow(vrb1)+nrow(vrb2)-2
        q<-qt(input$equiv_alfa,df = dof,lower.tail = FALSE)
        ei <- media-q*sc*sqrt(1/m1+1/m2)
      }else{
        dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
          (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
        q<-qt(input$equiv_alfa,df = dof,lower.tail = FALSE)
        ei <- media-q*sqrt(ds1^2/m1+ds2^2/m2)
      }
    }
    ei
  })
  
  output$equiv_ic_inf<-renderText({
    paste("lower extreme =",round(equiv_ic_inf(),4))
  })
  
  equiv_ic_sup <- reactive({
    validate(need(input$equiv_alfa>0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    vrb1<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[1],input$equiv_variab1])
    vrb2<-as.data.frame(dati$DS[dati$DS[,input$equiv_variab2]==gruppi[2],input$equiv_variab1])
    media<-mean(vrb1[,1])-mean(vrb2[,1])
    m1<-nrow(vrb1)
    m2<-nrow(vrb2)
    if(input$equiv_var==1){
      s1<-input$equiv_var_nota1
      s2<-input$equiv_var_nota2
      q<-qnorm(input$equiv_alfa,mean = 0,sd = 1,lower.tail = FALSE)
      es <- media+q*sqrt(s1^2/m1+s2^2/m2)
    } else {
      ds1<-sd(vrb1[,1])
      ds2<-sd(vrb2[,1])
      sc<-sqrt(((m1-1)*ds1^2+(m2-1)*ds2^2)/(m1+m2-2))
      if(input$equiv_var_uguale==1){
        dof<-nrow(vrb1)+nrow(vrb2)-2
        q<-qt(input$equiv_alfa,df = dof,lower.tail = FALSE)
        es <- media+q*sc*sqrt(1/m1+1/m2)
      }else{
        dof<-(ds1^2/nrow(vrb1)+ds2^2/nrow(vrb2))^2/
          (ds1^4/(nrow(vrb1)^2*(nrow(vrb1)-1))+ds2^4/(nrow(vrb2)^2*(nrow(vrb2)-1)))
        q<-qt(input$equiv_alfa,df = dof,lower.tail = FALSE)
      es <- media+q*sqrt(ds1^2/m1+ds2^2/m2)
      }
    }
  })
  
  output$equiv_ic_sup<-renderText({
    paste("upper extreme =",round(equiv_ic_sup(),4))
  })
  
  output$equiv_pval<-renderText({
    p <- max(equiv_pval1(),equiv_pval2())
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 

  output$equiv_graf_intconf <- renderPlot({
    req(input$equiv_H0)
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(length(unique(dati$DS[,input$equiv_variab2]))==2,""))
    
    delta <- input$equiv_H0
    inf <- equiv_ic_inf()
    sup <- equiv_ic_sup()
    pval <- max(equiv_pval1(),equiv_pval2())
    
    plot(x=0,y=0,type="n",frame.plot = FALSE,yaxt="n",xlab="",ylab="",xlim=c(-2*delta,2*delta))
    abline(v=-delta,lty=2,col="blue")
    mtext(text =expression(-delta),at = -delta,side = 1,line = 2,col="blue")
    abline(v=delta,lty=2,col="blue")
    mtext(text =expression(-delta),at = delta,side = 1,line = 2,col="blue" )

    arrows(x0 = inf,y0 = 0,x1 = sup,y1 = 0,length = 0.1,angle = 90,code = 3,col = "green4")

    if(pval<0.05){
      txt <- "equiv."
    }else{
      txt <- "not equiv."
    }

    mtext(text =txt,at =(inf+sup)/2,side = 1,line = 2,col="green4",cex=0.8 )
  })

  output$equiv_qqplot1<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    dati<-dati$DS[dati$DS[,input$equiv_variab2]==gruppi[1],]
    ggplot(dati,aes(sample=dati[,input$equiv_variab1]))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="theoretical quantiles",  y = "sample quantiles")+
      theme_classic()
  })
  
  output$equiv_shapiro1<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    dati<-dati$DS[dati$DS[,input$equiv_variab2]==gruppi[1],]
    Campione.1<-dati[,input$equiv_variab1]
    shapiro.test(Campione.1)
  })
  
  output$equiv_qqplot2<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    dati<-dati$DS[dati$DS[,input$equiv_variab2]==gruppi[2],]
    ggplot(dati,aes(sample=dati[,input$equiv_variab1]))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="theoretical quantiles",  y = "sample quantiles")+
      theme_classic()
  })
  
  output$equiv_shapiro2<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiv_variab1%in%colnames(dati$DS))
    req(input$equiv_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$equiv_variab2])
    dati<-dati$DS[dati$DS[,input$equiv_variab2]==gruppi[2],]
    Campione.2<-dati[,input$equiv_variab1]
    shapiro.test(Campione.2) 
  }) 

  # equiv_test_a -----------------------------------------------------------------
  
  output$equiva_variab1<-renderUI({
    selectizeInput(inputId = "equiva_variab1"," ",
                   choices = dati$var_qt)})
  
  output$equiva_variab2<-renderUI({
    req(input$equiva_variab1%in%colnames(dati$DS))
    selectizeInput(inputId = "equiva_variab2"," ",
                   choices = dati$var_qt[!dati$var_qt%in%input$equiva_variab1])})
  
  output$equiva_H0<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    numericInput("equiva_H0",label = HTML("Critical difference for equivalence &delta;"),
                 value=1,width = "40%")
  })
  
  output$equiva_var_nota<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    req(input$equiva_var==1)
    numericInput("equiva_var_nota",label = "Known standard dev. differences",
                 value=round(sd(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1]),3),width = "40%")
  })

  output$equiva_Test1_1<-renderText({
    validate(need(input$equiva_var==1,""))
    "Z-test 1"
  })
  
  output$equiva_Test1_2<-renderText({
    validate(need(input$equiva_var==2,""))
    "T-test 1"
  })
  
  output$equiva_H0_txt1 = renderUI({        
    HTML("H<SUB>0</SUB>: &mu;<SUB>d</SUB> = -", input$equiva_H0,"<p> H<SUB>1</SUB>: &mu;<SUB>d</SUB> &gt; -",input$equiva_H0)
  })
  
  output$equiva_graf_distr1<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    if(is.numeric(dati$DS[,input$equiva_variab1])&is.numeric(dati$DS[,input$equiva_variab2])){
      vrb<-as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])
      x<-seq(-6, 6,by = 0.1)
      if(input$equiva_var==1){
        df<-cbind.data.frame(x=x,y=dnorm(x,mean=0,sd=1))
        if(input$equiva_alfa>0){
          q<-qnorm(input$equiva_alfa,mean = 0,sd = 1,lower.tail = FALSE)
          if(q>6) q<-6
          x.b<-seq(q,6,by = 0.1)
          # x.a<- -x.b[order(x.b,decreasing = TRUE)]
          # df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =0,sd = 1))
          # df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
          df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =0,sd = 1))
          df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        }
        gr<-ggplot() +theme_classic()+
          geom_line(data = df,mapping = aes(x=x,y=y))+
          ylab("density")+xlab(expression(frac(bar(D)[m]+delta,sigma * sqrt(1/m))))+ggtitle("N(0,1)")+
          theme(plot.title = element_text(size = 20, face = "bold",
                                          hjust = 0.5))
        
        if(input$equiva_alfa>0){
          gr<-gr+
            # geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
            geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
        gr+geom_vline(xintercept = (mean(vrb[,1])+input$equiva_H0)/(input$equiva_var_nota*sqrt(1/nrow(vrb))),col="green")
      } else {
        dof<-nrow(vrb)-1
        if (dof==0){
          plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
          text(0,0,"   At least 1 degree of freedom is needed \n
             sample size at least 2 \n",col="red",cex=2)
        } else {
          ds<-sd(vrb[,1])
          df<-cbind.data.frame(x=x,y=dt(x,df = dof))
          if(input$equiva_alfa>0){
            q<-qt(input$equiva_alfa,df = dof,lower.tail = FALSE)
            if(q>6) q<-6
            x.b<-seq(q,6,by = 0.1)
            # x.a<- -x.b[order(x.b,decreasing = TRUE)]
            # df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
            # df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
            df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
            df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
          }
          
          gr<-ggplot() +theme_classic()+
            geom_line(data = df,mapping = aes(x=x,y=y))+
            ylab("density")+xlab(expression(frac(bar(D)[m]+delta,S[m] * sqrt(1/m))))+ggtitle(paste("T(",dof,")",sep=""))+
            theme(plot.title = element_text(size = 20, face = "bold",
                                            hjust = 0.5))
          
          if(input$equiva_alfa>0){
            gr<-gr+
              # geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")+
              geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")} 
          
          gr+geom_vline(xintercept = (mean(vrb[,1])+input$equiva_H0)/(ds*sqrt(1/nrow(vrb))),col="green") 
        }
      }
    }else{
      sendSweetAlert(session, title = "Input Error",
                     text = 'Select two quantitative variables!',
                     type = "error",btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
    }
  })

  output$equiva_stat1<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    if(input$ttest2_var=="1"){
      paste("statistic =",round((mean(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])+input$ttest2_H0)/
                                   (input$equiva_var_nota*sqrt(1/nrow(as.data.frame(dati$DS[,input$equiva_variab1])))),4)) 
    }else{
      paste("statistic =",round((mean(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])+input$equiva_H0)/
                                   (sd(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])*sqrt(1/nrow(as.data.frame(dati$DS[,input$equiva_variab1])))),4)) 
    }
  }) 

  equiva_pval1<- reactive({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    if(input$equiva_var=="1"){
      q<-(mean(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])+input$equiva_H0)/
        (input$equiva_var_nota*sqrt(1/nrow(as.data.frame(dati$DS[,input$equiva_variab1])))) 
      p<-pnorm(q = abs(q),mean = 0,sd = 1,lower.tail = FALSE)
      # p<-format(2*p,digits = 4,format="e")
    }else{
      q<-(mean(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])+input$equiva_H0)/
        (sd(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])*sqrt(1/nrow(as.data.frame(dati$DS[,input$equiva_variab1]))))
      dof<-nrow(as.data.frame(dati$DS[,input$equiva_variab1]))-1
      p<-pt(q = abs(q),df = dof,lower.tail = FALSE)
      # p<-format(2*p,digits = 4,format="e")
    }
    p
  })

  output$equiva_pval1<-renderText({
    p <- equiva_pval1()
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 

  output$equiva_Test2_1<-renderText({
    validate(need(input$equiva_var==1,""))
    "Z-test 2"
  })
  
  output$equiva_Test2_2<-renderText({
    validate(need(input$equiva_var==2,""))
    "Z-test 2"
  })
  
  output$equiva_H0_txt2 = renderUI({        
    HTML("H<SUB>0</SUB>: &mu;<SUB>d</SUB> = ", input$equiva_H0,"<p> H<SUB>1</SUB>: &mu;<SUB>d</SUB> &lt;",input$equiva_H0)
  })
  
  output$equiva_graf_distr2<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    if(is.numeric(dati$DS[,input$equiva_variab1])&is.numeric(dati$DS[,input$equiva_variab2])){
      vrb<-as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])
      x<-seq(-6, 6,by = 0.1)
      if(input$equiva_var==1){
        df<-cbind.data.frame(x=x,y=dnorm(x,mean=0,sd=1))
        if(input$equiva_alfa>0){
          q<-qnorm(input$equiva_alfa,mean = 0,sd = 1,lower.tail = FALSE)
          if(q>6) q<-6
          x.b<-seq(q,6,by = 0.1)
          x.a<- -x.b[order(x.b,decreasing = TRUE)]
          df.a<-cbind.data.frame(x=x.a,y=dnorm(x.a,mean =0,sd = 1))
          df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
          # df.b<-cbind.data.frame(x=x.b,y=dnorm(x.b,mean =0,sd = 1))
          # df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
        }
        gr<-ggplot() +theme_classic()+
          geom_line(data = df,mapping = aes(x=x,y=y))+
          ylab("density")+xlab(expression(frac(bar(D)[m]-delta,sigma * sqrt(1/m))))+ggtitle("N(0,1)")+
          theme(plot.title = element_text(size = 20, face = "bold",
                                          hjust = 0.5))
        
        if(input$equiva_alfa>0){
          gr<-gr+
            geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
          # +
          # geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")
        } 
        gr+geom_vline(xintercept = (mean(vrb[,1])-input$equiva_H0)/(input$equiva_var_nota*sqrt(1/nrow(vrb))),col="green")
      } else {
        dof<-nrow(vrb)-1
        if (dof==0){
          plot(0,0,type='n',axes=FALSE,xlab="",ylab="")
          text(0,0,"   At least 1 degree of freedom is needed \n
             sample size at least 2 \n",col="red",cex=2)
        } else {
          ds<-sd(vrb[,1])
          df<-cbind.data.frame(x=x,y=dt(x,df = dof))
          if(input$equiva_alfa>0){
            q<-qt(input$equiva_alfa,df = dof,lower.tail = FALSE)
            if(q>6) q<-6
            x.b<-seq(q,6,by = 0.1)
            x.a<- -x.b[order(x.b,decreasing = TRUE)]
            df.a<-cbind.data.frame(x=x.a,y=dt(x.a,df = dof))
            df.a<-rbind(c(min(x.a), 0), df.a, c(max(x.a), 0))
            # df.b<-cbind.data.frame(x=x.b,y=dt(x.b,df = dof))
            # df.b<-rbind(c(min(x.b), 0), df.b, c(max(x.b), 0)) 
          }
          
          gr<-ggplot() +theme_classic()+
            geom_line(data = df,mapping = aes(x=x,y=y))+
            ylab("density")+xlab(expression(frac(bar(D)[m]-delta,S[m] * sqrt(1/m))))+ggtitle(paste("T(",dof,")",sep=""))+
            theme(plot.title = element_text(size = 20, face = "bold",
                                            hjust = 0.5))
          
          if(input$equiva_alfa>0){
            gr<-gr+
              geom_polygon(df.a,mapping = aes(x=x,y=y),fill="blue")
            # +
            # geom_polygon(df.b,mapping = aes(x=x,y=y),fill="blue")
          } 
          
          gr+geom_vline(xintercept = (mean(vrb[,1])-input$equiva_H0)/(ds*sqrt(1/nrow(vrb))),col="green") 
        }
      }
    }else{
      sendSweetAlert(session, title = "Input Error",
                     text = 'Select two quantitative variables!',
                     type = "error",btn_labels = "Ok", html = FALSE, closeOnClickOutside = TRUE)
    }
  })

  output$equiva_stat2<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    if(input$ttest2_var=="1"){
      paste("statistic =",round((mean(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])-input$ttest2_H0)/
                                   (input$equiva_var_nota*sqrt(1/nrow(as.data.frame(dati$DS[,input$equiva_variab1])))),4)) 
    }else{
      paste("statistic =",round((mean(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])-input$equiva_H0)/
                                   (sd(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])*sqrt(1/nrow(as.data.frame(dati$DS[,input$equiva_variab1])))),4)) 
    }
  }) 

  equiva_pval2<- reactive({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    if(input$equiva_var=="1"){
      q<-(mean(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])-input$equiva_H0)/
        (input$equiva_var_nota*sqrt(1/nrow(as.data.frame(dati$DS[,input$equiva_variab1])))) 
      p<-pnorm(q = abs(q),mean = 0,sd = 1,lower.tail = FALSE)
      # p<-format(2*p,digits = 4,format="e")
    }else{
      q<-(mean(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])-input$equiva_H0)/
        (sd(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])*sqrt(1/nrow(as.data.frame(dati$DS[,input$equiva_variab1]))))
      dof<-nrow(as.data.frame(dati$DS[,input$equiva_variab1]))-1
      p<-pt(q = abs(q),df = dof,lower.tail = FALSE)
      # p<-format(2*p,digits = 4,format="e")
    }
    p
  })

  output$equiva_pval2<-renderText({
    p <- equiva_pval2()
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 

  output$equiva_ic_titolo<-renderText({
    validate(need(input$equiva_alfa>0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    "Confidence interval"
  })

  equiva_ic_inf <- reactive({
    validate(need(input$equiva_alfa>0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    media<-mean(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])
    m<-nrow(as.data.frame(dati$DS[,input$equiva_variab1]))
    if(input$equiva_var==1){
      s<-input$equiva_var_nota
      q<-qnorm(input$equiva_alfa,mean = 0,sd = 1,lower.tail = FALSE)
    } else {
      s<-sd(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])
      q<-qt(input$equiva_alfa,df = m-1,lower.tail = FALSE)
    }
    ei <- media-q*s*sqrt(1/m)
    ei
  })

  output$equiva_ic_inf<-renderText({
    paste("lower extreme =",round(equiva_ic_inf(),4))
  })

  equiva_ic_sup <- reactive({
    validate(need(input$equiva_alfa>0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    media<-mean(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])
    m<-nrow(as.data.frame(dati$DS[,input$equiva_variab1]))
    if(input$equiva_var==1){
      s<-input$equiva_var_nota
      q<-qnorm(input$equiva_alfa,mean = 0,sd = 1,lower.tail = FALSE)
    } else {
      s<-sd(as.data.frame(dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2])[,1])
      q<-qt(input$equiva_alfa,df = m-1,lower.tail = FALSE)
    }
    es <- media+q*s*sqrt(1/m)
    es
  })

  output$equiva_ic_sup<-renderText({
    paste("upper extreme =",round(equiva_ic_sup(),4))
  })

  output$equiva_pval<-renderText({
    p <- max(equiva_pval1(),equiva_pval2())
    p<-format(p,digits = 4,format="e")
    paste("p-value =",p)
  }) 

  output$equiva_graf_intconf <- renderPlot({
    req(input$equiva_H0)
    validate(need(nrow(dati$DS)!=0,""))

    delta <- input$equiva_H0
    inf <- equiva_ic_inf()
    sup <- equiva_ic_sup()
    pval <- max(equiva_pval1(),equiva_pval2())
    
    plot(x=0,y=0,type="n",frame.plot = FALSE,yaxt="n",xlab="",ylab="",xlim=c(-2*delta,2*delta))
    abline(v=-delta,lty=2,col="blue")
    mtext(text =expression(-delta),at = -delta,side = 1,line = 2,col="blue")
    abline(v=delta,lty=2,col="blue")
    mtext(text =expression(-delta),at = delta,side = 1,line = 2,col="blue" )
    
    arrows(x0 = inf,y0 = 0,x1 = sup,y1 = 0,length = 0.1,angle = 90,code = 3,col = "green4")
    
    if(pval<0.05){
      txt <- "equiv."
    }else{
      txt <- "not equiv."
    }
    mtext(text =txt,at =(inf+sup)/2,side = 1,line = 2,col="green4",cex=0.8 )
  })

  output$equiva_qqplot<-renderPlot({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    Diff<-dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2]
    ggplot(dati$DS,aes(sample=Diff))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="theoretical quantiles",  y = "sample quantiles")+
      theme_classic()
  })
  
  output$equiva_shapiro<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$equiva_variab1%in%colnames(dati$DS))
    req(input$equiva_variab2%in%colnames(dati$DS))
    Differenze<-dati$DS[,input$equiva_variab1]-dati$DS[,input$equiva_variab2]
    shapiro.test(Differenze) 
  })

  # ftest -----------------------------------------------------------------
  
  output$ftest_variab1<-renderUI({
    selectizeInput(inputId = "ftest_variab1"," ",
                   choices = dati$var_qt)})
  
  output$ftest_variab2<-renderUI({
    selectizeInput(inputId = "ftest_variab2",div("Group variable",style="font-weight: 400;"),
                   choices = dati$var_ql)})
  
  output$ftest_H0_txt = renderUI({        
    HTML("H<SUB>0</SUB>: &sigma;<SUB>1</SUB> = &sigma;<SUB>2</SUB> <p> H<SUB>1</SUB>: &sigma;<SUB>1</SUB> &ne; &sigma;<SUB>1</SUB>")
    
  })
  
  output$ftest_errore<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    validate(need(length(unique(dati$DS[,input$ftest_variab2]))!=2,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    "The group variable must have 2 levels"
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
        text(0,0,"Sample size at least 2 \n",col="red",cex=2)
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
          ylab("density")+xlab(expression(frac(S[m[1]]^2,S[m[2]]^2)))+
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
    "Point estimate"
  })
  
  output$ftest_sd_camp1<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    paste("sample standard dev. gr 1=",round(sd(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[1],input$ftest_variab1]),3))
  })
  
  output$ftest_sd_camp2<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$ftest_variab1%in%colnames(dati$DS))
    req(input$ftest_variab2%in%colnames(dati$DS))
    gruppi<-unique(dati$DS[,input$ftest_variab2])
    paste("sample standard dev. gr 2=",round(sd(dati$DS[dati$DS[,input$ftest_variab2]==gruppi[2],input$ftest_variab1]),3))
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
    paste("statistic =",round(ds1^2/ds2^2,4)) 
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
    "Interval estimation"
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
    paste("lower extreme =",round((ds1^2/ds2^2)*(1/q),4))
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
    paste("upper extreme =",round((ds1^2/ds2^2)*(1/q),4))
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
      labs(x="theoretical quantiles",  y = "sample quantiles")+
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
      labs(x="theoretical quantiles",  y = "sample quantiles")+
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
    selectizeInput(inputId = "anovatest_variab2",div("Factor",style="font-weight: 400;"),
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
    ylab("density")+xlab("F")+
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
    paste("statistic =",round(F,4)) 
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
      labs(x="theoretical quantiles",  y = "sample quantiles")+
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
    selectizeInput(inputId = "anova2test_variab2",div("Factor 1",style="font-weight: 400;"),
                   choices = dati$var_ql)})
  
  output$anova2test_variab3<-renderUI({
    selectizeInput(inputId = "anova2test_variab3",div("Factor 2",style="font-weight: 400;"),
                   choices = dati$var_ql[!dati$var_ql%in%input$anova2test_variab2])})
  
  output$anova2test_h12_ipotesi<-renderUI({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))
    
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    if (max(smr)==1){
      HTML("<h4>Anova without repetitions. </h4>
              <h4>We have no dof to perform the Interaction test</h4>")
    } else {
      HTML("<h4>Hypothesis 12:</h4>
      <h4>H<SUB>0,12</SUB>: (&alpha;&beta;)<SUB>i,j</SUB> = 0 for every (i,j) <br>
              H<SUB>1,12</SUB>:(&alpha;&beta;)<SUB>i,j</SUB> &ne;0 at least a (i,j)</h4>")
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
      dof1<-s[[1]][1,1]
      dof2<-s[[1]][3,1]
    } else {
      mod<-aov(x~gr1*gr2,df)
      s<-summary(mod)
      dof1<-s[[1]][1,1]
      dof2<-s[[1]][4,1]
    }
    F<-s[[1]][1,4]
    
    x<-seq(0, 10,by = 0.1)
    df<-cbind.data.frame(x=x,y=df(x,df1 = dof1,df2 = dof2))

    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("density")+xlab("F")+
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
    F<-s[[1]][1,4]
    paste("statistic =",round(F,4)) 
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
      dof1<-s[[1]][2,1]
      dof2<-s[[1]][3,1]
    } else {
      mod<-aov(x~gr1*gr2,df)
      s<-summary(mod)
      dof1<-s[[1]][2,1]
      dof2<-s[[1]][4,1]
    }
    F<-s[[1]][2,4]
    
    x<-seq(0, 10,by = 0.1)
    df<-cbind.data.frame(x=x,y=df(x,df1 = dof1,df2 = dof2))
    
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("density")+xlab("F")+
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
    F<-s[[1]][2,4]
    paste("statistic =",round(F,4)) 
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
    
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    req(max(smr)!=1)
 
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)

    mod<-aov(x~gr1*gr2,df)
    s<-summary(mod)
    dof1<-s[[1]][3,1]
    dof2<-s[[1]][4,1]
    F<-s[[1]][3,4]
    
    x<-seq(0, 10,by = 0.1)
    df<-cbind.data.frame(x=x,y=df(x,df1 = dof1,df2 = dof2))
    
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("density")+xlab("f")+
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

    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    req(max(smr)!=1)

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
    paste("statistic =",round(F,4)) 
  }) 
  
  output$anova2test_pval12<-renderText({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$anova2test_variab1%in%colnames(dati$DS))
    req(input$anova2test_variab2%in%colnames(dati$DS))
    req(input$anova2test_variab3%in%colnames(dati$DS))

    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    req(max(smr)!=1)
    
    df<-cbind.data.frame(x=dati$DS[,input$anova2test_variab1],gr1=dati$DS[,input$anova2test_variab2],
                         gr2=dati$DS[,input$anova2test_variab3])
    df$gr1<-as.factor(df$gr1)
    df$gr2<-as.factor(df$gr2)
    int<-interaction(dati$DS[,input$anova2test_variab2],dati$DS[,input$anova2test_variab3])
    smr<-summary(int)
    mod<-aov(x~gr1*gr2,df)
    s<-summary(mod)
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
      labs(x="theoretical quantiles",  y = "sample quantiles")+
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
     cat("Anova without repetitions. \n")
     cat("We have no dof to perform the test.")
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
      cat("Anova without repetitions. \n")
      cat("We have no dof to perform the test.")
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
      cat("Anova without repetitions. \n")
      cat("We have no dof to perform the test.")
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
      cat("Anova without repetitions. \n")
      cat("We have no dof to perform the test.")
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
      cat("Anova without repetitions. \n")
      cat("We have no dof to perform the test.")
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
    selectizeInput(inputId = "anova3test_variab2",div("Factor 1",style="font-weight: 400;"),
                   choices = dati$var_ql)})
  
  output$anova3test_variab3<-renderUI({
    selectizeInput(inputId = "anova3test_variab3",div("Factor 2",style="font-weight: 400;"),
                   choices = dati$var_ql[!dati$var_ql%in%input$anova3test_variab2])})
  
  output$anova3test_variab4<-renderUI({
    selectizeInput(inputId = "anova3test_variab4",div("Factor 3",style="font-weight: 400;"),
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

# Calcolatore potenza-----------------------------------------------------------------
  
 ## T-test: una popolazione-----------------------------------------------------------------

  output$calc_potenza_t1_diff_medie <- renderUI({
    validate(need(input$calc_potenza_test=='T-test: one population',""))
    numericInput("calc_potenza_t1_diff_medie",label = "Difference from the real mean",
                 value=0.5,width = "40%")})
  
  output$calc_potenza_t1_devst <- renderUI({
    validate(need(input$calc_potenza_test=='T-test: one population',""))
    numericInput("calc_potenza_t1_devst",label = "Standard dev.",
                 value=1,width = "40%")})
  
  output$calc_potenza_t1_effetto <- renderUI({
    validate(need(input$calc_potenza_test=='T-test: one population',""))
    HTML('Effect size d/<span>&#963;</span> =',round(input$calc_potenza_t1_diff_medie/input$calc_potenza_t1_devst,2))
    })

  ## T-test: due popolazioni----------------------------------------------------------------- 
  
  output$calc_potenza_t2_var_uguali <- renderUI({
    validate(need(input$calc_potenza_test=='T-test: two populations',""))
    radioButtons("calc_potenza_t2_var_uguali", label = "",
                 choices = list("Equal variances" = 1, "Unequal variances" = 2),
                 selected = 1)
    })

    output$calc_potenza_t2_diff_medie <- renderUI({
      validate(need(input$calc_potenza_test=='T-test: two populations',""))
      numericInput("calc_potenza_t2_diff_medie",label = "Difference from the real mean",
                   value=0.5,width = "40%")})
    
    output$calc_potenza_t2_devst <- renderUI({
      validate(need(input$calc_potenza_test=='T-test: two populations',""))
      validate(need(input$calc_potenza_t2_var_uguali==1,""))
      numericInput("calc_potenza_t2_devst",label = "Standard dev.",
                   value=1,width = "40%")})
    
    output$calc_potenza_t2_effetto1 <- renderUI({
      validate(need(input$calc_potenza_test=='T-test: two populations',""))
      validate(need(input$calc_potenza_t2_var_uguali==1,""))
      HTML('Effect size d/<span>&#963;</span> =',round(input$calc_potenza_t2_diff_medie/input$calc_potenza_t2_devst,2))
    })
    
    output$calc_potenza_t2_devst1 <- renderUI({
      validate(need(input$calc_potenza_test=='T-test: two populations',""))
      validate(need(input$calc_potenza_t2_var_uguali==2,""))
      numericInput("calc_potenza_t2_devst1",label = "Standard dev. gr. 1",
                   value=1,width = "45%")})
    
    output$calc_potenza_t2_devst2 <- renderUI({
      validate(need(input$calc_potenza_test=='T-test: two populations',""))
      validate(need(input$calc_potenza_t2_var_uguali==2,""))
      numericInput("calc_potenza_t2_devst2",label = "Standard dev. gr. 2",
                   value=1,width = "45%")})
    
    output$calc_potenza_t2_effetto2 <- renderUI({
      validate(need(input$calc_potenza_test=='T-test: two populations',""))
      validate(need(input$calc_potenza_t2_var_uguali==2,""))
      HTML('Effect size <sup>d</sup>&frasl;<sub><span>&#8730;(<span>&#963;</span><sub>1</sub><sup>2</sup>+<span>&#963;</span><sub>2</sub><sup>2</sup>)/2
      </span></sub> =',
           round(input$calc_potenza_t2_diff_medie/sqrt((input$calc_potenza_t2_devst1^2+input$calc_potenza_t2_devst2^2)/2),2))
    })

    ## F-test: test varianza ----------------------------------------------------------------- 

    output$calc_potenza_f_devst1 <- renderUI({
      validate(need(input$calc_potenza_test=='F-test: variance test',""))
      numericInput("calc_potenza_f_devst1",label = "Standard dev. gr. 1",
                   value=1.15,width = "45%")})
    
    output$calc_potenza_f_devst2 <- renderUI({
      validate(need(input$calc_potenza_test=='F-test: variance test',""))
      numericInput("calc_potenza_f_devst2",label = "Standard dev. gr. 2",
                   value=1,width = "45%")})
    
    output$calc_potenza_f_effetto <- renderUI({
      validate(need(input$calc_potenza_test=='F-test: variance test',""))
      HTML('Effect size   <span>&#963;</span><sub>1</sub> &frasl;   <span>&#963;</span><sub>2</sub>  =',
      round(input$calc_potenza_f_devst1/input$calc_potenza_f_devst2,2)
      )
    })

    ## Anova: una via -----------------------------------------------------------------
  
    output$calc_potenza_aov1_ngruppi <- renderUI({
      validate(need(input$calc_potenza_test=='Anova: one way',""))
      numericInput("calc_potenza_aov1_ngruppi",label = "Number of groups",
                   value=4,width = "40%")})
    
    output$calc_potenza_aov1_diff_medie <- renderUI({
      validate(need(input$calc_potenza_test=='Anova: one way',""))
      numericInput("calc_potenza_aov1_diff_medie",label = HTML("Treatment eff. &#8721;&alpha;<sub>j</sub><sup>2</sup>"),
                   value=input$calc_potenza_aov1_ngruppi/16,width = "45%")})
    
    output$calc_potenza_aov1_devst <- renderUI({
      validate(need(input$calc_potenza_test=='Anova: one way',""))
      numericInput("calc_potenza_aov1_devst",label = "Standard dev.",
                   value=1,width = "40%")})
    
    output$calc_potenza_aov1_effetto <- renderUI({
      validate(need(input$calc_potenza_test=='Anova: one way',""))
      # HTML('Grandezza effetto &#963; =') ###
      HTML('Effect size <span class="frac"> &#8730; <sup>&#8721;&alpha;<sub>j</sub><sup>2</sup>/k </sup> <span>/</span> <sub>&#963</sub> </span> = ',
           round(sqrt(input$calc_potenza_aov1_diff_medie/input$calc_potenza_aov1_ngruppi)/input$calc_potenza_aov1_devst,2))
    })

  ## Grafico ----------------------------------------------------------------- 
   
    output$calc_potenza_graf <- renderGirafe({
      if(input$calc_potenza_test=='T-test: one population'){
        
        req(input$calc_potenza_alfa)
        req(input$calc_potenza_t1_diff_medie)
        req(input$calc_potenza_t1_devst)
        
        alfa=input$calc_potenza_alfa
        d=input$calc_potenza_t1_diff_medie
        sd=input$calc_potenza_t1_devst
        
        n=0
        PT <- as.data.frame(NULL)
        while(n<=99){
          n=n+1
          txt <- power.t.test(n = n,delta = d,sd = sd,sig.level = alfa,power = NULL,
                              alternative = 'two.sided',type = 'one.sample',strict = TRUE)
          p <- txt$power
          PT[n,1] <- n
          PT[n,2] <- p
          if(p>=1)break
        }
        colnames(PT) <- c('n','pt')
        
        subtitolo <- paste("T-test one population: effect size =", round(d/sd,2))
        xtxt <- "sample size"
      }
      
      if(input$calc_potenza_test=='T-test: two populations'){
        req(input$calc_potenza_t2_var_uguali)
        
        if(input$calc_potenza_t2_var_uguali==1){
          req(input$calc_potenza_alfa)
          req(input$calc_potenza_t2_diff_medie)
          req(input$calc_potenza_t2_devst)
          
          alfa=input$calc_potenza_alfa
          d=input$calc_potenza_t2_diff_medie
          sd=input$calc_potenza_t2_devst
          
          n=1
          PT <- as.data.frame(NULL)
          while(n<=99){
            n=n+1
            txt <- power_t_test(n=n,ratio=1,delta=d,sd=sd, sd.ratio=1, 
                                type = "two.sample",alternative = "two.sided",strict = TRUE, df.method="classical")
            
            p <- txt$power
            PT[n,1] <- n
            PT[n,2] <- p
            if(p>=1)break
          }
          
          colnames(PT) <- c('n','pt')
          PT <- PT[-1,]
          
          subtitolo <- paste("T-test two populations equal variances: effect size =", round(d/sd,2))
          xtxt <- "sample size for each group"
        }
        
        if(input$calc_potenza_t2_var_uguali==2){
          req(input$calc_potenza_alfa)
          req(input$calc_potenza_t2_diff_medie)
          req(input$calc_potenza_t2_devst1)
          req(input$calc_potenza_t2_devst2)
          
          alfa=input$calc_potenza_alfa
          d=input$calc_potenza_t2_diff_medie
          sd1=input$calc_potenza_t2_devst1
          sd2=input$calc_potenza_t2_devst2
          
          n=1
          PT <- as.data.frame(NULL)
          while(n<=99){
            n=n+1
            txt <- power_t_test(n=n,ratio=1, delta=d, sd=sd1,  sd.ratio=sd2/sd1, 
                                type = "two.sample",alternative = "two.sided",strict = TRUE,df.method="welch")
            p <- txt$power
            PT[n,1] <- n
            PT[n,2] <- p
            if(p>=1)break
          }
          
          colnames(PT) <- c('n','pt')
          PT <- PT[-1,]
          
          subtitolo <- paste("T-test two populations unequal variances: effect size =", 
                             round(input$calc_potenza_t2_diff_medie/sqrt((input$calc_potenza_t2_devst1^2+input$calc_potenza_t2_devst2^2)/2),2))
          xtxt <- "sample size for each group"
        }
      }

      if(input$calc_potenza_test=='F-test: variance test'){
        req(input$calc_potenza_alfa)
        req(input$calc_potenza_f_devst1)
        req(input$calc_potenza_f_devst2)
        
        alfa=input$calc_potenza_alfa
        sd1=input$calc_potenza_f_devst1
        sd2=input$calc_potenza_f_devst2
        lambda=sd1/sd2
        
        n=1
        PT <- as.data.frame(NULL)
        while(n<=99){
          n=n+1
          f1<-qf(p = alfa/2,df1 = n-1,df2 = n-1,lower.tail = TRUE)
          f2<-qf(p = alfa/2,df1 = n-1,df2 = n-1,lower.tail = FALSE)
          p <- pf(q = f1/lambda^2,df1 = n-1,df2 = n-1,lower.tail = TRUE)+
            pf(q = f2/lambda^2,df1 = n-1,df2 = n-1,lower.tail = FALSE)
          PT[n,1] <- n
          PT[n,2] <- p
          if(p>=1)break
        }
        
        colnames(PT) <- c('n','pt')
        PT <- PT[-1,]
        
        subtitolo <- paste("F-test: variance test: effect size =", 
                           round(input$calc_potenza_f_devst1/input$calc_potenza_f_devst2,2))
        xtxt <- "sample size for each group"
      }

      if(input$calc_potenza_test=='Anova: one way'){
        req(input$calc_potenza_alfa)
        req(input$calc_potenza_aov1_ngruppi)
        req(input$calc_potenza_aov1_diff_medie)
        req(input$calc_potenza_aov1_devst)
        
        alfa=input$calc_potenza_alfa
        k <- input$calc_potenza_aov1_ngruppi
        d=input$calc_potenza_t1_diff_medie
        sd=input$calc_potenza_t1_devst
        f <- sqrt(input$calc_potenza_aov1_diff_medie/input$calc_potenza_aov1_ngruppi)/input$calc_potenza_aov1_devst
        
        n=1
        PT <- as.data.frame(NULL)
        while(n<=99){
          n=n+1
          txt <- pwr.anova.test(k = k,n = n,f = f,sig.level = alfa)
          p <- txt$power
          PT[n,1] <- n
          PT[n,2] <- p
          if(p>=1)break
        }
        colnames(PT) <- c('n','pt')
        
        subtitolo <- paste("One way anova: effect size =", 
                           round(sqrt(input$calc_potenza_aov1_diff_medie/input$calc_potenza_aov1_ngruppi)/input$calc_potenza_aov1_devst,2))
        xtxt <- "sample size for each group"
      }

      tooltip_text = paste0('n: ',PT$n, "\n",
                            'power: ',round(PT$pt*100,2), "%")
      
      latest_vax_graph <- ggplot(PT,
                                 aes(x = n,
                                     y = pt,
                                     tooltip = tooltip_text, data_id = n #<<
                                 )) +
        geom_col_interactive(color = "chartreuse4", fill="chartreuse4", size = 0.5) +  #<<
        theme_minimal() +
        theme(axis.text=element_text(size = 6)) +  #<<
        labs(title = "Power as function of sample size",
             subtitle = subtitolo) +
        ylab("power") +
        xlab(xtxt) +
        ylim(c(0,1))

      girafe(ggobj = latest_vax_graph,
             options = list(opts_tooltip(css = "background-color:orange;color:black;
                                   padding:2px;border-radius:2px;
                                   font-style:bold;"),
                            opts_selection(type = "single"),
                            opts_sizing(width = 1) ))
    })

# Regressione semplice-----------------------------------------------------------------
  output$regrsemplice_variaby<-renderUI({
    selectizeInput(inputId = "regrsemplice_variaby",div("Dependent variable (y)",style="font-weight: 400;"),
                   choices = dati$var_qt)})
  
  output$regrsemplice_variabx<-renderUI({
    selectizeInput(inputId = "regrsemplice_variabx",div("Independent variable (x)",style="font-weight: 400;"),
                   choices = dati$var_qt[!dati$var_qt%in%input$regrsemplice_variaby])})  
  
  output$regrsemplice_graf<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c("x","y")

    frm <- 'y~x'
    if(!input$regrsemplice_intercetta)frm <- paste(frm,'-1')
    
    require(ggplot2)
    ggplot(data = df,aes(x=x,y=y))+xlab(input$regrsemplice_variabx)+ylab(input$regrsemplice_variaby)+
      geom_point()+theme_light()+
      stat_smooth(method = "lm", col = "red",formula = formula(frm),level=1-input$regrsemplice_alfa)
  })
  
  output$regrsemplice_parpt<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    mod<-lm(frm,df)
    mod$coefficients
  })
  
  output$regrsemplice_parint<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    mod<-lm(frm,df)
    confint(object = mod,level = 1-input$regrsemplice_alfa)
  })
  
  output$regrsemplice_prev<-renderPrint({
    validate(need(nrow(dati$DS)!=0 & input$regrsemplice_prevx!="",""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    mod<-lm(frm,df)
    nd<-cbind.data.frame(x=input$regrsemplice_prevx)
    colnames(nd)<-input$regrsemplice_variabx
    X <- predict(object = mod,newdata=nd,interval="confidence",level=1-input$regrsemplice_alfa)
    rownames(X) <- ''
    X
  })

  output$regrsemplice_prev_inv<-renderPrint({
    validate(need(nrow(dati$DS)!=0 & input$regrsemplice_prevy!="",""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    mod<-lm(frm,df)
    
    b0 <- mod$coefficients[1]
    b1 <- mod$coefficients[2]
    if(!input$regrsemplice_intercetta)b0=0
    if(!input$regrsemplice_intercetta)b1 <- mod$coefficients[1]
    
    req(b1!=0)
    x <- (input$regrsemplice_prevy-b0)/b1
    nd<-cbind.data.frame(x)
    colnames(nd)<-input$regrsemplice_variabx
    pred_M <- predict(object = mod,newdata=nd,interval="prediction",level=1-input$regrsemplice_alfa)
    x_upr<-(pred_M[3]-b0)/b1
    semi.amp <- abs(x_upr-x)
    X <- cbind.data.frame(fit=x,lwr=x-semi.amp,upr=x+semi.amp)
    rownames(X) <- ''
    X
  })

  output$regrsemplice_summary<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    mod<-lm(frm,df)
    summary(mod)
  })
  
  output$regrsemplice_verifhp_ttest<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    mod<-lm(frm,df)
    t.test(mod$residuals)
  })
  
  output$regrsemplice_verifhp_grlin<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    mod<-lm(frm,df)
    df_xy<-cbind.data.frame(x=mod$fitted.values,y=mod$residuals)
    ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
      geom_hline(yintercept = 0,col="blue",lty=2)+
      ylab("residuals")+xlab("fitted values")
  })
  
  output$regrsemplice_verifhp_shapiro<-renderPrint({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
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
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    mod<-lm(frm,df)
    df_res<-cbind.data.frame(residui=mod$residuals)
    ggplot(df_res,aes(sample=residui))+
      stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
      labs(x="theoretical quantiles",  y = "sample quantiles")+
      theme_classic()
  })
  
  output$regrsemplice_verifhp_bp<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    modello<-lm(frm,df)
    lmtest::bptest(modello)
  })

  output$regrsemplice_verifhp_omosch<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    mod<-lm(frm,df)
    df_xy<-cbind.data.frame(x=mod$fitted.values,y=sqrt(abs(mod$residuals)))
    ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
      geom_hline(yintercept = 0,col="blue",lty=2)+
      ylab(expression(sqrt(residuals)))+xlab("fitted values")
  })
  
  output$regrsemplice_verifhp_dw<-renderPrint({
    require(ggplot2)
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    modello<-lm(frm,df)
    lmtest::dwtest(modello)
  })
  
  output$regrsemplice_verifhp_corr<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrsemplice_variaby%in%colnames(dati$DS))
    req(input$regrsemplice_variabx%in%colnames(dati$DS))
    df<-cbind.data.frame(x=dati$DS[,input$regrsemplice_variabx],y=dati$DS[,input$regrsemplice_variaby])
    colnames(df)<-c(input$regrsemplice_variabx,input$regrsemplice_variaby)
    frm <- paste(input$regrsemplice_variaby,"~",input$regrsemplice_variabx,sep="")
    if(!input$regrsemplice_intercetta)frm <- paste(frm, '- 1')
    frm <- formula(frm)
    mod<-lm(frm,df)
    n<-length(mod$residuals)
    df_xy<-cbind.data.frame(x=mod$residuals[-n],y=mod$residuals[-1])
    ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
      geom_hline(yintercept = 0,col="blue",lty=2)+
      ylab(expression(residuals[n]))+xlab(expression(residuals[n-1]))
  })

  # Regressione polinomiale-----------------------------------------------------------------
  output$regrpoli_variaby<-renderUI({
    selectizeInput(inputId = "regrpoli_variaby",div("Dependent variable (y)",style="font-weight: 400;"),
                   choices = dati$var_qt)})
  
  output$regrpoli_variabx<-renderUI({
    selectizeInput(inputId = "regrpoli_variabx",div("Independent variable (x)",style="font-weight: 400;"),
                   choices = dati$var_qt[!dati$var_qt%in%input$regrpoli_variaby])})  
  
  output$regrpoli_graf<-renderPlot({
    validate(need(nrow(dati$DS)!=0,""))
    req(input$regrpoli_variaby%in%colnames(dati$DS))
    req(input$regrpoli_variabx%in%colnames(dati$DS))
    req(input$regrpoli_grado)
    df<-cbind.data.frame(x=dati$DS[,input$regrpoli_variabx],y=dati$DS[,input$regrpoli_variaby])
    colnames(df)<-c("x","y")
 
    require(ggplot2)
    ggplot(data = df,aes(x=x,y=y))+xlab(input$regrpoli_variabx)+ylab(input$regrpoli_variaby)+
      geom_point()+theme_light()+
      stat_smooth(method = "lm", col = "red",formula = y~poly(x,input$regrpoli_grado),level=1-input$regrpoli_alfa)
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
    confint(object = mod,,level=1-input$regrpoli_alfa)
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
    predict(object = mod,newdata=nd,interval="confidence",level=1-input$regrpoli_alfa)
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
      ylab("rsidals")+xlab("fitted values")
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
      labs(x="theoretical quantiles",  y = "sample quantiles")+
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
      ylab(expression(sqrt(residuals)))+xlab("fited values")
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
      ylab(expression(residals[n]))+xlab(expression(residuals[n-1]))
  }) 

# Regressione multipla-----------------------------------------------------------------
output$regrmulti_variaby<-renderUI({
  selectizeInput(inputId = "regrmulti_variaby",div("Dependent variable (y)",style="font-weight: 400;"),
                 choices = dati$var_qt)})

output$regrmulti_variabx<-renderUI({
  selectizeInput(inputId = "regrmulti_variabx",div("Independent variables (x)",style="font-weight: 400;"),
                 choices = dati$var_qt[!dati$var_qt%in%input$regrmulti_variaby],
                 multiple = TRUE)})  

output$regrmulti_inter_ord<-renderUI({
  validate(need(input$regrmulti_addi=="2",''))
  validate(need(length(input$regrmulti_variabx)>=2,''))
  numericInput("regrmulti_inter_ord", label = h5("Interaction order"), value = 2,min = 2,width = "70px")
})

# costruzione vettore delle variabili usate nel modello
regrmulti_formula_var <- reactive({
  vars <- input$regrmulti_variabx
  formula_terms <- vars
  if(input$regrmulti_addi==2){
    req(input$regrmulti_inter_ord)
    req(input$regrmulti_inter_ord<=length(vars))
    n <- input$regrmulti_inter_ord
    interactions <- list()
    for(order in 1:n) {
      combs <- combn(vars, order, simplify = FALSE)
      for(comb in combs) {
        interactions[[length(interactions) + 1]] <- comb
      }
    }
    formula_terms <- c(formula_terms,sapply(interactions,function(x) {paste(x, collapse = ":")}))
  }
  if(input$regrmulti_include_squared) {
    quadr <- c(NULL)
    quadr <-paste0('I(',vars,'^2)')
    formula_terms <- c(formula_terms,quadr)
  }
  return(formula_terms)
})

output$regrmulti_variab_mod<-renderUI({
    selectizeInput(inputId = "regrmulti_variab_mod",label=h5("Model terms (x)"),
                   choices = regrmulti_formula_var(),
                   selected = regrmulti_formula_var(),
                   multiple=TRUE)
})

# Costruzione della formula del modello
regrmulti_formula_text <- reactive({
  req(input$regrmulti_variab_mod)
  # req(length(input$regrmulti_variabx)>=2)
  formula_terms <- input$regrmulti_variab_mod
  frm <- paste(input$regrmulti_variaby,"~",paste(formula_terms, collapse = " + "))
  if(!input$regrmulti_intercetta)frm <- paste(frm, '- 1')
  frm <- formula(frm)
  return(frm)
})

regrmulti_model <- reactive({
  req(dati$DS, regrmulti_formula_text())
  frm <- formula(regrmulti_formula_text())
  req(input$regrmulti_variabx,input$regrmulti_variaby)
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  X<-model.matrix(frm,df)
  validate(need(qr(X)$rank==ncol(X),"The program was aborted because the model matrix has insufficient rank"))
  mod<-lm(frm,df)
  return(mod)
})

output$regrmulti_graf<-renderPlot({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  require(ggplot2)
  df_coeff<-data.frame(names(mod$coefficients),mod$coefficients,confint(mod,level=1-input$regrmulti_alfa))
  if(!input$regrmulti_include_interc_plot)df_coeff <- df_coeff[-1,]
  ggplot(data = df_coeff,aes(x =df_coeff$names.mod.coefficients.,
                             y=df_coeff$mod.coefficients))+
    xlab("")+ylab("")+theme_light()+
    geom_bar(fill="red",stat="identity")+
    geom_errorbar(aes(ymin=df_coeff[,3], ymax=df_coeff[,4]),
                  width=0.2, colour="green3")+
    scale_x_discrete(limits=df_coeff$names.mod.coefficients.)+
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
})

output$regrmulti_parpt<-renderPrint({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  round(mod$coefficients,input$regrmulti_ddigits)
})

output$regrmulti_parint<-renderPrint({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  round(confint(object = mod,level=1-input$regrmulti_alfa),input$regrmulti_ddigits)
})

output$regrmulti_prev<-renderPrint({
  validate(need(nrow(dati$DS)!=0 & length(as.numeric(unlist(strsplit(input$regrmulti_prevx," "))))==length(input$regrmulti_variabx),""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  x<- as.numeric(unlist(strsplit(input$regrmulti_prevx," ")))
  nd<-rbind.data.frame(x)
  colnames(nd)<-input$regrmulti_variabx
  round(predict(object = mod,newdata=nd,interval="confidence",level=1-input$regrmulti_alfa),input$regrmulti_ddigits)
})

output$regrmulti_summary<-renderPrint({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  summary(mod,cor=TRUE)
})

output$regrmulti_vif<-renderPrint({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  req(model.matrix(regrmulti_model()))
  mod <- regrmulti_model()
  M <- model.matrix(mod)
  M = as.data.frame(M)
  if (colnames(M)[1] == "(Intercept)")M = M[, -1]
  
  req(ncol(M)>1)
  z = rep(NA, ncol(M))
  names(z) = colnames(M)
  for (i in 1:ncol(M)) {
    z[i] = 1/(1 - summary(lm(M[, i] ~ ., data = M[, -i,drop=FALSE]))$r.squared)
  }
  return(round(z,2))
})

output$regrmulti_selvar<-renderUI({
  validate(need(length(input$regrmulti_variabx)>2,''))
  var <- input$regrmulti_variabx
  selectInput("regrmulti_selvar", label = h4("Select 2 variables"),
              choices = var,
              multiple = TRUE,selected = var[1:2])
})

output$regrmulti_fixed_values_ui <- renderUI({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variabx,input$regrmulti_selvar)
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  
  # Ottieni le variabili non nel grafico
  other_vars <- setdiff(input$regrmulti_variabx, input$regrmulti_selvar)
  if(length(other_vars) == 0) return(NULL)
  tagList(
    h4("Fixed values for the other variables:"),
    lapply(other_vars, function(var) {
      var_values <- dati$DS[[var]]
      mean_val <- mean(var_values)
      min_val <- min(var_values)
      max_val <- max(var_values)
      
      div(
        style = "margin-bottom: 15px;",
        numericInput(
          inputId = paste0("fixed_", var),
          label = h5(var),
          value = mean_val,
          min = min_val,
          max = max_val
        ),
        actionButton(
          inputId = paste0("reset_", var),
          label = "Reset mean value",
          class = "btn-sm"
        )
      )
    })
  )
})

# Observer per i pulsanti di reset
observe({
  req(nrow(dati$DS)!=0, input$regrmulti_variabx)
  other_vars <- setdiff(input$regrmulti_variabx, input$regrmulti_selvar)
  
  lapply(other_vars, function(var) {
    observeEvent(input[[paste0("reset_", var)]], {
      mean_val <- mean(dati$DS[[var]])
      updateNumericInput(session, 
                         paste0("fixed_", var), 
                         value = mean_val)
    })
  })
})

# Grafico della superficie di risposta

output$regrmulti_surface_plot <- renderPlotly({
  validate(need(nrow(dati$DS)!=0,""))
  req(length(input$regrmulti_variabx)>=2)
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  mod <- regrmulti_model()
  if(length(input$regrmulti_variabx)==2){
    x1_plot <- input$regrmulti_variabx[1]
    x2_plot <- input$regrmulti_variabx[2]
  }
  if(length(input$regrmulti_variabx)>2){
    x1_plot <- input$regrmulti_selvar[1]
    x2_plot <- input$regrmulti_selvar[2]
  }
  # Creo griglia di predizione per le due variabili selezionate
  req(!is.null(x1_plot))
  x1_seq <- seq(min(df[[x1_plot]]), max(df[[x1_plot]]),
                length.out = input$regrmulti_resolution)
  x2_seq <- seq(min(df[[x2_plot]]), max(df[[x2_plot]]),
                length.out = input$regrmulti_resolution)
  # Creo il grid completo con i valori fissati dall'utente per le altre variabili
  grid_base <- list()
  other_vars <- setdiff(input$regrmulti_variabx, input$regrmulti_selvar)
  for(var in other_vars) {
    fixed_value <- input[[paste0("fixed_", var)]]
    grid_base[[var]] <- fixed_value
  }
  # Aggiungo le variabili del plot
  grid <- expand.grid(
    data.frame(
      setNames(list(x1_seq), x1_plot),
      setNames(list(x2_seq), x2_plot))
  )
  # Combino con i valori base
  for(var in names(grid_base)) {
    grid[[var]] <- grid_base[[var]]
  }
  # Calcolo predizioni
  req(length(colnames(grid))==length(input$regrmulti_variabx))

  z_matrix <- matrix(predict(mod, newdata = grid),
                     nrow = input$regrmulti_resolution, ncol = input$regrmulti_resolution)

  # Creo il plot 3D
  plot_ly() %>%
    add_surface(x = x1_seq, y = x2_seq, z = t(z_matrix),
                colorscale = "Viridis",
                colorbar = list(
                  # len = 0.5,        # Length of the colorbar
                  y = 0.75         # Center position (0.5 = middle)
                  # thickness = 15    # Width of the colorbar
                ),
                reversescale=T) %>%
    add_markers(data = df, 
                x = as.formula(paste0("~", x1_plot)),
                y = as.formula(paste0("~", x2_plot)),
                z = as.formula(paste0("~", input$regrmulti_variaby)),
                marker = list(size = 3, color = "red", symbol = "circle")) %>%
    layout(scene = list(
      xaxis = list(title = x1_plot, autorange="reversed"),
      yaxis = list(title = x2_plot, autorange="reversed"),
      zaxis = list(title = input$regrmulti_variaby)
    ))
})

output$regrmulti_livellorisp_col<-renderUI({
  validate(need(nrow(dati$DS)!=0,""))
  req(length(input$regrmulti_variabx)>=2)
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  selectInput("regrmulti_livellorisp_col", label = h3(""), 
              choices = list("blu" = 1, "green" = 2, "red" = 3,"black" = 4,"purple" = 5), 
              selected = 1,width="130px")
})

# # Grafico delle linee di livello
output$regrmulti_contour_plot <- renderPlotly({
  validate(need(nrow(dati$DS)!=0,""))
  req(length(input$regrmulti_variabx)>=2)
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  df<-cbind.data.frame(x=dati$DS[,input$regrmulti_variabx],y=dati$DS[,input$regrmulti_variaby])
  colnames(df)<-c(input$regrmulti_variabx,input$regrmulti_variaby)
  mod <- regrmulti_model()
  if(length(input$regrmulti_variabx)==2){
    x1_plot <- input$regrmulti_variabx[1]
    x2_plot <- input$regrmulti_variabx[2]
  }
  if(length(input$regrmulti_variabx)>2){
    x1_plot <- input$regrmulti_selvar[1]
    x2_plot <- input$regrmulti_selvar[2]
  }
  # Creo griglia di predizione per le due variabili selezionate
  req(!is.null(x1_plot))
  x1_seq <- seq(min(df[[x1_plot]]), max(df[[x1_plot]]), 
                length.out = input$regrmulti_resolution)
  x2_seq <- seq(min(df[[x2_plot]]), max(df[[x2_plot]]), 
                length.out = input$regrmulti_resolution)
  # Creo il grid completo con i valori fissati dall'utente per le altre variabili
  grid_base <- list()
  other_vars <- setdiff(input$regrmulti_variabx, input$regrmulti_selvar)
  for(var in other_vars) {
    fixed_value <- input[[paste0("fixed_", var)]]
    grid_base[[var]] <- fixed_value
  }
  # Aggiungo le variabili del plot
  grid <- expand.grid(
    data.frame(
      setNames(list(x1_seq), x1_plot),
      setNames(list(x2_seq), x2_plot))
  )
  # Combino con i valori base
  for(var in names(grid_base)) {
    grid[[var]] <- grid_base[[var]]
  }
  # Calcolo predizioni
  req(length(colnames(grid))==length(input$regrmulti_variabx))
  
  z_matrix <- matrix(predict(mod, newdata = grid),
                     nrow = input$regrmulti_resolution, ncol = input$regrmulti_resolution)

  colore<-c("blue","green","red","black","purple1")
  cl<-as.integer(input$regrmulti_livellorisp_col)
  
  plot_ly() %>%
    add_contour(x = x1_seq, y = x2_seq, z = t(z_matrix),
                contours = list(
                  showfill = FALSE,  # Rimuove il riempimento colorato
                  coloring = 'none', # This ensures no coloring between lines
                  showlabels = TRUE,  # Mostra le etichette dei valori
                  labelfont = list(size = input$regrmulti_labelsize)
                  # start = 0,
                  # end = 200,
                  # size = input$regrmulti_size  # Imposta la distanza tra le linee
                ),
                line = list(color = colore[cl])
                )%>%
    layout(
      # title = "Contour Plot with Labeled Axes",
      xaxis = list(title = x1_plot,showgrid = FALSE,zeroline = FALSE),
      yaxis = list(title = x2_plot,showgrid = FALSE,zeroline = FALSE)
    )
})

output$regrmulti_verifhp_ttest<-renderPrint({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  t.test(mod$residuals)
})

output$regrmulti_verifhp_grlin<-renderPlot({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  df_xy<-cbind.data.frame(x=mod$fitted.values,y=mod$residuals)
  ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
    geom_hline(yintercept = 0,col="blue",lty=2)+
    ylab("residuals")+xlab("fited values")
})

output$regrmulti_verifhp_shapiro<-renderPrint({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))

  mod <- regrmulti_model()
  residui=mod$residuals
  shapiro.test(x = residui) 
})

output$regrmulti_verifhp_qqplot<-renderPlot({
  require(ggplot2)
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  df_res<-cbind.data.frame(residui=mod$residuals)
  ggplot(df_res,aes(sample=residui))+
    stat_qq(cex=2,col="blue")+stat_qq_line(col="blue",lty=2)+
    labs(x="theoretical quantiles",  y = "sample quantiles")+
    theme_classic()
})

output$regrmulti_verifhp_bp<-renderPrint({
  require(ggplot2)
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  lmtest::bptest(mod)
})

output$regrmulti_verifhp_omosch<-renderPlot({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  df_xy<-cbind.data.frame(x=mod$fitted.values,y=sqrt(abs(mod$residuals)))
  ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
    geom_hline(yintercept = 0,col="blue",lty=2)+
    ylab(expression(sqrt(residuals)))+xlab("fitted values")
})

output$regrmulti_verifhp_dw<-renderPrint({
  require(ggplot2)
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  lmtest::dwtest(mod)
})

output$regrmulti_verifhp_corr<-renderPlot({
  validate(need(nrow(dati$DS)!=0,""))
  req(input$regrmulti_variaby%in%colnames(dati$DS))
  req(input$regrmulti_variabx%in%colnames(dati$DS))
  mod <- regrmulti_model()
  n<-length(mod$residuals)
  df_xy<-cbind.data.frame(x=mod$residuals[-1],y=mod$residuals[-n])
  ggplot(df_xy,aes(x=x,y=y))+theme_classic()+geom_point(cex=2,col="blue")+
    geom_hline(yintercept = 0,col="blue",lty=2)+
    ylab(expression(rsiduals[n]))+xlab(expression(residuals[n-1]))
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
    checkboxInput("graf_norm_camp", label = "Sample", value = FALSE)
  })
  
  output$graf_norm_camp_num<-renderUI({
    validate(need(input$graf_norm_camp==TRUE,""))
    sliderInput(inputId="graf_norm_camp_num",label = "Sample size",min = 1,max = 10000,value = 10,
                step=10)
  })
  
  output$graf_normale<-renderPlot({
    require(ggplot2)
    x<-seq(-10, 10,by = 0.1)
    df<-cbind.data.frame(x=x,y=dnorm(x,mean=input$graf_norm_media,sd=input$graf_norm_ds))
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("density")+xlab("Y")
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
        text(0,0,"Error: b must be greater than a",col="red",cex=2)
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
        text(0,0,"Error: b must be greater than a",col="red",cex=2)
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
      "P[x<a and x>b]"
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
    checkboxInput("graf_tstudent_camp", label = "Sample", value = FALSE)
  })
  
  output$graf_tstudent_camp_num<-renderUI({
    validate(need(input$graf_tstudent_camp==TRUE,""))
    sliderInput(inputId="graf_tstudent_camp_num",label = "Sample size",min = 1,max = 10000,value = 10,
                step=10)
  })
  
  output$graf_tstudent<-renderPlot({
    require(ggplot2)
    x<-seq(-10, 10,by = 0.1)
    df<-cbind.data.frame(x=x,y=dt(x,df = input$graf_tstudent_dof))
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("density")+xlab("T")
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
        text(0,0,"Error: b must be greater than a",col="red",cex=2)
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
        text(0,0,"Error: b must be greater than a",col="red",cex=2)
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
      "P[T<a]"
    } else if (input$graf_tstudent_area=="upper" & !is.null(input$graf_tstudent_a)){
      "P[T>a]"
    } else if (input$graf_tstudent_area=="both" & !is.null(input$graf_tstudent_a) & !is.null(input$graf_tstudent_b)){
      "P[T<a and T>b]"
    } else if (input$graf_tstudent_area=="middle" & !is.null(input$graf_tstudent_a) & !is.null(input$graf_tstudent_b)){
      "P[a<T<b]"
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
    checkboxInput("graf_chi_camp", label = "Sample", value = FALSE)
  })
  
  output$graf_chi_camp_num<-renderUI({
    validate(need(input$graf_chi_camp==TRUE,""))
    sliderInput(inputId="graf_chi_camp_num",label = "Sample size",min = 1,max = 10000,value = 10,
                step=10)
  })
  
  output$graf_chi<-renderPlot({
    require(ggplot2)
    x<-seq(0, 20,by = 0.1)
    df<-cbind.data.frame(x=x,y=dchisq(x,df = input$graf_chi_dof))
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("density")+xlab(expression(chi^2))
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
        text(0,0,"Error: b must be greater than a",col="red",cex=2)
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
        text(0,0,"Error: b must be greater than a",col="red",cex=2)
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
      HTML("P[&chi;<sup>2</sup> < a and &chi;<sup>2</sup> < b]")
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
    checkboxInput("graf_f_camp", label = "Sample", value = FALSE)
  })
  
  output$graf_f_camp_num<-renderUI({
    validate(need(input$graf_f_camp==TRUE,""))
    sliderInput(inputId="graf_f_camp_num",label = "Sample size",min = 1,max = 10000,value = 10,
                step=10)
  })
  
  output$graf_f<-renderPlot({
    require(ggplot2)
    x<-seq(0, 20,by = 0.1)
    df<-cbind.data.frame(x=x,y=df(x,df1 = input$graf_f_dof1,df2 = input$graf_f_dof2))
    gr<-ggplot() +theme_classic()+
      geom_line(data = df,mapping = aes(x=x,y=y))+
      ylab("density")+xlab("F")
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
        text(0,0,"Error: b must be greater than a",col="red",cex=2)
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
        text(0,0,"Error: b must be greater than a",col="red",cex=2)
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
      HTML("P[F < a and F > b]")
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

# Teorema centrale del limite ---------------------------------------------

  output$graf_lc_pop<-renderPlot({
    require(ggplot2)
    gr=as.factor(c(0,1))
    y=dbinom(x=c(0,1),prob = input$graf_lc_prob,size = 1)*100
    df<-cbind.data.frame(gr,y)
   ggplot(df,mapping = aes(gr))+geom_bar(aes(weight = y),fill="blue",color = "black",width=0.5)+
     theme_classic()+xlab("Y")+ylab("probability (%)")
  })
  
  output$lc_pop_media<-renderText({
    paste("mean =",input$graf_lc_prob)
  })
  
  output$lc_pop_var<-renderText({
    paste("variance =",input$graf_lc_prob*(1-input$graf_lc_prob))
  })
  
  output$graf_lc_titolo<-renderText({
   paste("mean distribuion of",input$graf_lc_numta_camp,"variables")
   })
  
  df_tlc<-reactive({
    input$lc_resample
    set.seed(as.numeric(Sys.time()))
    # df<-c(NULL)
    # for(i in 1: input$graf_lc_num_camp){
    #   df[i]<-mean(rbinom(n = input$graf_lc_numta_camp,size = 1,prob = input$graf_lc_prob))
    # }
    # df<-as.data.frame(df)
    # df<-2*df-1
    # names(df)<-"x"
    # df
    
    df <- rbinom(input$graf_lc_num_camp, size = input$graf_lc_numta_camp, prob = input$graf_lc_prob)
    df
    
  })

  output$graf_lc<-renderPlot({
    require(ggplot2)
    df <- df_tlc()
    media <- input$graf_lc_prob
    var <- input$graf_lc_prob*(1-input$graf_lc_prob)
    num <- input$graf_lc_numta_camp
    
    ggplot(data.frame(x = df), aes(x = x))+theme_classic()+
      geom_histogram(aes(y = after_stat(density) * 100),
                     fill="blue",col="white",color = "black", 
                    # binwidth =(max(df$x)-min(df$x))/sqrt(nrow(df))
                    binwidth =1
                     )+
        xlab("Number of Successes")+ylab("frequency (%)")+
      scale_x_continuous(breaks = 0:num,
                         limits = c(-1, num + 1)) +
      stat_function(fun = function(x) dnorm(x, mean = media*num, sd = sqrt(var*num)) * 100, 
                    color = "red", 
                    linewidth = 1) 
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
      ylab("density")+xlab(expression(frac(bar(Y)[m]-mu,sigma * sqrt(1/m))))+ggtitle("N(0,1)")+
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
        text(0,0,"   At least 1 degree of freedom is needed \n
        sample size at least 2 \n",col="red",cex=2)
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
        ylab("density")+xlab(expression(frac(bar(Y)[m]-mu,S[m] * sqrt(1/m))))+ggtitle(paste("T(",dof,")",sep=""))+
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
    paste("sample mean =",round(mean(int_conf_camp()),3))
  })
  
  output$int_conf_sd_camp<-renderText({
    validate(need(input$int_conf_var=="2",""))
    paste("sample standard dev. =",round(sd(int_conf_camp()),2))
  })
  
  output$int_conf_stat<-renderText({ 
    if(input$int_conf_var==1){
      st<-(mean(int_conf_camp())-input$int_conf_media)/(input$int_conf_ds*sqrt(1/input$int_conf_numta_camp))
      paste("statistic =",round(st,3))
    } else {
      st<-(mean(int_conf_camp())-input$int_conf_media)/(sd(int_conf_camp())*sqrt(1/input$int_conf_numta_camp))
      paste("statistic =",round(st,3))
    }
    })
  
  # output$int_conf_graf_ic<-renderPlot({
  #   validate(need(input$int_conf_alfa>0,""))
  #   library(lattice)
  #   media<-mean(int_conf_camp())
  #   m<-length(int_conf_camp())
  #   if(input$int_conf_var==1){
  #     s<-input$int_conf_ds
  #     q<-qnorm(input$int_conf_alfa/2,mean = 0,sd = 1,lower.tail = FALSE)
  #   } else {
  #     s<-sd(int_conf_camp())
  #     q<-qt(input$int_conf_alfa/2,df = m-1,lower.tail = FALSE)
  #   }
  #   x=media;y=0
  #   gr<-xyplot(y~x,type="n",xlim=c(input$int_conf_media - 4*q*s*sqrt(1/m),
  #                                  input$int_conf_media + 4*q*s*sqrt(1/m)),ylim=c(-1,2),
  #          par.settings=list(axis.line=list(col=NA), axis.text=list(col=NA)),xlab=NULL, ylab=NULL)
  #   print(gr)
  #   trellis.focus("panel", 1, 1, highlight=FALSE)
  #   panel.arrows(input$int_conf_media - 4*q*s*sqrt(1/m),0,
  #                input$int_conf_media + 4*q*s*sqrt(1/m),0,angle=20,length=0,lwd=0.1)
  #   panel.text(x=input$int_conf_media,y=-0.3,expression(mu))
  #   panel.arrows(input$int_conf_media,0,input$int_conf_media,2,lty=2,length=0)
  #   
  #   panel.arrows(media,1,media-q*s*sqrt(1/m),1,angle=90,length=0.05,col="green4")
  #   panel.arrows(media,1,media+q*s*sqrt(1/m),1,angle=90,length=0.05,col="green4")
  #   trellis.unfocus()
  # })
  
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
    gr<-xyplot(y~x,type="n",xlim=c(input$int_conf_media - 6*s*sqrt(1/m),
                                   input$int_conf_media + 6*s*sqrt(1/m)),ylim=c(-1,2),
               par.settings=list(axis.line=list(col=NA),axis.text=list(col=NA)),
               xlab=NULL, ylab=NULL)
    print(gr)
    trellis.focus("panel", 1, 1, highlight=FALSE)
    panel.arrows(input$int_conf_media - 6*s*sqrt(1/m),0,
                 input$int_conf_media + 6*s*sqrt(1/m),0,angle=20,length=0,lwd=0.1)
    panel.text(x=input$int_conf_media,y=-0.3,expression(mu))
    panel.arrows(input$int_conf_media,0,input$int_conf_media,2,lty=2,length=0)
    
    panel.arrows(media,1,media-q*s*sqrt(1/m),1,angle=90,length=0.05,col="green4")
    panel.arrows(media,1,media+q*s*sqrt(1/m),1,angle=90,length=0.05,col="green4")
    trellis.unfocus()
  })
  
  output$int_conf_IC_txt<-renderText({
    validate(need(input$int_conf_alfa>0," "))
    "Confidence interval"
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
    paste("lower extreme =",round(media-q*s*sqrt(1/m),3))
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
    paste("upper extreme =",round(media+q*s*sqrt(1/m),3))
  })
  
  
# test ipotesi -------------------------------------------------------------- 
  h0_camp<-reactive({
    input$h0_resample
    set.seed(as.numeric(Sys.time()))
    rnorm(n = input$h0_numta_camp,mean = input$h0_media,sd = input$h0_ds)
  })
  
  output$h0_Test1<-renderText({
    validate(need(input$h0_var==1,""))
    "Z-test"
  })
  
  output$h0_Test2<-renderText({
    validate(need(input$h0_var==2,""))
    "T-test"
  })
  
  output$h0_H0<-renderUI({
    req(input$h0_media)
    numericInput("h0_H0",label = "Assumed mean",
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
        ylab("density")+xlab(expression(frac(bar(Y)[m]-mu,sigma * sqrt(1/m))))+ggtitle("N(0,1)")+
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
        text(0,0,"   At least 1 degree of freedom is needed \n
             sample size at least 2 \n",col="red",cex=2)
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
          ylab("density")+xlab(expression(frac(bar(Y)[m]-mu,S[m] * sqrt(1/m))))+ggtitle(paste("T(",dof,")",sep=""))+
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
      paste("statistic =",round((mean(vrb[,1])-input$h0_H0)/(input$h0_ds*sqrt(1/nrow(vrb))),4)) 
    }else{
      paste("statistic =",round((mean(vrb[,1])-input$h0_H0)/(sd(vrb[,1])*sqrt(1/nrow(vrb))),4)) 
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
    "Power of the test"
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
        geom_line(data = df,mapping = aes(x=x,y=y),colour = 'grey')+
        ylab("density")+xlab(expression(frac(bar(Y)[m]-mu[0],sigma * sqrt(1/m))))+
        # ggtitle("N(0,1)")+
        # theme(plot.title = element_text(size = 20, face = "bold",
        #                                 hjust = 0.5,colour = 'grey'))+
        annotate(geom="text", x=-2.5, y=0.2, label=expression(H[0]),size=10,colour = 'grey')+
        annotate(geom="text", x=-2.5, y=0.35, label=expression(bold(N(0,1))),size=7,colour = 'grey')
    } else {
      df<-cbind.data.frame(x=x,y=dt(x,df = input$potenza_num_pop-1))
      q<-qt(input$potenza_alfa/2,df = input$potenza_num_pop-1,lower.tail = FALSE)
      if(q>10) q<-10
      gr<-ggplot() +theme_classic()+
        geom_line(data = df,mapping = aes(x=x,y=y),colour = 'grey')+
        ylab("density")+xlab(expression(frac(bar(Y)[m]-mu[0],S[m] * sqrt(1/m))))+
        # ggtitle(paste("t(",input$potenza_num_pop-1,")",sep=""))+
        # theme(plot.title = element_text(size = 20, face = "bold",
        #                                 hjust = 0.5))+
        annotate(geom="text", x=-2.5, y=0.2, label=expression(H[0]),size=10,colour = 'grey')+
        annotate(geom="text", x=-2.5, y=0.35, label=paste("T(",input$potenza_num_pop-1,")",sep=""),size=7,colour = 'grey',fontface='bold')
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
          annotate(geom="text", x=input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop))+2.5, y=0.2, label=expression(H[1]),size=10)+
          annotate(geom="text", x=input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop))+3.5, y=0.35, label=expression(bold(N(frac(d,sigma* sqrt(1/m)),1))),size=7)
      } else {
        delta<-input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop))
        x.b<-seq(-q,q,by = 0.1)
        df.b<-cbind.data.frame(x=c(-q,x.b,q),
                               y=c(0,dt(x.b,ncp = delta,df =input$potenza_num_pop-1),0))
        df1<-cbind.data.frame(x=x,y=dt(x,ncp = delta,df =input$potenza_num_pop-1))
 
        gr<-gr+geom_line(data = df1,mapping = aes(x=x,y=y))+
          geom_polygon(df.b,mapping = aes(x=x,y=y),fill="green")+
          annotate(geom="text", x=input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop))+2.5, y=0.2, label=expression(H[1]),size=10)+
          annotate(geom="text", x=input$potenza_delta/(input$potenza_ds*sqrt(1/input$potenza_num_pop))+3.5, y=0.35, 
                   label=expression(bold(paste("T(m-1, ",frac(d,sigma* sqrt(1/m)),")"))),
                   size=7)
      }
    }
    gr
  })
  
  output$potenza_err2<-renderText({
    validate(need(input$potenza_delta>0," "))
    "Type II error"
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
    "Power"
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
      ylab("density")+xlab("Y")+ggtitle("Populations distribution")+
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
    
    p<-ggplot(df, aes(x=gr, y=x)) + theme_light()+xlab("group")+ylim(-7,7)+ylab("Y")+
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
         degrees of freedom =",3*input$anova_numta_camp-3,"<br>
         MS<SUB>in</SUB> =",round(ss/(3*input$anova_numta_camp-3),3))
  })
  
  output$anova_graf_var_tra<-renderPlot({
    m.a<-mean(anova_camp1())
    m.b<-mean(anova_camp2())
    m.c<-mean(anova_camp3())
    
    df<-data.frame(m=c(m.a,m.b,m.c),gr=c(1,2,3),y=c("0","0","0"))
    df$gr<-as.factor(df$gr)
    
    p<-ggplot(df, aes(x=y, y=m)) + theme_light()+xlab("")+ylab("groups means")+ylim(-7,7)+
      theme(axis.text.y = element_text(size = 1))+
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
         degrees of freedom = 2 <br>
         MS<SUB>tra</SUB> =",round(ss/2,3))
  })
  
  output$anova_graf_var_tot<-renderPlot({
    m<-input$anova_numta_camp
    df<-data.frame(x=c(anova_camp1(),anova_camp2(),anova_camp3()),y=rep("0",3*m),gr=c(rep(1,m),rep(2,m),rep(3,m)))
    df$gr<-as.factor(df$gr)
    
    p<-ggplot(df, aes(x=y, y=x)) + theme_light()+xlab("")+ylim(-7,7)+ylab("Y")+
      theme(axis.text.y = element_text(size = 1))+
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
         degrees of freedom = ",3*input$anova_numta_camp-1,"<br>
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
    paste("statistic =",round(ms_tra/ms_in,4)) 
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
      ylab("density")+xlab("F")+
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
      "Line to be estimated: y = x"
    } else if (a!=0 & b==1){
      paste("Line to be estimated: y = ",input$regr_mq_a," + x",sep="")
    } else if(a==0 & b!=1){
      paste("Line to be estimated: y = ",input$regr_mq_b,"x",sep="")
    } else if (a!=0 & b!=1){
      paste("Line to be estimated: y = ",input$regr_mq_a," + ",input$regr_mq_b,"x",sep="")
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
        if(sum(df$y>df$y.prev)){
          gr<-gr+geom_rect(data = df, mapping=aes(xmin=x, ymin=y.prev, xmax= x+res,ymax=y),alpha=0.4,fill="blue")
        } else {
          gr<-gr+geom_rect(data = df, mapping=aes(xmin=x, ymin=y, xmax= x+res,ymax=y.prev),alpha=0.4,fill="blue")
        }}
      else if(2 %in% input$regr_mq_dq & 1 %in% input$regr_mq_dq ){
        gr<-gr+ geom_segment(data = df, aes(x = x, y = y, xend = x, yend = y.prev),col="blue", size=1.1)
        if(sum(df$y>df$y.prev)){
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
    paste("Intercept = ",round(mod$coefficients[1],2),sep="")
  })

  output$regr_mq_rregr_pdz<-renderText({
    validate(need(input$regr_mq_rregr==1,""))
    x<- as.numeric(unlist(strsplit(input$regr_mq_dis," ")))
    m<-length(x)
    y<-input$regr_mq_a+input$regr_mq_b*x+regr_mq_camp()
    r<-input$regr_mq_a+input$regr_mq_b*x
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    paste("Slope = ",round(mod$coefficients[2],2),sep="")
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
    "Parameters to be estimated:"
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
    paste("Intercept = ",round(mod$coefficients[1],2),sep="")
  })
  
  output$regr_sp_rregr_pdz<-renderText({
    validate(need(input$regr_sp_rregr==1,""))
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_sp_b*x+regr_sp_camp()
    r<-input$regr_sp_a+input$regr_sp_b*x
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    paste("Slope = ",round(mod$coefficients[2],2),sep="")
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
      ylab("density")+
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
    paste("statistic =",round(s$coefficients[1,3],3))
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
    paste("intercept =",round(s$coefficients[1,1],digits = 3))
  })
  
  output$regr_sp_int_es<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    paste("std. error =",round(s$coefficients[1,2],digits = 3))
  })

  output$regr_sp_int_ic_inf<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    q<-qt(input$regr_sp_alfa/2,df = m-2,lower.tail = FALSE)
    paste("lower extreme =",round(s$coefficients[1,1]-q*s$coefficients[1,2],digits = 3))
  })
  
  output$regr_sp_int_ic_sup<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    q<-qt(input$regr_sp_alfa/2,df = m-2,lower.tail = FALSE)
    paste("upper extreme =",round(s$coefficients[1,1]+q*s$coefficients[1,2],digits = 3))
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
      ylab("density")+
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
    paste("statistic =",round(s$coefficients[2,3],3))
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
    paste("slope =",round(s$coefficients[2,1],digits = 3))
  })
  
  output$regr_sp_pen_es<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    paste("std. error =",round(s$coefficients[2,2],digits = 3))
  })
  
  output$regr_sp_pen_ic_inf<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    q<-qt(input$regr_sp_alfa/2,df = m-2,lower.tail = FALSE)
    paste("lower extreme =",round(s$coefficients[2,1]-q*s$coefficients[2,2],digits = 3))
  })
  
  output$regr_sp_pen_ic_sup<-renderText({
    x<- as.numeric(unlist(strsplit(input$regr_sp_dis," ")))
    m<-length(x)
    y<-input$regr_sp_a+input$regr_mq_b*x+regr_sp_camp()
    df<-cbind.data.frame(x,y)
    mod<-lm(y~x,df)
    s<-summary(mod)
    q<-qt(input$regr_sp_alfa/2,df = m-2,lower.tail = FALSE)
    paste("upper extreme =",round(s$coefficients[2,1]+q*s$coefficients[2,2],digits = 3))
  }) 

  output$regr_prev_titolo<-renderText({
    a<-input$regr_prev_a
    b<-input$regr_prev_b
    paste("Value to be estimated = ",input$regr_prev_a+input$regr_prev_b*input$regr_prev_x0,sep="")
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
    paste("prediction = ",round(mod$coefficients[1]+mod$coefficients[2]*input$regr_prev_x0,3),sep="")
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
    paste("std. error = ",round(sqrt(h*sq),3),sep="")
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
    paste("lower extreme = ",round(p-q*sqrt(h*sq),3),sep="")
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
    paste("upper extreme = ",round(p+q*sqrt(h*sq),3),sep="")
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





