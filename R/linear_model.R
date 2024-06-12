#' linear_model
#'
#' @param VIs selected vegetation indices
#' @param y Observed variable, e.g. data["yield"]
#' @param experiment Variable with_number experiments, e.g. data["Experiment"]
#' @param train_exp Vector with experiment numbers for train model, e.g. c(1,2,3,4,8,9)
#' @param test_exp Vector with experiment numbers for test model,  e.g. c(5,6,7,8,9)
#' @param model_degree Degree of model (1 or 2),
#' @param metric The selection metric can be RRMSE (put "rrmse" or "RRMSE"), MAPE (put "mape" or "MAPE") or KGE(put "kge" or "KGE"). KGE is particularly useful when the estimate needs to accurately reflect the variability at the observed extremes
#' @param orcutt To readjust model parameters if there is dependence (1 for true, 0 for false)
#' @param treatment Variable_with_treatments, e.g. data["Treatment"]
#' @param cook_distance To eliminate outliers during modeling (1 for true, 0 for false)
#'
#' @return Top five of VIs, models, used metric, observed variable, and predicted variable 
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
linear_model <- function(VIs, y, experiment, treatment, train_exp, test_exp, model_degree, metric = "rrmse", orcutt = 0, cook_distance = 0) {
  
  best_metric_mod1 = Inf; best_model_mod1 = 0; best_train_VI_mod1 = 0; best_coeficients_mod1 = 0; best_bands_mod1 = 0; best_pred_mod1 = 0; best_test_VI_mod1 = 0; output_mod1 = NULL
  best_metric_mod2 = Inf; best_model_mod2 = 0; best_train_VI_mod2 = 0; best_coeficients_mod2 = 0; best_bands_mod2 = 0; best_pred_mod2 = 0; best_test_VI_mod2 = 0; output_mod2 = NULL
  best_metric_mod3 = Inf;best_model_mod3 = 0; best_train_VI_mod3 = 0; best_coeficients_mod3 = 0; best_bands_mod3 = 0; best_pred_mod3 = 0; best_test_VI_mod3 = 0; output_mod3 = NULL
  best_metric_mod4 = Inf;best_model_mod4 = 0; best_train_VI_mod4 = 0; best_coeficients_mod4 = 0; best_bands_mod4 = 0; best_pred_mod4 = 0; best_test_VI_mod4 = 0; output_mod4 = NULL
  best_metric_mod5 = Inf;best_model_mod5 = 0; best_train_VI_mod5 = 0; best_coeficients_mod5 = 0; best_bands_mod5 = 0; best_pred_mod5 = 0; best_test_VI_mod5 = 0; output_mod5 = NULL
  
  for (degree in 1:model_degree) {
    for (a in 2:length(VIs)) {
      VI_i = VIs[,a]
      VI = cbind(experiment,y,VI_i, treatment)
      
      train_VIs = VI[VI[,1] %in% train_exp, ]
      test_VIs = VI[VI[,1] %in% test_exp, ]
      
      
      try ({
        
        train_VIs_ok = train_VIs
        
        if (degree==1) {
          model <- lm (train_VIs[,2]~ I(train_VIs[,3]), data=train_VIs); x2<-0;
          
          if (cook_distance == 1){
            
            outliers <- which(cooks.distance(model) > (4/(nrow(train_VIs)-1)))
            train_VIs_ok <- train_VIs[-outliers, ]
            
            model <- lm (train_VIs_ok[,2]~ I(train_VIs_ok[,3]), data=train_VIs_ok); x2<-0;
          }
          
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
            train_VIs_ok <- train_VIs[-outliers, ]
            
            model <- lm (train_VIs_ok[,2]~ I(train_VIs_ok[,3])+I(train_VIs_ok[,3]^2), data=train_VIs_ok)
          }
          
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
          L <- suppressWarnings(resettest(model, power = 2:3, type = c("fitted", "regressor","princomp"), data = train_VIs_ok))
          L <- suppressWarnings(L$p.value)}else{L = Inf}
        
        I <- suppressWarnings(dwtest(model, alternative="two.sided", data = train_VIs_ok))
        I <- suppressWarnings(I$p.value)
        I <- replace(I,is.na(I),0)
        
        R2 = summarymodel$r.squared
        orcutt_aplied = 0
        
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
              L <- resettest(model, power = 2:3, type = c("fitted", "regressor","princomp"), data = train_VIs_ok)
              L <- L$p.value}else{L = Inf}
            
            I <- dwtest(model, alternative="two.sided", data = train_VIs_ok)
            I <- I$p.value
            I <- replace(I,is.na(I),0)
            
            
            R2 = model$r.squared
            orcutt_aplied = 1

          }
        }
        if (pvalue < 0.05 & N > 0.05 & H > 0.05 & I > 0.05 & L > 0.05){
          if (metric == "rrmse" | metric == "RRMSE" | metric == "rmse" | metric == "RMSE"){
            train_pred <- cbind(train_VIs_ok[,2], x0 + x1 * I(train_VIs_ok[,3]) + x2 * I(train_VIs_ok[,3]^2), train_VIs_ok[,1])
            train_pred <- na.omit(train_pred)
            train_RRMSEs <- NULL
            train_exp = unique(train_pred[,3])
            for (exp in train_exp) {
              train_exp_data = train_pred[train_pred[,3] == exp, , drop = FALSE]
              
              train_RRMSE_exp = sqrt(mean((train_exp_data[,2] - train_exp_data[,1])^2))/mean(train_exp_data[,1])*100
              train_RRMSEs = cbind(train_RRMSEs, train_RRMSE_exp)
            }
            train_metric = max(train_RRMSEs)
            
            test_pred <- cbind(test_VIs[,2], x0 + x1 * I(test_VIs[,3]) + x2 * I(test_VIs[,3]^2), test_VIs[,1])
            test_pred <- na.omit(test_pred)
            test_RRMSEs <- NULL
            test_exp = unique(test_pred[,3])
            for (exp in test_exp) {
              test_exp_data = test_pred[test_pred[,3] == exp, , drop = FALSE]
              test_RRMSE_exp = sqrt(mean((test_exp_data[,2] - test_exp_data[,1])^2))/mean(test_exp_data[,1])*100
              test_RRMSEs = cbind(test_RRMSEs, test_RRMSE_exp)
            }
            test_metric = max(test_RRMSEs)}
          
          
          if (metric == "mape" | metric == "MAPE" | metric == "mae" | metric == "MAE"){
            
            train_pred <- cbind(train_VIs_ok[,2], x0 + x1 * I(train_VIs_ok[,3]) + x2 * I(train_VIs_ok[,3]^2), train_VIs_ok[,1])
            train_pred <- na.omit(train_pred)
            train_MAPEs <- NULL
            train_exp = unique(train_pred[,3])
            for (exp in train_exp) {
              train_exp_data = train_pred[train_pred[,3] == exp, , drop = FALSE]
              train_MAPE_exp = mean(abs((train_exp_data[,1]-train_exp_data[,2])/train_exp_data[,1])) * 100
              train_MAPEs = cbind(train_MAPEs, train_MAPE_exp)
            }
            train_metric = max(train_MAPEs)
            
            test_pred <- cbind(test_VIs[,2], x0 + x1 * I(test_VIs[,3]) + x2 * I(test_VIs[,3]^2), test_VIs[,1])
            test_pred <- na.omit(test_pred)
            test_MAPEs <- NULL
            test_exp = unique(test_pred[,3])
            for (exp in test_exp) {
              test_exp_data = test_pred[test_pred[,3] == exp, , drop = FALSE]
              test_MAPE_exp = mean(abs((test_exp_data[,1]-test_exp_data[,2])/test_exp_data[,1])) * 100
              test_MAPEs = cbind(test_MAPEs, test_MAPE_exp)
            }
            test_metric = max(test_MAPEs)
            
            }
          
          
          
          if (metric == "kge" | metric == "KGE"){
            
            train_pred <- cbind(train_VIs_ok[,2], x0 + x1 * I(train_VIs_ok[,3]) + x2 * I(train_VIs_ok[,3]^2), train_VIs_ok[,1])
            train_pred <- na.omit(train_pred)
            train_KGEs <- NULL
            train_exp = unique(train_pred[,3])
            for (exp in train_exp) {
              train_exp_data = train_pred[train_pred[,3] == exp, , drop = FALSE]
              train_KGE_exp = 1 - sqrt(
                (cor(train_exp_data[,1], train_exp_data[,2]) - 1)^2 + 
                  ((sqrt(mean((train_exp_data[,2] - mean(train_exp_data[,2]))^2))/mean(train_exp_data[,2])) / (sqrt(mean((train_exp_data[,1] - mean(train_exp_data[,1]))^2))/mean(train_exp_data[,1])) - 1)^2 +
                  (mean(train_exp_data[,2]) / mean(train_exp_data[,1]) - 1)^2 )
              train_KGE_exp = 1 - train_KGE_exp
              
              train_KGEs = cbind(train_KGEs, train_KGE_exp)
            }
            train_metric = max(train_KGEs)
            
            test_pred <- cbind(test_VIs[,2], x0 + x1 * I(test_VIs[,3]) + x2 * I(test_VIs[,3]^2), test_VIs[,1])
            test_pred <- na.omit(test_pred)
            test_KGEs <- NULL
            test_exp = unique(test_pred[,3])
            for (exp in test_exp) {
              test_exp_data = test_pred[test_pred[,3] == exp, , drop = FALSE]
              test_KGE_exp = 1 - sqrt(
                (cor(test_exp_data[,1], test_exp_data[,2]) - 1)^2 + 
                  ((sqrt(mean((test_exp_data[,2] - mean(test_exp_data[,2]))^2))/mean(test_exp_data[,2])) / (sqrt(mean((test_exp_data[,1] - mean(test_exp_data[,1]))^2))/mean(test_exp_data[,1])) - 1)^2 +
                  (mean(test_exp_data[,2]) / mean(test_exp_data[,1]) - 1)^2 )
              test_KGE_exp = 1 - test_KGE_exp
              test_KGEs = cbind(test_KGEs, test_KGE_exp)
            }
            test_metric = max(test_KGEs)}
          
          
          best_metric = max(train_metric,test_metric)
          
          residuals = model$residuals
          RMSE <- sqrt(mean(residuals^2))
          
          output_model = c(x0, x1, x2, R2, RMSE, orcutt_aplied)
          
          
          if (best_metric < best_metric_mod1) {best_metric_mod5 = best_metric_mod4; best_metric_mod4 = best_metric_mod3;best_metric_mod3 = best_metric_mod2;best_metric_mod2 = best_metric_mod1; best_metric_mod1 = best_metric
          best_model_mod5 = best_model_mod4; best_train_VI_mod5 = best_train_VI_mod4; best_bands_mod5 = best_bands_mod4;best_test_VI_mod5 = best_test_VI_mod4; output_mod5 = output_mod4
          best_model_mod4 = best_model_mod3; best_train_VI_mod4 = best_train_VI_mod3; best_bands_mod4 = best_bands_mod3;best_test_VI_mod4 = best_test_VI_mod3; output_mod4 = output_mod3
          best_model_mod3 = best_model_mod2; best_train_VI_mod3 = best_train_VI_mod2; best_bands_mod3 = best_bands_mod2;best_test_VI_mod3 = best_test_VI_mod2; output_mod3 = output_mod2
          best_model_mod2 = best_model_mod1; best_train_VI_mod2 = best_train_VI_mod1; best_bands_mod2 = best_bands_mod1;best_test_VI_mod2 = best_test_VI_mod1; output_mod2 = output_mod1
          best_model_mod1 = model; best_train_VI_mod1 = train_VIs; best_test_VI_mod1 = cbind(test_VIs, pred = test_pred[,2]);
          best_bands_mod1 = colnames(VIs[a]); output_mod1 = output_model}
          
          if (best_metric < best_metric_mod2 & best_metric > best_metric_mod1) {best_metric_mod5 = best_metric_mod4; best_metric_mod4 = best_metric_mod3;best_metric_mod3 = best_metric_mod2;best_metric_mod2 = best_metric
          best_model_mod5 = best_model_mod4; best_train_VI_mod5 = best_train_VI_mod4; best_bands_mod5 = best_bands_mod4;best_test_VI_mod5 = best_test_VI_mod4; output_mod5 = output_mod4
          best_model_mod4 = best_model_mod3; best_train_VI_mod4 = best_train_VI_mod3; best_bands_mod4 = best_bands_mod3;best_test_VI_mod4 = best_test_VI_mod3; output_mod4 = output_mod3
          best_model_mod3 = best_model_mod2; best_train_VI_mod3 = best_train_VI_mod2; best_bands_mod3 = best_bands_mod2;best_test_VI_mod3 = best_test_VI_mod2; output_mod3 = output_mod2
          best_model_mod2 = model; best_train_VI_mod2 = train_VIs; best_test_VI_mod2 = cbind(test_VIs, pred = test_pred[,2]);
          best_bands_mod2 = colnames(VIs[a]); output_mod2 = output_model}
          
          if (best_metric < best_metric_mod3 & best_metric > best_metric_mod1 & best_metric > best_metric_mod2) {best_metric_mod5 = best_metric_mod4; best_metric_mod4 = best_metric_mod3;best_metric_mod3 = best_metric
          best_model_mod5 = best_model_mod4; best_train_VI_mod5 = best_train_VI_mod4; best_bands_mod5 = best_bands_mod4;best_test_VI_mod5 = best_test_VI_mod4; output_mod5 = output_mod4
          best_model_mod4 = best_model_mod3; best_train_VI_mod4 = best_train_VI_mod3; best_bands_mod4 = best_bands_mod3;best_test_VI_mod4 = best_test_VI_mod3; output_mod4 = output_mod3
          best_model_mod3 = model; best_train_VI_mod3 = train_VIs; best_test_VI_mod3 = cbind(test_VIs, pred = test_pred[,2]);
          best_bands_mod3 = colnames(VIs[a]); output_mod3 = output_model} 
          
          if (best_metric < best_metric_mod4 & best_metric > best_metric_mod1 & best_metric > best_metric_mod2 & best_metric > best_metric_mod3) {best_metric_mod5 = best_metric_mod4; best_metric_mod4 = best_metric
          best_model_mod5 = best_model_mod4; best_train_VI_mod5 = best_train_VI_mod4; best_bands_mod5 = best_bands_mod4;best_test_VI_mod5 = best_test_VI_mod4; output_mod5 = output_mod4
          best_model_mod4 = model; best_train_VI_mod4 = train_VIs; best_test_VI_mod4 = cbind(test_VIs, pred = test_pred[,2]);
          best_bands_mod4 = colnames(VIs[a]); output_mod4 = output_model}
          
          if (best_metric < best_metric_mod5 & best_metric > best_metric_mod1 & best_metric > best_metric_mod2 & best_metric > best_metric_mod3 & best_metric > best_metric_mod3 & best_metric > best_metric_mod4) {best_metric_mod5 = best_metric
          best_model_mod5 = model; best_train_VI_mod5 = train_VIs; best_test_VI_mod5 = cbind(test_VIs,pred = test_pred[,2]);
          best_bands_mod5 = colnames(VIs[a]); output_mod5 = output_model}
        } 
        
      }, silent = TRUE)
      
    }                
  }
  
  return(list(
    best_bands_mod1 = best_bands_mod1,
    best_metric_mod1 = best_metric_mod1,
    best_model_mod1 = best_model_mod1,
    best_train_VI_mod1 = best_train_VI_mod1, 
    best_test_VI_mod1 = best_test_VI_mod1,
    output_mod1 = output_mod1,
    
    best_bands_mod2 = best_bands_mod2,
    best_metric_mod2 = best_metric_mod2,
    best_model_mod2 = best_model_mod2,
    best_train_VI_mod2 = best_train_VI_mod2, 
    best_test_VI_mod2 = best_test_VI_mod2,
    output_mod2 = output_mod2,
    
    best_bands_mod3 = best_bands_mod3,
    best_metric_mod3 = best_metric_mod3,
    best_model_mod3 = best_model_mod3,
    best_train_VI_mod3 = best_train_VI_mod3, 
    best_test_VI_mod3 = best_test_VI_mod3,
    output_mod3 = output_mod3,
    
    best_bands_mod4 = best_bands_mod4,
    best_metric_mod4 = best_metric_mod4,
    best_model_mod4 = best_model_mod4,
    best_train_VI_mod4 = best_train_VI_mod4, 
    best_test_VI_mod4 = best_test_VI_mod4,
    output_mod4 = output_mod4,
    
    best_bands_mod5 = best_bands_mod5,
    best_metric_mod5 = best_metric_mod5,     
    best_model_mod5 = best_model_mod5,
    best_train_VI_mod5 = best_train_VI_mod5, 
    best_test_VI_mod5 = best_test_VI_mod5,
    output_mod5 = output_mod5
  ))
}
