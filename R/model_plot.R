#' model_plot
#'
#' @param models Top five of VIs, models, used metric, observed variable, and predicted variable 
#' @param treatments Vector indicating the sequence of treatment pauses, e.g. c("0N", "60N", "120N", "180N", "240N")
#' @param shape Vector that specifies the order of the shapes for the treatment breaks in the legend, e.g. c(21, 22, 23, 24, 25)
#' @param y_breaks Number of breaks for the observable variable (y-axis) in the diagram, e.g. 5 for a range from 0 to 1, with the axis points marked at 0, 0.2, 0.4, 0.6, 0.8 and 1
#' @param min_y_lim Minimum limit for the axis of the observable variable (y-axis) in the diagram, e.g. 0
#' @param max_y_lim Maximum limit for the axis of the observable variable (y-axis) in the diagram, e.g. 1
#' @param directory Directory path in which the results are saved, e.g. "C:/Users/User/Downloads"
#' @param lables_treat Vector indicating the sequence of labels treatment pauses, e.g. c("0 kg N/ha", "60 kg N/ha", "120 kg N/ha", "180 kg N/ha", "240 kg N/ha")
#'
#' @return The plot top five the best models
#' 
#' @import ggplot2
#' @import paletteer
#' @import gridExtra
#' @import egg
#' @import svglite
#' @export
#'
#' @examples
#' maize_data = SPARK::maize
#' V10 = maize_data[maize_data$Stage == "V10", ]
#' bands_names <- c("B3", "B4", "B5", "B6", "B8", "B7_2", "B11_2", "VH",  "VVxL", "Ns")
#' 
#' # Combining spectral bands 
#' NNI_V10_VIs = optical_SAR_Ns_indices(
#'   data = V10, 
#'   y = V10["NNI"], 
#'   n_bands= 4, 
#'   set_bands = bands_names, 
#'   scan = 0.995
#' )
#' 
#' # Modeling vegetation indices with linear models 
#' NNI_V10_model = linear_model(
#'   VIs = NNI_V10_VIs,
#'   y = V10["NNI"],
#'   experiment = V10["Experiment"], 
#'   treatment = V10["Treatment"],
#'   train_exp = c(1, 2, 3, 4, 10, 11),   
#'   test_exp = c(5, 6, 7, 8, 9),  
#'   model_degree = 2,
#'   metric = "rrmse",
#'   orcutt = 1, 
#'   cook_distance = 0
#' )
#' 
#' # Ploting the restuls
#' model_plot(
#'  models = NNI_V10_model,                       
#'  treatments = c("0N", "60N", "120N", "180N", "240N"),
#'  lables_treat = c("  0 kg N/ha", " 60 kg N/ha", "120 kg N/ha", "180 kg N/ha", "240 kg N/ha"),
#'  shape = c(21, 22, 23, 24, 25),
#'  y_breaks = 5,
#'  min_y_lim = 0,
#'  max_y_lim = 2,
#'  directory = tempdir()  # Put a directory for the example
#' )
#' 
model_plot = function(models = models,  
                      treatments = c("0N", "60N", "120N", "180N", "240N"),
                      lables_treat = c("  0 kg N/ha", " 60 kg N/ha", "120 kg N/ha", "180 kg N/ha", "240 kg N/ha"),
                      shape = c(21,22,23,24,25),
                      y_breaks = 5,
                      min_y_lim = NULL,
                      max_y_lim = NULL,
                      directory = "."){
  
  suppressWarnings({
    
    output_mod1 = models$output_mod1
    output_mod2 = models$output_mod2
    output_mod3 = models$output_mod3
    output_mod4 = models$output_mod4
    output_mod5 = models$output_mod5
    
    if (!is.null(output_mod1)) {
      n_models = 1}else {print("No selected models")}
    
    if (!is.null(output_mod2)) {
      n_models = n_models + 1}
    
    if (!is.null(output_mod3)) {
      n_models = n_models + 1}
    
    if (!is.null(output_mod4)) {
      n_models = n_models + 1}
    
    if (!is.null(output_mod5)) {
      n_models = n_models + 1}
    
    
    if(is.null(min_y_lim)){
      min_y = min(models$best_train_VI_mod1[,2])
      max_y = max(models$best_train_VI_mod1[,2])
      
      min_y_lim = min_y - (max_y - min_y) * 0.05
    }
    
    if(is.null(max_y_lim)){
      min_y = min(models$best_train_VI_mod1[,2])
      max_y = max(models$best_train_VI_mod1[,2])
      
      max_y_lim = max_y + (max_y - min_y) * 0.05
    }
    
    
    if(n_models > 0 ){
      
      mod1 = models$best_model_mod1
      summarymodel_mod1 = summary(models$best_model_mod1)
      coefficients_mod1 = coef(summarymodel_mod1)
      
      x0_mod1 = output_mod1[1]
      x1_mod1 = output_mod1[2]
      x2_mod1 = output_mod1[3]
      
      curve_mod1 = function(x) {
        x0_mod1 + x1_mod1*(x) + x2_mod1*(x*x) }
      
      if (output_mod1[6] == 1) {
        print("The parameters of Model 1 were calculated using the iterative Cochrane-Orcutt")
      } 
      
      R2_mod1 = output_mod1[4]
      RMSE = output_mod1[5]
      min_x = min(models$best_train_VI_mod1[,3])
      max_x = max(models$best_train_VI_mod1[,3])
      
      min_x_lim = min_x - (max_x-min_x)*0.05 
      max_x_lim = max_x + (max_x-min_x)*0.05
      
      min_pred = min(models$best_test_VI_mod1[,5])
      max_pred = max(models$best_test_VI_mod1[,5])
      
      VI_x_lab = function(band_string) {
        terms = unlist(strsplit(band_string, "_div_"))
        process_terms = function(term) {
          term = gsub("-1", "-", term)
          term = gsub("_1", "+", term)
          term = gsub("_0", "+0", term)
          term = gsub("_2", "\u00B2", term)
          term = gsub("_", "", term)
          return(term)
        }
        processed_terms = lapply(terms, process_terms)
        processed_string = paste0("(", processed_terms[[1]], ")/(", processed_terms[[2]], ")")
        processed_string = gsub("\\(1", "(", processed_string)
        processed_string = gsub("\\(\\+", "(", processed_string)
        return(processed_string)
      }
      
      intelligent_round = function(value) {
        if (value < 1) {
          return(signif(value, digits = 2))
        } else if (value < 10) {
          return(format(round(value, 2), scientific = F)) 
        } else if (value < 100) {
          return(format(round(value, 1), scientific = F))
        } else {
          return(round(value, 0)) 
        }
      }
      
      
      VI_x_lab_mod1 = VI_x_lab(models$best_bands_mod1)
      VI_y_lab_mod1 = colnames(models$best_train_VI_mod1[2])
      
      text_loc_mod1 = lm(models$best_train_VI_mod1[,2] ~ models$best_train_VI_mod1[,3], data = models$best_train_VI_mod1)
      text_loc_mod1 = coef(text_loc_mod1)
      text_loc_mod1 = text_loc_mod1[2]     
      
      plot_train_mod1 = 
        ggplot(models$best_train_VI_mod1, aes(x = models$best_train_VI_mod1[,3], y = models$best_train_VI_mod1[,2])) +
        geom_point(aes(fill = as.factor(models$best_train_VI_mod1[,1]), shape = as.factor(models$best_train_VI_mod1[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+    
        
        stat_function(fun = curve_mod1, geom = "line", color = "black", linewidth = 0.25, xlim = c(min_x, max_x))+
        
        xlab(VI_x_lab_mod1) +
        ylab(VI_y_lab_mod1) +
        
        scale_fill_paletteer_d("ggthemes::stata_s1rcolor") +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "black", fill = NA, linewidth = 0.5),
          legend.position = "none",
          axis.line = element_line(color = "black", linewidth = 0.5),
          axis.text = element_text(color = "black",size = rel(0.6)),
          axis.ticks = element_line(color = "black"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8)),
          
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5)
        ) +
        
        scale_x_continuous(limits =   c(min_x_lim, max_x_lim))+
        scale_y_continuous(limits = c(min_y_lim, max_y_lim), n.breaks = y_breaks)+
        
        annotate("text", x = (max_x_lim+min_x_lim)/2, y = max_y_lim, label = "Model 1", size = 3) +
        
        if(x2_mod1!=0 & text_loc_mod1 > 0){ 
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod1),
                     "\nR\u00B2 = ", round(R2_mod1, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod1), " + ", intelligent_round(x1_mod1),"x +", intelligent_round(x2_mod1), "x\u00B2 "),
                   x = max_x_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5) 
        }else if (text_loc_mod1 > 0) {
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod1),
                     "\nR\u00B2 = ", round(R2_mod1, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod1), " + ", intelligent_round(x1_mod1),"x "),
                   x = max_x_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5)
          
        }else if (x2_mod1!=0){
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod1),
                     "\nR\u00B2 = ", round(R2_mod1, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod1), " + ", intelligent_round(x1_mod1),"x +", intelligent_round(x2_mod1), "x\u00B2 "),
                   x = min_x_lim, y =  min_y_lim, vjust = 'bottom', hjust = 'left', size = 2.5) 
        }else {
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod1),
                     "\nR\u00B2 = ", round(R2_mod1, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod1), " + ", intelligent_round(x1_mod1),"x "),
                   x = min_x_lim, y =  min_y_lim, vjust = 'bottom', hjust = 'left', size = 2.5)
        }
      
      print(plot_train_mod1)
      
    }
    
    
    if (n_models > 1 ) {
      
      mod2 = models$best_model_mod2
      summarymodel_mod2 = summary(models$best_model_mod2)
      coefficients_mod2 = coef(summarymodel_mod2)
      
      x0_mod2 = output_mod2[1]
      x1_mod2 = output_mod2[2]
      x2_mod2 = output_mod2[3]
      
      curve_mod2 = function(x) {
        x0_mod2 + x1_mod2*(x) + x2_mod2*(x*x) }
      
      if (output_mod2[6] == 1) {
        print("The parameters of Model 2 were calculated using the iterative Cochrane-Orcutt")
      } 
      
      R2_mod2 = output_mod2[4]
      RMSE = output_mod2[5]
      min_x = min(models$best_train_VI_mod2[,3])
      max_x = max(models$best_train_VI_mod2[,3])
      
      min_x_lim = min_x - (max_x-min_x)*0.05 
      max_x_lim = max_x + (max_x-min_x)*0.05
      
      min_pred_mod2 = min(models$best_test_VI_mod2[,5])
      min_pred =  min(min_pred, min_pred_mod2)
      
      max_pred_mod2 = max(models$best_test_VI_mod2[,5])
      max_pred =  max(max_pred, max_pred_mod2)
      
      intelligent_round = function(value) {
        if (value < 1) {
          return(signif(value, digits = 2)) 
        } else if (value < 10) {
          return(format(round(value, 2), scientific = F)) 
        } else if (value < 100) {
          return(format(round(value, 1), scientific = F)) 
        } else {
          return(round(value, 0)) 
        }
      }
      
      
      VI_x_lab_mod2 = VI_x_lab(models$best_bands_mod2)
      VI_y_lab_mod2 = colnames(models$best_train_VI_mod2[2])
      
      text_loc_mod2 = lm(models$best_train_VI_mod2[,2] ~ models$best_train_VI_mod2[,3], data = models$best_train_VI_mod2)
      text_loc_mod2 = coef(text_loc_mod2)
      text_loc_mod2 = text_loc_mod2[2]     
      
      plot_train_mod2 = 
        ggplot(models$best_train_VI_mod2, aes(x = models$best_train_VI_mod2[,3], y = models$best_train_VI_mod2[,2])) +
        geom_point(aes(fill = as.factor(models$best_train_VI_mod2[,1]), shape = as.factor(models$best_train_VI_mod2[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+    
        
        stat_function(fun = curve_mod2, geom = "line", color = "black", linewidth = 0.25, xlim = c(min_x, max_x))+
        
        xlab(VI_x_lab_mod2) +
        ylab(VI_y_lab_mod2) +
        
        scale_fill_paletteer_d("ggthemes::stata_s1rcolor") +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "black", fill = NA, linewidth = 0.5),
          legend.position = "none",
          axis.line = element_line(color = "black", linewidth = 0.5),
          axis.text = element_text(color = "black",size = rel(0.6)),
          axis.ticks = element_line(color = "black"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8)),
          
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5)
        ) +
        
        scale_x_continuous(limits =   c(min_x_lim, max_x_lim))+
        scale_y_continuous(limits = c(min_y_lim, max_y_lim), n.breaks = y_breaks)+
        
        annotate("text", x = (max_x_lim+min_x_lim)/2, y = max_y_lim, label = "Model 2", size = 3) +
        
        if(x2_mod2!=0 & text_loc_mod2 > 0){ 
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod2),
                     "\nR\u00B2 = ", round(R2_mod2, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod2), " + ", intelligent_round(x1_mod2),"x +", intelligent_round(x2_mod2), "x\u00B2 "),
                   x = max_x_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5) 
        }else if (text_loc_mod2 > 0) {
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod2),
                     "\nR\u00B2 = ", round(R2_mod2, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod2), " + ", intelligent_round(x1_mod2),"x "),
                   x = max_x_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5)
          
        }else if (x2_mod2!=0){
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod2),
                     "\nR\u00B2 = ", round(R2_mod2, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod2), " + ", intelligent_round(x1_mod2),"x +", intelligent_round(x2_mod2), "x\u00B2 "),
                   x = min_x_lim, y =  min_y_lim, vjust = 'bottom', hjust = 'left', size = 2.5)
        }else {
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod2),
                     "\nR\u00B2 = ", round(R2_mod2, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod2), " + ", intelligent_round(x1_mod2),"x "),
                   x = min_x_lim, y =  min_y_lim, vjust = 'bottom', hjust = 'left', size = 2.5)
        }
      
      print(plot_train_mod2)
      
    }
    
    
    
    if (n_models > 2 ) {
      
      mod3 = models$best_model_mod3
      summarymodel_mod3 = summary(models$best_model_mod3)
      coefficients_mod3 = coef(summarymodel_mod3)
      
      x0_mod3 = output_mod3[1]
      x1_mod3 = output_mod3[2]
      x2_mod3 = output_mod3[3]
      
      curve_mod3 = function(x) {
        x0_mod3 + x1_mod3*(x) + x2_mod3*(x*x) }
      
      if (output_mod3[6] == 1) {
        print("The parameters of Model 3 were calculated using the iterative Cochrane-Orcutt")
      } 
      
      R2_mod3 = output_mod3[4]
      RMSE = output_mod3[5]
      min_x = min(models$best_train_VI_mod3[,3])
      max_x = max(models$best_train_VI_mod3[,3])
      
      
      min_x_lim = min_x - (max_x-min_x)*0.05 
      max_x_lim = max_x + (max_x-min_x)*0.05
      
      min_pred_mod3 = min(models$best_test_VI_mod3[,5])
      min_pred =  min(min_pred, min_pred_mod3)
      
      max_pred_mod3 = max(models$best_test_VI_mod3[,5])
      max_pred =  max(max_pred, max_pred_mod3)
      
      
      intelligent_round = function(value) {
        if (value < 1) {
          return(signif(value, digits = 2)) 
        } else if (value < 10) {
          return(format(round(value, 2), scientific = F)) 
        } else if (value < 100) {
          return(format(round(value, 1), scientific = F)) 
        } else {
          return(round(value, 0)) 
        }
      }
      
      
      VI_x_lab_mod3 = VI_x_lab(models$best_bands_mod3)
      VI_y_lab_mod3 = colnames(models$best_train_VI_mod3[2])
      
      text_loc_mod3 = lm(models$best_train_VI_mod3[,2] ~ models$best_train_VI_mod3[,3], data = models$best_train_VI_mod3)
      text_loc_mod3 = coef(text_loc_mod3)
      text_loc_mod3 = text_loc_mod3[2]     
      
      plot_train_mod3 = 
        ggplot(models$best_train_VI_mod3, aes(x = models$best_train_VI_mod3[,3], y = models$best_train_VI_mod3[,2])) +
        geom_point(aes(fill = as.factor(models$best_train_VI_mod3[,1]), shape = as.factor(models$best_train_VI_mod3[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+    
        
        stat_function(fun = curve_mod3, geom = "line", color = "black", linewidth = 0.25, xlim = c(min_x, max_x))+
        
        xlab(VI_x_lab_mod3) +
        ylab(VI_y_lab_mod3) +
        
        scale_fill_paletteer_d("ggthemes::stata_s1rcolor") +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "black", fill = NA, linewidth = 0.5),
          legend.position = "none",
          axis.line = element_line(color = "black", linewidth = 0.5),
          axis.text = element_text(color = "black",size = rel(0.6)),
          axis.ticks = element_line(color = "black"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8)),
          
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5)
        ) +
        
        scale_x_continuous(limits =   c(min_x_lim, max_x_lim))+
        scale_y_continuous(limits = c(min_y_lim, max_y_lim), n.breaks = y_breaks)+
        
        annotate("text", x = (max_x_lim+min_x_lim)/2, y = max_y_lim, label = "Model 3", size = 3) +
        
        if(x2_mod3!=0 & text_loc_mod3 > 0){ 
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod3),
                     "\nR\u00B2 = ", round(R2_mod3, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod3), " + ", intelligent_round(x1_mod3),"x +", intelligent_round(x2_mod3), "x\u00B2 "),
                   x = max_x_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5) 
        }else if (text_loc_mod3 > 0) {
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod3),
                     "\nR\u00B2 = ", round(R2_mod3, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod3), " + ", intelligent_round(x1_mod3),"x "),
                   x = max_x_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5)
          
        }else if (x2_mod3!=0){
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod3),
                     "\nR\u00B2 = ", round(R2_mod3, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod3), " + ", intelligent_round(x1_mod3),"x +", intelligent_round(x2_mod3), "x\u00B2 "),
                   x = min_x_lim, y =  min_y_lim, vjust = 'bottom', hjust = 'left', size = 2.5)
        }else {
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod3),
                     "\nR\u00B2 = ", round(R2_mod3, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod3), " + ", intelligent_round(x1_mod3),"x "),
                   x = min_x_lim, y =  min_y_lim, vjust = 'bottom', hjust = 'left', size = 2.5)
        }
      
      print(plot_train_mod3)
      
    }
    
    
    
    if (n_models > 3 ) {
      
      mod4 = models$best_model_mod4
      summarymodel_mod4 = summary(models$best_model_mod4)
      coefficients_mod4 = coef(summarymodel_mod4)
      
      x0_mod4 = output_mod4[1]
      x1_mod4 = output_mod4[2]
      x2_mod4 = output_mod4[3]
      
      curve_mod4 = function(x) {
        x0_mod4 + x1_mod4*(x) + x2_mod4*(x*x) }
      
      if (output_mod4[6] == 1) {
        print("The parameters of Model 4 were calculated using the iterative Cochrane-Orcutt")
      } 
      
      R2_mod4 = output_mod4[4]
      RMSE = output_mod4[5]
      min_x = min(models$best_train_VI_mod4[,3])
      max_x = max(models$best_train_VI_mod4[,3])
      
      min_x_lim = min_x - (max_x-min_x)*0.05 
      max_x_lim = max_x + (max_x-min_x)*0.05
      
      min_pred_mod4 = min(models$best_test_VI_mod4[,5])
      min_pred =  min(min_pred, min_pred_mod4)
      
      max_pred_mod4 = max(models$best_test_VI_mod4[,5])
      max_pred =  max(max_pred, max_pred_mod4)
      
      
      intelligent_round = function(value) {
        if (value < 1) {
          return(signif(value, digits = 2)) 
        } else if (value < 10) {
          return(format(round(value, 2), scientific = F))  
        } else if (value < 100) {
          return(format(round(value, 1), scientific = F)) 
        } else {
          return(round(value, 0)) 
        }
      }
      
      
      VI_x_lab_mod4 = VI_x_lab(models$best_bands_mod4)
      VI_y_lab_mod4 = colnames(models$best_train_VI_mod4[2])
      
      text_loc_mod4 = lm(models$best_train_VI_mod4[,2] ~ models$best_train_VI_mod4[,3], data = models$best_train_VI_mod4)
      text_loc_mod4 = coef(text_loc_mod4)
      text_loc_mod4 = text_loc_mod4[2]     
      
      plot_train_mod4 = 
        ggplot(models$best_train_VI_mod4, aes(x = models$best_train_VI_mod4[,3], y = models$best_train_VI_mod4[,2])) +
        geom_point(aes(fill = as.factor(models$best_train_VI_mod4[,1]), shape = as.factor(models$best_train_VI_mod4[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+    
        
        stat_function(fun = curve_mod4, geom = "line", color = "black", linewidth = 0.25, xlim = c(min_x, max_x))+
        
        xlab(VI_x_lab_mod4) +
        ylab(VI_y_lab_mod4) +
        
        scale_fill_paletteer_d("ggthemes::stata_s1rcolor") +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "black", fill = NA, linewidth = 0.5),
          legend.position = "none",
          axis.line = element_line(color = "black", linewidth = 0.5),
          axis.text = element_text(color = "black",size = rel(0.6)),
          axis.ticks = element_line(color = "black"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8)),
          
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5)
        ) +
        
        scale_x_continuous(limits =   c(min_x_lim, max_x_lim))+
        scale_y_continuous(limits = c(min_y_lim, max_y_lim), n.breaks = y_breaks)+
        
        annotate("text", x = (max_x_lim+min_x_lim)/2, y = max_y_lim, label = "Model 4", size = 3) +
        
        if(x2_mod4!=0 & text_loc_mod4 > 0){ 
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod4),
                     "\nR\u00B2 = ", round(R2_mod4, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod4), " + ", intelligent_round(x1_mod4),"x +", intelligent_round(x2_mod4), "x\u00B2 "),
                   x = max_x_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5) 
        }else if (text_loc_mod4 > 0) {
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod4),
                     "\nR\u00B2 = ", round(R2_mod4, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod4), " + ", intelligent_round(x1_mod4),"x "),
                   x = max_x_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5)
          
        }else if (x2_mod4!=0){
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod4),
                     "\nR\u00B2 = ", round(R2_mod4, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod4), " + ", intelligent_round(x1_mod4),"x +", intelligent_round(x2_mod4), "x\u00B2 "),
                   x = min_x_lim, y =  min_y_lim, vjust = 'bottom', hjust = 'left', size = 2.5)
        }else {
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod4),
                     "\nR\u00B2 = ", round(R2_mod4, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod4), " + ", intelligent_round(x1_mod4),"x "),
                   x = min_x_lim, y =  min_y_lim, vjust = 'bottom', hjust = 'left', size = 2.5)
        }
      
      print(plot_train_mod4)
      
    }
    
    
    
    if (n_models > 4 ) {
      
      mod5 = models$best_model_mod5
      summarymodel_mod5 = summary(models$best_model_mod5)
      coefficients_mod5 = coef(summarymodel_mod5)
      
      x0_mod5 = output_mod5[1]
      x1_mod5 = output_mod5[2]
      x2_mod5 = output_mod5[3]
      
      curve_mod5 = function(x) {
        x0_mod5 + x1_mod5*(x) + x2_mod5*(x*x) }
      
      if (output_mod5[6] == 1) {
        print("The parameters of Model 5 were calculated using the iterative Cochrane-Orcutt")
      } 
      
      R2_mod5 = output_mod5[4]
      RMSE = output_mod5[5]
      min_x = min(models$best_train_VI_mod5[,3])
      max_x = max(models$best_train_VI_mod5[,3])
      
      min_x_lim = min_x - (max_x-min_x)*0.05 
      max_x_lim = max_x + (max_x-min_x)*0.05
      
      min_pred_mod5 = min(models$best_test_VI_mod5[,5])
      min_pred =  min(min_pred, min_pred_mod5)
      
      max_pred_mod5 = max(models$best_test_VI_mod5[,5])
      max_pred =  max(max_pred, max_pred_mod5)
      
      intelligent_round = function(value) {
        if (value < 1) {
          return(signif(value, digits = 2)) 
        } else if (value < 10) {
          return(format(round(value, 2), scientific = F))  
        } else if (value < 100) {
          return(format(round(value, 1), scientific = F)) 
        } else {
          return(round(value, 0)) 
        }
      }
      
      
      VI_x_lab_mod5 = VI_x_lab(models$best_bands_mod5)
      VI_y_lab_mod5 = colnames(models$best_train_VI_mod5[2])
      
      text_loc_mod5 = lm(models$best_train_VI_mod5[,2] ~ models$best_train_VI_mod5[,3], data = models$best_train_VI_mod5)
      text_loc_mod5 = coef(text_loc_mod5)
      text_loc_mod5 = text_loc_mod5[2]     
      
      plot_train_mod5 = 
        ggplot(models$best_train_VI_mod5, aes(x = models$best_train_VI_mod5[,3], y = models$best_train_VI_mod5[,2])) +
        geom_point(aes(fill = as.factor(models$best_train_VI_mod5[,1]), shape = as.factor(models$best_train_VI_mod5[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+    
        
        stat_function(fun = curve_mod5, geom = "line", color = "black", linewidth = 0.25, xlim = c(min_x, max_x))+
        
        xlab(VI_x_lab_mod5) +
        ylab(VI_y_lab_mod5) +
        
        scale_fill_paletteer_d("ggthemes::stata_s1rcolor") +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "black", fill = NA, linewidth = 0.5),
          legend.position = "none",
          axis.line = element_line(color = "black", linewidth = 0.5),
          axis.text = element_text(color = "black",size = rel(0.6)),
          axis.ticks = element_line(color = "black"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8)),
          
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5)
        ) +
        
        scale_x_continuous(limits =   c(min_x_lim, max_x_lim))+
        scale_y_continuous(limits = c(min_y_lim, max_y_lim), n.breaks = y_breaks)+
        
        annotate("text", x = (max_x_lim+min_x_lim)/2, y = max_y_lim, label = "Model 5", size = 3) +
        
        if(x2_mod5!=0 & text_loc_mod5 > 0){ 
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod5),
                     "\nR\u00B2 = ", round(R2_mod5, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod5), " + ", intelligent_round(x1_mod5),"x +", intelligent_round(x2_mod5), "x\u00B2 "),
                   x = max_x_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5) 
        }else if (text_loc_mod5 > 0) {
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod5),
                     "\nR\u00B2 = ", round(R2_mod5, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod5), " + ", intelligent_round(x1_mod5),"x "),
                   x = max_x_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5)
          
        }else if (x2_mod5!=0){
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod5),
                     "\nR\u00B2 = ", round(R2_mod5, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod5), " + ", intelligent_round(x1_mod5),"x +", intelligent_round(x2_mod5), "x\u00B2 "),
                   x = min_x_lim, y =  min_y_lim, vjust = 'bottom', hjust = 'left', size = 2.5)
        }else {
          annotate("text", color = "black",
                   label = paste(
                     "n = ", nrow(models$best_train_VI_mod5),
                     "\nR\u00B2 = ", round(R2_mod5, 2),
                     "\nRMSE = ", intelligent_round(RMSE),
                     "\ny = ", intelligent_round(x0_mod5), " + ", intelligent_round(x1_mod5),"x "),
                   x = min_x_lim, y =  min_y_lim, vjust = 'bottom', hjust = 'left', size = 2.5)
        }
      
      print(plot_train_mod5)
      
      
    }
    
    
    
    if (n_models > 0 ) {
      train_legend = 
        ggplot(models$best_train_VI_mod1, aes(x = models$best_train_VI_mod1[,3], y = models$best_train_VI_mod1[,2])) +
        geom_point(aes(fill = as.factor(models$best_train_VI_mod1[,1]), shape = as.factor(models$best_train_VI_mod1[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+ 
        
        
        scale_fill_paletteer_d("ggthemes::stata_s1rcolor") +
        
        guides(
          fill = guide_legend(title = "Experiment", title.hjust = 0, label.hjust = 0, override.aes=list(shape=21,size=2.25, alpha = 0.6)),
          shape = guide_legend(title = "Treatment", title.hjust = 0, label.hjust = 1,override.aes=list(size=2.25))
        ) +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "white", fill = "white", linewidth = 0.5),
          legend.position = c(0.95,0.8),
          legend.box = "horizontal",
          legend.justification = c(1, 1),
          legend.key.height = unit(0.3, 'cm'),
          legend.key.width = unit(0.4, 'cm'),
          legend.title = element_text(size = 10),
          legend.text = element_text(size = 8),
          axis.line = element_line(color = "white", linewidth = 0.5),
          axis.text = element_text(color = "white",size = rel(0.6)),
          axis.ticks = element_line(color = "white"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8), color = "white"),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5))
      
    }
    
    
    
    if (n_models > 0 ) {
      
      if(min_pred < min_y_lim){min_y_lim = min_pred}
      if(max_pred > max_y_lim){max_y_lim = max_pred}
      
      test_KGEs <- NULL
      test_RMSEs <- NULL
      test_RRMSEs <- NULL
      test_MAEs <- NULL
      test_MAPEs <- NULL
      
      VI_y_lab_mod = colnames(models$best_test_VI_mod1[2])
      
      test_pred = data.frame(models$best_test_VI_mod1)
      test_exp = unique(test_pred[,1])
      for (exp in test_exp) {
        test_exp_data_mod1 = test_pred[test_pred[,1] == exp, , drop = FALSE]
        
        test_KGE_exp = 1 - sqrt(
          (cor(test_exp_data_mod1[,2], test_exp_data_mod1[,5]) - 1)^2 + 
            ((sqrt(mean((test_exp_data_mod1[,5] - mean(test_exp_data_mod1[,5]))^2))/mean(test_exp_data_mod1[,5])) / (sqrt(mean((test_exp_data_mod1[,2] - mean(test_exp_data_mod1[,2]))^2))/mean(test_exp_data_mod1[,2])) - 1)^2 +
            (mean(test_exp_data_mod1[,5]) / mean(test_exp_data_mod1[,2]) - 1)^2 )
        test_KGEs = cbind(test_KGEs, test_KGE_exp)
        
        test_RMSE_exp = sqrt(mean((test_exp_data_mod1[,5] - test_exp_data_mod1[,2])^2))
        test_RMSEs = cbind(test_RMSEs, test_RMSE_exp)
        
        test_RRMSE_exp = sqrt(mean((test_exp_data_mod1[,5] - test_exp_data_mod1[,2])^2))/mean(test_exp_data_mod1[,2])*100
        test_RRMSEs = cbind(test_RRMSEs, test_RRMSE_exp)
        
        test_MAE_exp = mean(abs((test_exp_data_mod1[,2]-test_exp_data_mod1[,5])))
        test_MAEs = cbind(test_MAEs, test_MAE_exp)
        
        test_MAPE_exp = mean(abs((test_exp_data_mod1[,2]-test_exp_data_mod1[,5])/test_exp_data_mod1[,2])) * 100
        test_MAPEs = cbind(test_MAPEs, test_MAPE_exp)
      }
      
      KGE = mean(test_KGEs)
      RMSE = mean(test_RMSEs)
      RRMSE = mean(test_RRMSEs)
      MAE = mean(test_MAEs)
      MAPE = mean(test_MAPEs)
      
      
      plot_test_mod1 <- 
        ggplot(models$best_test_VI_mod1, aes(x = models$best_test_VI_mod1[,5], y = models$best_test_VI_mod1[,2])) +
        geom_point(aes(fill = as.factor(models$best_test_VI_mod1[,1]), shape = as.factor(models$best_test_VI_mod1[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+    
        
        geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black", size = 0.3, alpha = 0.6) +
        
        xlab(paste("Predicted", VI_y_lab_mod)) +
        ylab(paste("Observed ", VI_y_lab_mod)) +
        
        scale_fill_paletteer_d(palette = "ggthemes::stata_s1rcolor", direction = -1) +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "black", fill = NA, linewidth = 0.5),
          legend.position = "none",
          axis.line = element_line(color = "black", linewidth = 0.5),
          axis.text = element_text(color = "black",size = rel(0.6)),
          axis.ticks = element_line(color = "black"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8)),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5)
        ) +
        
        scale_x_continuous(limits =   c(min_y_lim, max_y_lim))+
        scale_y_continuous(limits = c(min_y_lim, max_y_lim), n.breaks = y_breaks)+
        annotate("text", x = (max_y_lim + min_y_lim)/2, y = max_y_lim, label = "Model 1", size = 3) +
        annotate("text", color = "black",
                 label = paste(
                   "n = ", nrow(models$best_test_VI_mod1),
                   "\nKGE = ", round(KGE, 2),
                   "\nRMSE = ", intelligent_round(RMSE),
                   "\nRRMSE = ", round(RRMSE, 0), "%",
                   "\nMAE = ", intelligent_round(MAE),
                   "\nMAPE = ", round(MAPE, 0), "% "),
                 x = max_y_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5) 
      
      print(plot_test_mod1)
    }
    
    
    
    if (n_models > 1 ) {
      
      test_KGEs <- NULL
      test_RMSEs <- NULL
      test_RRMSEs <- NULL
      test_MAEs <- NULL
      test_MAPEs <- NULL
      
      test_pred = data.frame(models$best_test_VI_mod2)
      test_exp = unique(test_pred[,1])
      for (exp in test_exp) {
        test_exp_data_mod2 = test_pred[test_pred[,1] == exp, , drop = FALSE]
        
        test_KGE_exp = 1 - sqrt(
          (cor(test_exp_data_mod2[,2], test_exp_data_mod2[,5]) - 1)^2 + 
            ((sqrt(mean((test_exp_data_mod2[,5] - mean(test_exp_data_mod2[,5]))^2))/mean(test_exp_data_mod2[,5])) / (sqrt(mean((test_exp_data_mod2[,2] - mean(test_exp_data_mod2[,2]))^2))/mean(test_exp_data_mod2[,2])) - 1)^2 +
            (mean(test_exp_data_mod2[,5]) / mean(test_exp_data_mod2[,2]) - 1)^2 )
        test_KGEs = cbind(test_KGEs, test_KGE_exp)
        
        test_RMSE_exp = sqrt(mean((test_exp_data_mod2[,5] - test_exp_data_mod2[,2])^2))
        test_RMSEs = cbind(test_RMSEs, test_RMSE_exp)
        
        test_RRMSE_exp = sqrt(mean((test_exp_data_mod2[,5] - test_exp_data_mod2[,2])^2))/mean(test_exp_data_mod2[,2])*100
        test_RRMSEs = cbind(test_RRMSEs, test_RRMSE_exp)
        
        test_MAE_exp = mean(abs((test_exp_data_mod2[,2]-test_exp_data_mod2[,5])))
        test_MAEs = cbind(test_MAEs, test_MAE_exp)
        
        test_MAPE_exp = mean(abs((test_exp_data_mod2[,2]-test_exp_data_mod2[,5])/test_exp_data_mod2[,2])) * 100
        test_MAPEs = cbind(test_MAPEs, test_MAPE_exp)
      }
      
      KGE = mean(test_KGEs)
      RMSE = mean(test_RMSEs)
      RRMSE = mean(test_RRMSEs)
      MAE = mean(test_MAEs)
      MAPE = mean(test_MAPEs)
      
      
      plot_test_mod2 <- 
        ggplot(models$best_test_VI_mod2, aes(x = models$best_test_VI_mod2[,5], y = models$best_test_VI_mod2[,2])) +
        geom_point(aes(fill = as.factor(models$best_test_VI_mod2[,1]), shape = as.factor(models$best_test_VI_mod2[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+    
        
        geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black", size = 0.3, alpha = 0.6) +
        
        xlab(paste("Predicted", VI_y_lab_mod)) +
        ylab(paste("Observed ", VI_y_lab_mod)) +
        
        scale_fill_paletteer_d(palette = "ggthemes::stata_s1rcolor", direction = -1) +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "black", fill = NA, linewidth = 0.5),
          legend.position = "none",
          axis.line = element_line(color = "black", linewidth = 0.5),
          axis.text = element_text(color = "black",size = rel(0.6)),
          axis.ticks = element_line(color = "black"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8)),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5)
        ) +
        
        scale_x_continuous(limits =   c(min_y_lim, max_y_lim))+
        scale_y_continuous(limits = c(min_y_lim, max_y_lim), n.breaks = y_breaks)+
        annotate("text", x = (max_y_lim + min_y_lim)/2, y = max_y_lim, label = "Model 2", size = 3) +
        annotate("text", color = "black",
                 label = paste(
                   "n = ", nrow(models$best_test_VI_mod2),
                   "\nKGE = ", round(KGE, 2),
                   "\nRMSE = ", intelligent_round(RMSE),
                   "\nRRMSE = ", round(RRMSE, 0), "%",
                   "\nMAE = ", intelligent_round(MAE),
                   "\nMAPE = ", round(MAPE, 0), "% "),
                 x = max_y_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5) 
      
      print(plot_test_mod2)
    }
    
    
    
    if (n_models > 2 ) {
      
      test_KGEs <- NULL
      test_RMSEs <- NULL
      test_RRMSEs <- NULL
      test_MAEs <- NULL
      test_MAPEs <- NULL
      
      test_pred = data.frame(models$best_test_VI_mod3)
      test_exp = unique(test_pred[,1])
      for (exp in test_exp) {
        test_exp_data_mod3 = test_pred[test_pred[,1] == exp, , drop = FALSE]
        
        test_KGE_exp = 1 - sqrt(
          (cor(test_exp_data_mod3[,2], test_exp_data_mod3[,5]) - 1)^2 + 
            ((sqrt(mean((test_exp_data_mod3[,5] - mean(test_exp_data_mod3[,5]))^2))/mean(test_exp_data_mod3[,5])) / (sqrt(mean((test_exp_data_mod3[,2] - mean(test_exp_data_mod3[,2]))^2))/mean(test_exp_data_mod3[,2])) - 1)^2 +
            (mean(test_exp_data_mod3[,5]) / mean(test_exp_data_mod3[,2]) - 1)^2 )
        test_KGEs = cbind(test_KGEs, test_KGE_exp)
        
        test_RMSE_exp = sqrt(mean((test_exp_data_mod3[,5] - test_exp_data_mod3[,2])^2))
        test_RMSEs = cbind(test_RMSEs, test_RMSE_exp)
        
        test_RRMSE_exp = sqrt(mean((test_exp_data_mod3[,5] - test_exp_data_mod3[,2])^2))/mean(test_exp_data_mod3[,2])*100
        test_RRMSEs = cbind(test_RRMSEs, test_RRMSE_exp)
        
        test_MAE_exp = mean(abs((test_exp_data_mod3[,2]-test_exp_data_mod3[,5])))
        test_MAEs = cbind(test_MAEs, test_MAE_exp)
        
        test_MAPE_exp = mean(abs((test_exp_data_mod3[,2]-test_exp_data_mod3[,5])/test_exp_data_mod3[,2])) * 100
        test_MAPEs = cbind(test_MAPEs, test_MAPE_exp)
      }
      
      KGE = mean(test_KGEs)
      RMSE = mean(test_RMSEs)
      RRMSE = mean(test_RRMSEs)
      MAE = mean(test_MAEs)
      MAPE = mean(test_MAPEs)
      
      plot_test_mod3 <- 
        ggplot(models$best_test_VI_mod3, aes(x = models$best_test_VI_mod3[,5], y = models$best_test_VI_mod3[,2])) +
        geom_point(aes(fill = as.factor(models$best_test_VI_mod3[,1]), shape = as.factor(models$best_test_VI_mod3[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+    
        
        geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black", size = 0.3, alpha = 0.6) +
        
        xlab(paste("Predicted", VI_y_lab_mod)) +
        ylab(paste("Observed ", VI_y_lab_mod)) +
        
        scale_fill_paletteer_d(palette = "ggthemes::stata_s1rcolor", direction = -1) +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "black", fill = NA, linewidth = 0.5),
          legend.position = "none",
          axis.line = element_line(color = "black", linewidth = 0.5),
          axis.text = element_text(color = "black",size = rel(0.6)),
          axis.ticks = element_line(color = "black"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8)),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5)
        ) +
        
        scale_x_continuous(limits =   c(min_y_lim, max_y_lim))+
        scale_y_continuous(limits = c(min_y_lim, max_y_lim), n.breaks = y_breaks)+
        annotate("text", x = (max_y_lim + min_y_lim)/2, y = max_y_lim, label = "Model 3", size = 3) +
        annotate("text", color = "black",
                 label = paste(
                   "n = ", nrow(models$best_test_VI_mod3),
                   "\nKGE = ", round(KGE, 2),
                   "\nRMSE = ", intelligent_round(RMSE),
                   "\nRRMSE = ", round(RRMSE, 0), "%",
                   "\nMAE = ", intelligent_round(MAE),
                   "\nMAPE = ", round(MAPE, 0), "% "),
                 x = max_y_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5) 
      
      print(plot_test_mod3)
    }
    
    
    
    if (n_models > 3 ) {
      
      test_KGEs <- NULL
      test_RMSEs <- NULL
      test_RRMSEs <- NULL
      test_MAEs <- NULL
      test_MAPEs <- NULL
      
      test_pred = data.frame(models$best_test_VI_mod4)
      test_exp = unique(test_pred[,1])
      for (exp in test_exp) {
        test_exp_data_mod4 = test_pred[test_pred[,1] == exp, , drop = FALSE]
        test_KGE_exp = 1 - sqrt(
          (cor(test_exp_data_mod4[,2], test_exp_data_mod4[,5]) - 1)^2 + 
            ((sqrt(mean((test_exp_data_mod4[,5] - mean(test_exp_data_mod4[,5]))^2))/mean(test_exp_data_mod4[,5])) / (sqrt(mean((test_exp_data_mod4[,2] - mean(test_exp_data_mod4[,2]))^2))/mean(test_exp_data_mod4[,2])) - 1)^2 +
            (mean(test_exp_data_mod4[,5]) / mean(test_exp_data_mod4[,2]) - 1)^2 )
        test_KGEs = cbind(test_KGEs, test_KGE_exp)
        
        test_RMSE_exp = sqrt(mean((test_exp_data_mod4[,5] - test_exp_data_mod4[,2])^2))
        test_RMSEs = cbind(test_RMSEs, test_RMSE_exp)
        
        test_RRMSE_exp = sqrt(mean((test_exp_data_mod4[,5] - test_exp_data_mod4[,2])^2))/mean(test_exp_data_mod4[,2])*100
        test_RRMSEs = cbind(test_RRMSEs, test_RRMSE_exp)
        
        test_MAE_exp = mean(abs((test_exp_data_mod4[,2]-test_exp_data_mod4[,5])))
        test_MAEs = cbind(test_MAEs, test_MAE_exp)
        
        test_MAPE_exp = mean(abs((test_exp_data_mod4[,2]-test_exp_data_mod4[,5])/test_exp_data_mod4[,2])) * 100
        test_MAPEs = cbind(test_MAPEs, test_MAPE_exp)
      }
      
      
      KGE = mean(test_KGEs)
      RMSE = mean(test_RMSEs)
      RRMSE = mean(test_RRMSEs)
      MAE = mean(test_MAEs)
      MAPE = mean(test_MAPEs)
      
      
      plot_test_mod4 <- 
        ggplot(models$best_test_VI_mod4, aes(x = models$best_test_VI_mod4[,5], y = models$best_test_VI_mod4[,2])) +
        geom_point(aes(fill = as.factor(models$best_test_VI_mod4[,1]), shape = as.factor(models$best_test_VI_mod4[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+    
        
        geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black", size = 0.3, alpha = 0.6) +
        
        xlab(paste("Predicted", VI_y_lab_mod)) +
        ylab(paste("Observed ", VI_y_lab_mod)) +
        
        scale_fill_paletteer_d(palette = "ggthemes::stata_s1rcolor", direction = -1) +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "black", fill = NA, linewidth = 0.5),
          legend.position = "none",
          axis.line = element_line(color = "black", linewidth = 0.5),
          axis.text = element_text(color = "black",size = rel(0.6)),
          axis.ticks = element_line(color = "black"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8)),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5)
        ) +
        
        scale_x_continuous(limits =   c(min_y_lim, max_y_lim))+
        scale_y_continuous(limits = c(min_y_lim, max_y_lim), n.breaks = y_breaks)+
        annotate("text", x = (max_y_lim + min_y_lim)/2, y = max_y_lim, label = "Model 4", size = 3) +
        annotate("text", color = "black",
                 label = paste(
                   "n = ", nrow(models$best_test_VI_mod4),
                   "\nKGE = ", round(KGE, 2),
                   "\nRMSE = ", intelligent_round(RMSE),
                   "\nRRMSE = ", round(RRMSE, 0), "%",
                   "\nMAE = ", intelligent_round(MAE),
                   "\nMAPE = ", round(MAPE, 0), "% "),
                 x = max_y_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5) 
      
      print(plot_test_mod4)
    }
    
    
    
    if (n_models > 4 ) {
      
      test_KGEs <- NULL
      test_RMSEs <- NULL
      test_RRMSEs <- NULL
      test_MAEs <- NULL
      test_MAPEs <- NULL
      
      test_pred = data.frame(models$best_test_VI_mod5)
      test_exp = unique(test_pred[,1])
      for (exp in test_exp) {
        test_exp_data_mod5 = test_pred[test_pred[,1] == exp, , drop = FALSE]
        
        test_KGE_exp = 1 - sqrt(
          (cor(test_exp_data_mod5[,2], test_exp_data_mod5[,5]) - 1)^2 + 
            ((sqrt(mean((test_exp_data_mod5[,5] - mean(test_exp_data_mod5[,5]))^2))/mean(test_exp_data_mod5[,5])) / (sqrt(mean((test_exp_data_mod5[,2] - mean(test_exp_data_mod5[,2]))^2))/mean(test_exp_data_mod5[,2])) - 1)^2 +
            (mean(test_exp_data_mod5[,5]) / mean(test_exp_data_mod5[,2]) - 1)^2 )
        test_KGEs = cbind(test_KGEs, test_KGE_exp)
        
        test_RMSE_exp = sqrt(mean((test_exp_data_mod5[,5] - test_exp_data_mod5[,2])^2))
        test_RMSEs = cbind(test_RMSEs, test_RMSE_exp)
        
        test_RRMSE_exp = sqrt(mean((test_exp_data_mod5[,5] - test_exp_data_mod5[,2])^2))/mean(test_exp_data_mod5[,2])*100
        test_RRMSEs = cbind(test_RRMSEs, test_RRMSE_exp)
        
        test_MAE_exp = mean(abs((test_exp_data_mod5[,2]-test_exp_data_mod5[,5])))
        test_MAEs = cbind(test_MAEs, test_MAE_exp)
        
        test_MAPE_exp = mean(abs((test_exp_data_mod5[,2]-test_exp_data_mod5[,5])/test_exp_data_mod5[,2])) * 100
        test_MAPEs = cbind(test_MAPEs, test_MAPE_exp)
      }
      
      KGE = mean(test_KGEs)
      RMSE = mean(test_RMSEs)
      RRMSE = mean(test_RRMSEs)
      MAE = mean(test_MAEs)
      MAPE = mean(test_MAPEs)
      
      
      plot_test_mod5 <- 
        ggplot(models$best_test_VI_mod5, aes(x = models$best_test_VI_mod5[,5], y = models$best_test_VI_mod5[,2])) +
        geom_point(aes(fill = as.factor(models$best_test_VI_mod5[,1]), shape = as.factor(models$best_test_VI_mod5[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+    
        
        geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black", size = 0.3, alpha = 0.6) +
        
        xlab(paste("Predicted", VI_y_lab_mod)) +
        ylab(paste("Observed ", VI_y_lab_mod)) +
        
        scale_fill_paletteer_d(palette = "ggthemes::stata_s1rcolor", direction = -1) +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "black", fill = NA, linewidth = 0.5),
          legend.position = "none",
          axis.line = element_line(color = "black", linewidth = 0.5),
          axis.text = element_text(color = "black",size = rel(0.6)),
          axis.ticks = element_line(color = "black"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8)),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5)
        ) +
        
        scale_x_continuous(limits =   c(min_y_lim, max_y_lim))+
        scale_y_continuous(limits = c(min_y_lim, max_y_lim), n.breaks = y_breaks)+
        annotate("text", x = (max_y_lim + min_y_lim)/2, y = max_y_lim, label = "Model 5", size = 3) +
        annotate("text", color = "black",
                 label = paste(
                   "n = ", nrow(models$best_test_VI_mod5),
                   "\nKGE = ", round(KGE, 2),
                   "\nRMSE = ", intelligent_round(RMSE),
                   "\nRRMSE = ", round(RRMSE, 0), "%",
                   "\nMAE = ", intelligent_round(MAE),
                   "\nMAPE = ", round(MAPE, 0), "% "),
                 x = max_y_lim, y = min_y_lim, vjust = 'bottom', hjust = 'right', size = 2.5) 
      
      print(plot_test_mod5)
    }
    
    
    
    if (n_models > 0) {
      test_legend = 
        ggplot(models$best_test_VI_mod1, aes(x = models$best_test_VI_mod1[,5], y = models$best_test_VI_mod1[,2])) +
        geom_point(aes(fill = as.factor(models$best_test_VI_mod1[,1]), shape = as.factor(models$best_test_VI_mod1[,4])), color = "black", size = 2.25, alpha = 0.6, stroke = 0.3) +
        scale_shape_manual(breaks = treatments,
                           name = "",
                           values = shape,
                           labels = lables_treat )+ 
        
        
        scale_fill_paletteer_d("ggthemes::stata_s1rcolor", direction = -1) +
        
        guides(
          fill = guide_legend(title = "Experiment", title.hjust = 0, label.hjust = 0, override.aes=list(shape=21,size=2.25, alpha = 0.6)),
          shape = guide_legend(title = "Treatment", title.hjust = 0, label.hjust = 1,override.aes=list(size=2.25))
        ) +
        
        
        theme_minimal() +
        theme(
          panel.border = element_rect(linetype = "solid", colour = "white", fill = "white", linewidth = 0.5),
          legend.position = c(0.95,0.8),
          legend.box = "horizontal",
          legend.justification = c(1, 1),
          legend.key.height = unit(0.3, 'cm'),
          legend.key.width = unit(0.4, 'cm'),
          legend.title = element_text(size = 10),
          legend.text = element_text(size = 8),
          axis.line = element_line(color = "white", linewidth = 0.5),
          axis.text = element_text(color = "white",size = rel(0.6)),
          axis.ticks = element_line(color = "white"),
          axis.ticks.length = unit(0.15, "cm"),
          axis.title = element_text(size = rel(0.8), color = "white"),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(5.5, 40, 5.5, 5.5))
      
    }
    
    
    
    if(n_models == 5) {
      
      ggsave(filename = file.path(directory, "Train_Models.svg"), dpi = 1000, limitsize = F,
             
             grid.arrange(grobs = lapply(list(
               plot_train_mod1 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")), 
               plot_train_mod2 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               plot_train_mod3 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               plot_train_mod4 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),   
               plot_train_mod5 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               train_legend + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm"))
             ),
             set_panel_size,
             width = unit(5, "cm"),
             height = unit(5, "cm")
             ), nrow = 2, ncol = 3),
             width = 21, height = 13, units = "cm")
      
      ggsave(filename = file.path(directory, "Test_Models.svg"), dpi = 1000, limitsize = F,
             
             grid.arrange(grobs = lapply(list(
               plot_test_mod1 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")), 
               plot_test_mod2 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               plot_test_mod3 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               plot_test_mod4 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")), 
               plot_test_mod5 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               test_legend + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm"))
             ),
             set_panel_size,
             width = unit(5, "cm"),
             height = unit(5, "cm")
             ), nrow = 2, ncol = 3),
             width = 21, height = 13, units = "cm")}
    
    
    
    if(n_models==4) {
      
      ggsave(filename = file.path(directory, "Train_Models.svg"), dpi = 1000, limitsize = F,
             
             grid.arrange(grobs = lapply(list(
               plot_train_mod1 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")), 
               plot_train_mod2 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               plot_train_mod3 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               plot_train_mod4 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),   
               train_legend + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm"))
             ),
             set_panel_size,
             width = unit(5, "cm"),
             height = unit(5, "cm")
             ), nrow = 2, ncol = 3),
             width = 21, height = 13, units = "cm")
      
      ggsave(filename = file.path(directory, "Test_Models.svg"), dpi = 1000, limitsize = F,
             
             grid.arrange(grobs = lapply(list(
               plot_test_mod1 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")), 
               plot_test_mod2 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               plot_test_mod3 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               plot_test_mod4 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")), 
               test_legend + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm"))
             ),
             set_panel_size,
             width = unit(5, "cm"),
             height = unit(5, "cm")
             ), nrow = 2, ncol = 3),
             width = 21, height = 13, units = "cm")}
    
    
    
    if(n_models==3) {
      
      ggsave(filename = file.path(directory, "Train_Models.svg"), dpi = 1000, limitsize = F,
             grid.arrange(grobs = lapply(list(
               plot_train_mod1 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")), 
               plot_train_mod2 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               plot_train_mod3 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),  
               train_legend + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm"))
             ),
             set_panel_size,
             width = unit(5, "cm"),
             height = unit(5, "cm")
             ), nrow = 2, ncol = 2),
             width = 14, height = 13, units = "cm")
      
      ggsave(filename = file.path(directory, "Test_Models.svg"), dpi = 1000, limitsize = F,
             grid.arrange(grobs = lapply(list(
               plot_test_mod1 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")), 
               plot_test_mod2 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               plot_test_mod3 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               test_legend + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm"))
             ),
             set_panel_size,
             width = unit(5, "cm"),
             height = unit(5, "cm")
             ), nrow = 2, ncol = 2),
             width = 14, height = 13, units = "cm")}
    
    if(n_models==2) {
      
      ggsave(filename = file.path(directory, "Train_Models.svg"), dpi = 1000, limitsize = F,
             grid.arrange(grobs = lapply(list(
               plot_train_mod1 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")), 
               plot_train_mod2 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               train_legend + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm"))
             ),
             set_panel_size,
             width = unit(5, "cm"),
             height = unit(5, "cm")
             ), nrow = 1, ncol = 3),
             width = 21, height = 6.5, units = "cm")
      
      ggsave(filename = file.path(directory, "Test_Models.svg"), dpi = 1000, limitsize = F,
             grid.arrange(grobs = lapply(list(
               plot_test_mod1 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")), 
               plot_test_mod2 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               test_legend + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm"))
             ),
             set_panel_size,
             width = unit(5, "cm"),
             height = unit(5, "cm")
             ), nrow = 1, ncol = 3),
             width = 21, height = 6.5, units = "cm")}
    
    
    
    if(n_models==1) {
      
      ggsave(filename = file.path(directory, "Train_Models.svg"), dpi = 1000, limitsize = F,
             grid.arrange(grobs = lapply(list(
               plot_train_mod1 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               train_legend + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm"))
             ),
             set_panel_size,
             width = unit(5, "cm"),
             height = unit(5, "cm")
             ), nrow = 1, ncol = 2),
             width = 14, height = 6.5, units = "cm")
      
      ggsave(filename = file.path(directory, "Test_Models.svg"), dpi = 1000, limitsize = F,
             grid.arrange(grobs = lapply(list(
               plot_test_mod1 + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm")),
               test_legend + theme(plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), "mm"))
             ),
             set_panel_size,
             width = unit(5, "cm"),
             height = unit(5, "cm")
             ), nrow = 1, ncol = 2),
             width = 14, height = 6.5, units = "cm")}
    
    
  })
}

