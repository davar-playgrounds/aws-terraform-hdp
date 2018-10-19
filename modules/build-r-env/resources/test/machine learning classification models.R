#=======================================================================================
# Comparison of Classification Machine Learning Algorithms
# Mathias Hansson 06.06.2018
#=======================================================================================

# Libraries
library(caret)
library(readr)
library(doSNOW)
library(doParallel)


# Data
mydata <- read.csv("T3 prediction.csv")

features <- c("GpaVgs",	"gender",	"T1nt",	"T1et",	"T1ot",	"T1at",	"T1ct",	"T1FamilyEdu",	"T1FamilyIncome",	"GpaBI",	"T1NarcissLeader",
              "T1Makt1Orient",	"Mgt_Y.N",	"T3SalaryLevel")
mydata <- mydata[, features]
mydata <- na.omit(mydata)

mydata$Mgt_Y.N <- as.factor(mydata$Mgt_Y.N)

# Split data
set.seed(54321)
indexes <- createDataPartition(mydata$Mgt_Y.N,
                               times = 1,
                               p = 0.7,
                               list = FALSE)

train <- mydata[indexes,]
test <- mydata[-indexes,]

# Examine the proportions of the outcome variable
prop.table(table(mydata$Mgt_Y.N))
prop.table(table(train$Mgt_Y.N))
prop.table(table(test$Mgt_Y.N))


hist <- ggplot(aes(x=classe), data = train) +
  geom_histogram(fill='dark orange') +
  ggtitle('Histogram of Frequency in Training Set') +
  xlab('Prediction variable') +
  ylab('Frequency in Training Data')

#=======================================================================================
# TRAIN MODELS
#=======================================================================================

myModel <- Mgt_Y.N ~ T1nt + T1et + T1ot + T1at + T1ct + T1FamilyEdu + T1FamilyIncome + GpaVgs + GpaBI +
  T1NarcissLeader + T1Makt1Orient

train.control <- trainControl(method = "repeatedcv",
                              number = 10,
                              repeats = 3,
                              search = "grid",
                              verboseIter = TRUE,
                              allowParallel = TRUE)


cl <- makeCluster(detectCores())

registerDoSNOW(cl)


#=======================================================================================
# Trees (rpart2)
# Tuning parameters: maxdepth

tune.grid.rpart2 <- expand.grid(maxdepth = 2:8)

mod_rpart2 <- train(myModel, data=train,
                  method = "rpart2",
                  tuneGrid = tune.grid.rpart2,
                  trControl = train.control)


#=======================================================================================
# Random Forest
# Tuning parameters: .mtry

tune.grid.rf <- expand.grid(.mtry=c(1:15))

mod_rf <- train(myModel, data=train,
                    method = "rf",
                    tuneGrid = tune.grid.rf,
                    trControl = train.control)


#=======================================================================================
# Linear Discriminant Analysis

mod_lda <- train(myModel, data=train,
                method = "lda",
                trControl = train.control)


#=======================================================================================
# Naive Bayes
# Tuning parameters: usekernel, adjust, fL

tune.grid.nb <- expand.grid(usekernel = c(TRUE, FALSE),
                            fL = 0:5,
                            adjust = seq(0, 5, by = 1))

mod_nb <- train(myModel, data=train,
                 method = "nb",
                 tuneGrid = tune.grid.nb,
                 trControl = train.control)


#=======================================================================================
# Extreme Gradient Boosting Trees
# Tuning parameters: eta, nrounds, max_depth, min_child_weight, colsample_bytree; gamma, subsample

tune.grid.xgb <- expand.grid(eta = c(0.05,0.075, 0.1),
                            nrounds = c(50, 75, 100),
                            max_depth = 4:8,
                            min_child_weight = c(2.0, 2.25, 2.5),
                            colsample_bytree = c(0.3, 0.4, 0.5),
                            gamma = 0,
                            subsample = 1)


mod_xgb <- train(myModel,
                  data = train,
                  method = "xgbTree",
                  tuneGrid = tune.grid.xgb,
                  trControl = train.control)

stopCluster(cl)

#=======================================================================================
# Predict models
#=======================================================================================

pred_rpart2 <- predict(mod_rpart2,test)
cm_rpart2 <- confusionMatrix(pred_rpart2,test$Mgt_Y.N)

pred_rf <- predict(mod_rf,test)
cm_rf <- confusionMatrix(pred_rf,test$Mgt_Y.N)

pred_lda <- predict(mod_lda,test)
cm_lda <- confusionMatrix(pred_lda,test$Mgt_Y.N)

pred_nb <- predict(mod_nb,test)
cm_nb <- confusionMatrix(pred_nb,test$Mgt_Y.N)

pred_xgb <- predict(mod_xgb,test)
cm_xgb <- confusionMatrix(pred_xgb,test$Mgt_Y.N)


#=======================================================================================
# Compare models
#=======================================================================================

myResults <- data.frame(Model = c('Trees', 'Random Forest', 'Linear Discriminat',
                                      'Naive Bayes', 'Xtreme Gradient Boosting'),

                            Accuracy = c(cm_rpart2$overall[1], cm_rf$overall[1], cm_lda$overall[1],
                                         cm_nb$overall[1], cm_xgb$overall[1]),

                            AccuracyLower = c(cm_rpart2$overall[3], cm_rf$overall[3], cm_lda$overall[3],
                                              cm_nb$overall[3], cm_xgb$overall[3]),

                            AccuracyUpper =c(cm_rpart2$overall[4], cm_rf$overall[4], cm_lda$overall[4],
                                             cm_nb$overall[4], cm_xgb$overall[4]),

                            TruePositive = c(cm_rpart2$table[1,1], cm_rf$table[1,1], cm_lda$table[1,1],
                                             cm_nb$table[1,1], cm_xgb$table[1,1]),

                            FalseNegative = c(cm_rpart2$table[2,1], cm_rf$table[2,1], cm_lda$table[2,1],
                                              cm_nb$table[2,1], cm_xgb$table[2,1]),

                            FalsePositive = c(cm_rpart2$table[1,2], cm_rf$table[1,2], cm_lda$table[1,2],
                                              cm_nb$table[1,2], cm_xgb$table[1,2]),

                            TrueNegative = c(cm_rpart2$table[2,2], cm_rf$table[2,2], cm_lda$table[2,2],
                                             cm_nb$table[2,2], cm_xgb$table[2,2])

                              )

ggplot(aes(x = Model, y = Accuracy), data = myResults) +
  geom_bar(stat='identity', fill = 'blue') +
  ggtitle('Comparative Accuracy of Models on Cross-Validation Data') +
  xlab('Models') +
  ylab('Overall Accuracy')

# Saving the graph
ggsave("myGraph.png")

# Saving results
write.csv(myResults, 'myResults.csv')
