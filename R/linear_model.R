#' linear_model
#'
#' @param VIs selected vegetation indices
#' @param y Observed variable
#' @param experiment Variable_with_number_experiments,  
#' @param train_exp Vector with experiment numbers for train model, 
#' @param test_exp Vector with experiment numbers for test model,  
#' @param model_degree Degree of model (1 or 2),  
#' @param orcutt To readjust model parameters if there is dependence (1 for true, 0 for false)
#' @param cook_distance To eliminate outliers during modeling (1 for true, 0 for false)
#'
#' @return Top five of VIs, models, RRMSE, observed variable, and predicted variable 
#' 
#' @import stats
#' @import lmtest
#' @import nortest
#' @import orcutt
#' 
#' @export
#'
#' @examples
#' maize_data = SPARK::maize
#' V10 = maize_data[maize_data$Stage == "V10", ]
#' bands_names <- c("B2", "B3", "B4", "B5", "B6", "B7", "B8", "B8A", "B11", "B12")
#' 
#' # Combining spectral bands 
#' NNI_V10_VIs = optical_indices(
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
#'   train_exp = c(1, 2, 3, 4, 10, 11),   
#'   test_exp = c(5, 6, 7, 8, 9),  
#'   model_degree = 2, 
#'   orcutt = 1, 
#'     cook_distance = 1
#' )
#'   
linear_model <- function(VIs, y, experiment, train_exp, test_exp, model_degree, orcutt = 0, cook_distance = 0) {
  
  best_RRMSE_mod1 = Inf; best_model_mod1 = 0; best_train_VI_mod1 = 0; best_coeficients_mod1 = 0; best_bands_mod1 = 0; best_pred_mod1 = 0; best_test_VI_mod1 = 0
  best_RRMSE_mod2 = Inf; best_model_mod2 = 0; best_train_VI_mod2 = 0; best_coeficients_mod2 = 0; best_bands_mod2 = 0; best_pred_mod2 = 0; best_test_VI_mod2 = 0
  best_RRMSE_mod3 = Inf;best_model_mod3 = 0; best_train_VI_mod3 = 0; best_coeficients_mod3 = 0; best_bands_mod3 = 0; best_pred_mod3 = 0; best_test_VI_mod3 = 0
  best_RRMSE_mod4 = Inf;best_model_mod4 = 0; best_train_VI_mod4 = 0; best_coeficients_mod4 = 0; best_bands_mod4 = 0; best_pred_mod4 = 0; best_test_VI_mod4 = 0
  best_RRMSE_mod5 = Inf;best_model_mod5 = 0; best_train_VI_mod5 = 0; best_coeficients_mod5 = 0; best_bands_mod5 = 0; best_pred_mod5 = 0; best_test_VI_mod5 = 0
  for (degree in 1:model_degree) {
    for (a in 2:length(VIs)) {
      VI_i = VIs[,a]
      VI = cbind(experiment,y,VI_i)
      
      train_VIs = VI[VI[,1] %in% train_exp, ]
      test_VIs = VI[VI[,1] %in% test_exp, ]
      
      
      try ({
        
        if (degree==1) {
          model <- lm (train_VIs[,2]~ I(train_VIs[,3]), data=train_VIs); x2<-0;
          
          if (cook_distance == 1){
            
            outliers <- which(cooks.distance(model) > (4/(nrow(train_VIs)-1)))
            train_VIs <- train_VIs[-outliers, ]
            
            model <- lm (train_VIs[,2]~ I(train_VIs[,3]), data=train_VIs); x2<-0;}
          
          summarymodel      <- summary(model)
          summarymodel      <- na.omit(summarymodel)
          pvalue_model      <- c(summarymodel$coefficients[2,4]);
          pvalue            <- na.omit(pvalue_model)
          
          coeficients_model <- c(coefficients (model,useNA = 0))
          coeficients_model[is.na(coeficients_model)] <- 0
          x0 <-  coeficients_model[1]
          x1 <-  coeficients_model[2]
          x0[!is.finite(x0)] <- 0
          x1[!is.finite(x1)] <- 0
        } else {
          model <- lm (train_VIs[,2]~ I(train_VIs[,3])+I(train_VIs[,3]^2), data=train_VIs)
          
          if (cook_distance == 1){
            
            outliers <- which(cooks.distance(model) > (4/(nrow(train_VIs)-1)))
            train_VIs <- train_VIs[-outliers, ]
            
            model <- lm (train_VIs[,2]~ I(train_VIs[,3])+I(train_VIs[,3]^2), data=train_VIs)}
        
        summarymodel      <- summary(model)
        summarymodel      <- na.omit(summarymodel)
        pvalue_model      <- suppressWarnings(c(summarymodel$coefficients[2:3,4]))
        pvalue_model      <- suppressWarnings(na.omit(pvalue_model))
        pvalue            <- suppressWarnings(max(pvalue_model))
        
        coeficients_model <- c(coefficients (model,useNA = 0))
        coeficients_model[is.na(coeficients_model)] <- 0
        x0 <-  coeficients_model[1]
        x1 <-  coeficients_model[2]
        x2 <-  coeficients_model[3]
        x0[!is.finite(x0)] <- 0
        x1[!is.finite(x1)] <- 0
        x2[!is.finite(x2)] <- 0
        }
        
        
        N = lillie.test(model$residuals)
        N = N$p.value 
        
        H = bptest(model)
        H = H$p.value 
        
        if (degree==1) {
          L <- suppressWarnings(resettest(model, power = 2:3, type = c("fitted", "regressor","princomp"), data = train_VIs))
          L <- suppressWarnings(L$p.value)}else{L = Inf}
        
        I <- suppressWarnings(dwtest(model, alternative="two.sided", data = train_VIs))
        I <- suppressWarnings(I$p.value)
        I <- replace(I,is.na(I),0)
        
        if (orcutt == 1) {
          if (N < 0.05 | H < 0.05 | L < 0.05 | I < 0.05) {
            model = cochrane.orcutt(model)
            if (degree==1) {
              summarymodel      <- summary(model)
              summarymodel      <- na.omit(summarymodel)
              pvalue_model      <- c(summarymodel$coefficients[2,4]);
              pvalue            <- na.omit(pvalue_model)
              
              coeficients_model <- c(coefficients (model,useNA = 0))
              coeficients_model[is.na(coeficients_model)] <- 0
              x0 <-  coeficients_model[1]
              x1 <-  coeficients_model[2]
              x0[!is.finite(x0)] <- 0
              x1[!is.finite(x1)] <- 0
              x2<-0
            } else {
              summarymodel      <- summary(model)
              summarymodel      <- na.omit(summarymodel)
              pvalue_model      <- c(summarymodel$coefficients[2:3,4])
              pvalue_model      <- na.omit(pvalue_model)
              pvalue            <- max(pvalue_model)
              
              coeficients_model <- c(coefficients (model,useNA = 0))
              coeficients_model[is.na(coeficients_model)] <- 0
              x0 <-  coeficients_model[1]
              x1 <-  coeficients_model[2]
              x2 <-  coeficients_model[3]
              x0[!is.finite(x0)] <- 0
              x1[!is.finite(x1)] <- 0
              x2[!is.finite(x2)] <- 0
            }
            
            N = lillie.test(model$residuals)
            N = N$p.value 
            H = bptest(model)
            H = H$p.value 
            
            if (degree==1) {
              L <- resettest(model, power = 2:3, type = c("fitted", "regressor","princomp"), data = train_VIs)
              L <- L$p.value}else{L = Inf}
            
            I <- dwtest(model, alternative="two.sided", data = train_VIs)
            I <- I$p.value
            I <- replace(I,is.na(I),0)
          }
        }
        if (pvalue < 0.05 & N > 0.05 & H > 0.05 & I > 0.05 & L > 0.05){
          train_pred <- cbind(train_VIs[,2], x0 + x1 * I(train_VIs[,3]) + x2 * I(train_VIs[,3]^2), train_VIs[,1])
          train_pred <- na.omit(train_pred)
          train_RRMSEs <- NULL
          train_exp = unique(train_pred[,3])
          for (exp in train_exp) {
            train_exp_data = train_pred[train_pred[,3] == exp, , drop = FALSE]
            
            train_RRMSE_exp = sqrt(mean((train_exp_data[,2] - train_exp_data[,1])^2))/mean(train_exp_data[,1])*100
            train_RRMSEs = cbind(train_RRMSEs, train_RRMSE_exp)
          }
          train_RRMSE = max(train_RRMSEs)
          
          test_pred <- cbind(test_VIs[,2], x0 + x1 * I(test_VIs[,3]) + x2 * I(test_VIs[,3]^2), test_VIs[,1])
          test_pred <- na.omit(test_pred)
          test_RRMSEs <- NULL
          test_exp = unique(test_pred[,3])
          for (exp in test_exp) {
            test_exp_data = test_pred[test_pred[,3] == exp, , drop = FALSE]
            test_RRMSE_exp = sqrt(mean((test_exp_data[,2] - test_exp_data[,1])^2))/mean(test_exp_data[,1])*100
            test_RRMSEs = cbind(test_RRMSEs, test_RRMSE_exp)
          }
          test_RRMSE = max(test_RRMSEs)
          
          RRMSE = max(train_RRMSE,test_RRMSE)
          
          # selecting the five best models
          if (RRMSE < best_RRMSE_mod1) {best_RRMSE_mod5 = best_RRMSE_mod4; best_RRMSE_mod4 = best_RRMSE_mod3;best_RRMSE_mod3 = best_RRMSE_mod2;best_RRMSE_mod2 = best_RRMSE_mod1; best_RRMSE_mod1 = RRMSE
          best_model_mod5 = best_model_mod4; best_train_VI_mod5 = best_train_VI_mod4; best_bands_mod5 = best_bands_mod4;best_test_VI_mod5 = best_test_VI_mod4;
          best_model_mod4 = best_model_mod3; best_train_VI_mod4 = best_train_VI_mod3; best_bands_mod4 = best_bands_mod3;best_test_VI_mod4 = best_test_VI_mod3;
          best_model_mod3 = best_model_mod2; best_train_VI_mod3 = best_train_VI_mod2; best_bands_mod3 = best_bands_mod2;best_test_VI_mod3 = best_test_VI_mod2;
          best_model_mod2 = best_model_mod1; best_train_VI_mod2 = best_train_VI_mod1; best_bands_mod2 = best_bands_mod1;best_test_VI_mod2 = best_test_VI_mod1;
          best_model_mod1 = model; best_train_VI_mod1 = train_VIs; best_test_VI_mod1 = cbind(test_VIs, pred = test_pred[,2]);
          best_bands_mod1 = colnames(VIs[a])}
          
          if (RRMSE < best_RRMSE_mod2 & RRMSE > best_RRMSE_mod1) {best_RRMSE_mod5 = best_RRMSE_mod4; best_RRMSE_mod4 = best_RRMSE_mod3;best_RRMSE_mod3 = best_RRMSE_mod2;best_RRMSE_mod2 = RRMSE
          best_model_mod5 = best_model_mod4; best_train_VI_mod5 = best_train_VI_mod4; best_bands_mod5 = best_bands_mod4;best_test_VI_mod5 = best_test_VI_mod4;
          best_model_mod4 = best_model_mod3; best_train_VI_mod4 = best_train_VI_mod3; best_bands_mod4 = best_bands_mod3;best_test_VI_mod4 = best_test_VI_mod3;
          best_model_mod3 = best_model_mod2; best_train_VI_mod3 = best_train_VI_mod2; best_bands_mod3 = best_bands_mod2;best_test_VI_mod3 = best_test_VI_mod2;
          best_model_mod2 = model; best_train_VI_mod2 = train_VIs; best_test_VI_mod2 = cbind(test_VIs, pred = test_pred[,2]);
          best_bands_mod2 = colnames(VIs[a])}
          
          if (RRMSE < best_RRMSE_mod3 & RRMSE > best_RRMSE_mod1 & RRMSE > best_RRMSE_mod2) {best_RRMSE_mod5 = best_RRMSE_mod4; best_RRMSE_mod4 = best_RRMSE_mod3;best_RRMSE_mod3 = RRMSE
          best_model_mod5 = best_model_mod4; best_train_VI_mod5 = best_train_VI_mod4; best_bands_mod5 = best_bands_mod4;best_test_VI_mod5 = best_test_VI_mod4;
          best_model_mod4 = best_model_mod3; best_train_VI_mod4 = best_train_VI_mod3; best_bands_mod4 = best_bands_mod3;best_test_VI_mod4 = best_test_VI_mod3;
          best_model_mod3 = model; best_train_VI_mod3 = train_VIs; best_test_VI_mod3 = cbind(test_VIs, pred = test_pred[,2]);
          best_bands_mod3 = colnames(VIs[a])} 
          
          if (RRMSE < best_RRMSE_mod4 & RRMSE > best_RRMSE_mod1 & RRMSE > best_RRMSE_mod2 & RRMSE > best_RRMSE_mod3) {best_RRMSE_mod5 = best_RRMSE_mod4; best_RRMSE_mod4 = RRMSE
          best_model_mod5 = best_model_mod4; best_train_VI_mod5 = best_train_VI_mod4; best_bands_mod5 = best_bands_mod4;best_test_VI_mod5 = best_test_VI_mod4;
          best_model_mod4 = model; best_train_VI_mod4 = train_VIs; best_test_VI_mod4 = cbind(test_VIs, pred = test_pred[,2]);
          best_bands_mod4 = colnames(VIs[a])}
          
          if (RRMSE < best_RRMSE_mod5 & RRMSE > best_RRMSE_mod1 & RRMSE > best_RRMSE_mod2 & RRMSE > best_RRMSE_mod3 & RRMSE > best_RRMSE_mod3 & RRMSE > best_RRMSE_mod4) {best_RRMSE_mod5 = RRMSE
          best_model_mod5 = model; best_train_VI_mod5 = train_VIs; best_test_VI_mod5 = cbind(test_VIs,pred = test_pred[,2]);
          best_bands_mod5 = colnames(VIs[a])}
        } 
        
      }, silent = TRUE)
      
    }                
  }
  
  return(list(
    best_bands_mod1 = best_bands_mod1,
    best_RRMSE_mod1 = best_RRMSE_mod1,
    best_model_mod1 = summary(best_model_mod1),
    best_train_VI_mod1 = best_train_VI_mod1, 
    best_test_VI_mod1 = best_test_VI_mod1,
    
    best_bands_mod2 = best_bands_mod2,
    best_RRMSE_mod2 = best_RRMSE_mod2,
    best_model_mod2 = summary(best_model_mod2),
    best_train_VI_mod2 = best_train_VI_mod2, 
    best_test_VI_mod2 = best_test_VI_mod2,
    
    best_bands_mod3 = best_bands_mod3,
    best_RRMSE_mod3 = best_RRMSE_mod3,
    best_model_mod3 = summary(best_model_mod3),
    best_train_VI_mod3 = best_train_VI_mod3, 
    best_test_VI_mod3 = best_test_VI_mod3,
    
    best_bands_mod4 = best_bands_mod4,
    best_RRMSE_mod4 = best_RRMSE_mod4,
    best_model_mod4 = summary(best_model_mod4),
    best_train_VI_mod4 = best_train_VI_mod4, 
    best_test_VI_mod4 = best_test_VI_mod4,
    
    best_bands_mod5 = best_bands_mod5,
    best_RRMSE_mod5 = best_RRMSE_mod5,     
    best_model_mod5 = summary(best_model_mod5),
    best_train_VI_mod5 = best_train_VI_mod5, 
    best_test_VI_mod5 = best_test_VI_mod5
  ))
}
