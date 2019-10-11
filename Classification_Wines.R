# library loads add-on packages
library(rpart)
library(rpart.plot)
library(ggplot2)
library(randomForest)


#Read the file
df <- read.csv('~/Downloads/wine_dataset.csv')

#Check the data and variable types
head(df)
str(df)

#Checking the summary for the data
summary(df)

# Outputs the name of the columns which consists of NA values.
for (cols in colnames(df)) {
  cnt <- nrow(df[is.na(df[, cols]), ])
  if (cnt > 0) {
    print (cols)
  }
}

#We see that there are no null columns in our dataset
nrow(df)

#Discard Duplicate Values (if any)
df <- group_by(df, fixed_acidity,volatile_acidity,citric_acid,residual_sugar,chlorides,
                 free_sulfur_dioxide,total_sulfur_dioxide,density,pH,sulphates,alcohol,quality,style)
filter(df, n() == 1)

df <- as.data.frame(df)

#Add a new column for total acidity
df <- df %>% mutate(total_acidity = fixed_acidity + volatile_acidity+citric_acid)

#Add a new column for proportion of free sulfur dioxide to total sulfur dioxide
df <- df %>% mutate(proportion_free_SO2 = free_sulfur_dioxide/total_sulfur_dioxide)

#Add a new column to categorize quality into not good, good and excellent
df <- mutate(df, quality_category = ifelse(quality>=0 & quality<=4,"Not Good",
                                               ifelse(quality>=5 & quality <=6,"Good",
                                                      ifelse(quality>=7,"Excellent","N/A"))))

#Let's remove columns that won't be too useful for our predictions
df<-subset(df,select=-c(fixed_acidity,volatile_acidity,free_sulfur_dioxide,
                            total_sulfur_dioxide,quality,citric_acid))


#Decision Tree
df$style <- factor(df$style, levels=c('red','white'))
# Define seed for random number generator
set.seed(1234)
# sample takes a random sample of the specified size from the elements of x
train <- sample(nrow(df), 0.7*nrow(df))

# Define training data frame using random sample of observations
df.train <- df[train,]
# Define validation data frame using all observations not in training data frame
df.validate <- df[-train,]

# CUSTOMIZE DATA: The categorical dependent variable is called style
table(df.train$style)
table(df.validate$style)

# Define seed for random number generator
set.seed(1234)

# Fit a recursive partitioning model
# CUSTOMIZE DATA: the first parameter target specifies the categorical dependent variable 
# CUSTOMIZE DATA: The categorical dependent variable is called target
dtree <- rpart(style ~ ., data=df.train, method="class",
               parms=list(split="information"))

# Summarize the decision tree including decision nodes and leaf nodes
# The decision tree nodes are described row by row, then left to right
summary(dtree)

# Display decision tree.  The true values follow the left branches.
rpart.plot(dtree)

# Display decision tree complexity parameter table which is a matrix of information on the optimal prunings based on a complexity parameter
# Identify CP that corresponds to the lowest xerror
dtree$cptable

# Plot complexity parameter table
plotcp(dtree)

# Determine CP that corresponds to the lowest xerror
# Get index of CP with lowest xerror
opt <- which.min(dtree$cptable[,"xerror"])
# get its CP value
cp <- dtree$cptable[opt, "CP"]

# Prune decision tree to decrease overfitting
dtree.pruned <- prune(dtree, cp)

# Display pruned decision tree.  The true values follow the left branches.
rpart.plot(dtree.pruned)

# class displays the object class
class(dtree$cptable)

# names displays the names of an object
names(dtree)

# Determine proportion of categorical dependent variable
# CUSTOMIZE DATA: The categorical dependent variable is called target
table(df.train$style)/nrow(df.train)

# prp plots an rpart model
prp(dtree.pruned, type=2, extra=104, fallen.leaves=TRUE, main="Decision Tree")

# predict evaluates the application of a model to a data frame
dtree.pred <- predict(dtree.pruned, df.validate, type="class")
# define classification matrix
# CUSTOMIZE DATA: The categorical dependent variable is called target
dtree.perf <- table(df.validate$style, dtree.pred, dnn=c("Actual", "Predicted"))
dtree.perf

# Random Forest

# Define seed for random number generator
set.seed(1234)
# Fit a random forest model
# CUSTOMIZE DATA: The categorical dependent variable is called target
forest <- randomForest(style ~ ., data=df.train,
                       na.action=na.roughfix,
                       importance=TRUE)

# Display a summary for a random forest model
forest

# Display variable importance measures for a random forest model
importance(forest, type=2)

# predict evaluates the application of a model to a data frame
forest.pred <- predict(forest, df.validate)
# define classification matrix
# CUSTOMIZE DATA: The categorical dependent variable is called target
forest.perf <- table(df.validate$style, forest.pred,
                     dnn=c("Actual", "Predicted"))
forest.perf


#VISUALIZATIONS OF OUR VARIABLES THAT AFFECT OUR CLASSIFICATION
#Visualisation for Chlorides for each Wine Style
ggplot(df,aes(chlorides,fill=style,alpha=0.3)) +
  geom_density(kernel="gaussian")+ 
  ggtitle("Chlorides by Wine Style") +
  theme(plot.title = element_text(color= "dodgerblue4", size = 14,face="bold"))

#Visualisation between Residual Sugar and Total Acidity
ggplot(df,aes(x=total_acidity,y=residual_sugar,color=style)) +
  geom_point(size=2)+facet_wrap(~style) +
  ggtitle("Residual Sugar by Total Acidity") +
  theme(plot.title = element_text(color= "dodgerblue4", size = 14,face="bold"))

#Visualisation between Alcohol and Density
ggplot(df,aes(x=alcohol,y=density,color=style,alpha=0.3)) +
  geom_point(size=2)+facet_wrap(~style) +
  ggtitle("Alcohol and Density") +
  theme(plot.title = element_text(color= "dodgerblue4", size = 14,face="bold"))

#Visualisation between Proportion of free SO2 and Alcohol
ggplot(df,aes(x=alcohol,y=proportion_free_SO2,color=style)) +
  geom_point(size=2)+facet_wrap(~style) +
  ggtitle("Proportion of free SO2 by Alcohol") +
  theme(plot.title = element_text(color= "dodgerblue4", size = 14,face="bold"))

#VISUALIZATIONS FOR QUALITY OF WINE

#Visualisation between Chlorides and Quality Category
ggplot(df,aes(x=quality_category,y=chlorides,color=quality_category)) +
  geom_boxplot()+facet_wrap(~style)+ 
  ggtitle("Total Acidity by Quality Category") +
  theme(plot.title = element_text(color= "dodgerblue4", size = 14,face="bold"))

#Visualisation between Alcohol and Quality Category
ggplot(df,aes(x=quality_category,y=alcohol,color=quality_category)) +
  geom_boxplot()+facet_wrap(~style)+ 
  ggtitle("Alcohol by Quality Category") +
  theme(plot.title = element_text(color= "dodgerblue4", size = 14,face="bold"))

#Visualisation between Density and Quality Category
ggplot(df,aes(x=quality_category,y=density,color=quality_category)) +
  geom_boxplot()+facet_wrap(~style)+ 
  ggtitle("Density by Quality Category") +
  theme(plot.title = element_text(color= "dodgerblue4", size = 14,face="bold"))

#Visualisation between Residual Sugar by Quality Category
ggplot(df,aes(x=quality_category,y=residual_sugar,color=quality_category)) +
  geom_bar(stat="identity")+facet_wrap(~style)+ 
  ggtitle("Residual Sugar by Quality Category") +
  theme(plot.title = element_text(color= "dodgerblue4", size = 14,face="bold"))

#Visualisation between Total Acidity by Quality Category
ggplot(df,aes(x=quality_category,y=total_acidity,color=quality_category)) +
  geom_boxplot()+facet_wrap(~style)+ 
  ggtitle("Total Acidity by Quality Category") +
  theme(plot.title = element_text(color= "dodgerblue4", size = 14,face="bold"))



