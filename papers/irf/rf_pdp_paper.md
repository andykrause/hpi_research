---
title: "A machine learning approach to House Price Indexes"
author: 
 Andy Krause
 -- Zillow Group
 -- Seattle, WA
date: "2019-11-13"
output: 
  html_document:
      keep_md: yes
header-includes:
  - \usepackage{setspace}\doublespacing
editor_options: 
  chunk_output_type: console
---





### Abstract

The approaches for generating house price indexes are almost exclusively found in the realm of traditional statistics: ranging from simple median calculation to complex multiple regression formats. This paper presents a machine learning approach -- a random forest model -- combined with a model-agnostic interpretability method to derive home price indexes.  Additionally, I present a framework (and associated software package, `hpiR`) for evaluating and comparing the quality of house price indexes.

## Introduction

Traditionally, house price indexes have been generated through highly interpretable (statistical) modeling approaches such as measures of changes in median value or multiple regression models.  Both the repeat sales and the hedonic approach -- the two of the three most common approaches (Hill 2012; MacGuire et al 2013) -- are regression models.  Common statistical models are a good fit for this task as the coefficient estimates are easily convertable into standardized indexes. In short, house price index generation is not viewed as a prediction problem, but rather a scientific endeavor in which the attribution of the effects of time on market movements is sought. As a result, many of the rapidly growing set of machine learning algorithms -- e.g. support vector machines, random forests and neural networks -- have not been used in the production of price indexes due to the fact that they do not directly or easily attribute price impacts to the variables or features in the model. With the rise of interpretability methods, these 'black-box' models can be made more explainable and suitable for a more diverse set of tasks. 

This paper highlights the use of partial dependence -- a model-agnostic interpretability method (Molnar 2019) -- to generate house price indexes.  One of the major appeals of using a model-agnostic approach is that any underlying model class could be used on the data.  In this work, I use a random forest, one of the more common and intuitive machine learning models.  However, this is only for convenience sake, as a neural network could just as easily have been used. Along with an explanation of the method and examples, the results from this application of a model-agnostic interpretability method are compared to the more traditional repeat sales and hedonic model approaches. 

The remainder of this work is organized as follows:  Section two provides a brief literature review. Next, I discuss the interpretable random forest (IRF) approach to creating a house price index and provide details using the `hpiR` dataset: Seattle, WA homes sales in the 2010 through 2016 period. In section four, the random forest method is compared to more traditional models across three metrics -- volatility, revision and accuracy. Finally, I conclude with a discussion and suggestions for future work. 

Data used in the examples and the comparisons are from the `hpiR` open source R package. In the comparative analyses I provide extra details on the functionality and lexicon of the `hpiR` package to assist in the reproducibility of this work. More details on options to fully reproduce this work (as well as download and use the entire `hpiR` package) can be found can be found at: [www.github.com/andykrause/ml_hpi_research](https://www.github.com/andykrause/ml_hpi_research).

## Previous Work

Since the seminal Bailey et al. (1963) study there has been considerable and sustained research effort put into comparing and improving competing methods for generating house price indexes.  Published work in this subfield of housing economics is generally focused on one or more of four aims: 1) Comparison of model differences (Case et al 1991; Crone & Voith 1992; Meese and Wallace 1997; Nagaraja et al 2014; Bourassa et al 2016); 2) Identification and correction of estimation issues or problems (Abraham & Schauman 1991; Haurin & Henderschott 1991; Clapp et al 1992; Case et al 1997;  Steele & Goy 1997; Gatzlaff & Haurin 1997, 1998; Munneke & Slade 2000); 3) Creation of local or submarket indexes (Goodman 1978; Hill et al 1997; Gunterman et al 2016; Bogin et al 2019); and 4) Development of a new model or estimator (Case & Quigley 1991; Quigley 1995; Hill et al 1997; Englund et al. 1998, McMillen 2012; Bokhari & Geltner 2012; Bourassa et al 2016).  Readers interested in a broad coverage of approaches to and issues with existing house price index methods are direct to the "Handbook on Residential Property Prices Indices (Eurostat 2013).

### Random Forests

The term 'machine learning' often conjures the pejorative term 'black box'.  Or in other words, a model for which predictions are given but for reasons unknown and, perhaps, unknowable, by humans.  For use cases where a predicted outcome or response, be it a classfication or a regression problem, in it itself is all that is required the 'black box'-ness may not be an issue.  However, in other cases, where model biases need to be diagnosed and/or individual feature contributions are a key concern of the research or model application -- such as constructing house price indexes -- machine learning models often need to be extended with interpretabilty methods.  

There are many options for the choice of machine learning model. This paper uses random forests (Breiman 2001) as an example as they are a common modeling approach in the machine learning literature and industry. Forests create a set of many decision trees, each based on a random set of the data with each partition limited to a random set of the variables in the data.  By combining predictions across the many trees, a final model prediction (or classification) is created.

Random forests, essentially bootstrapped submarketing routines, also have a natural link to real estate valuation via the selection of small subsets of like homes to drive predictions. Interestingly, random forests have been little used in academic real estate studies (see Mayer et al 2019 for an exception) and not at all in house price index creation. Much of the reason for this dearth is that random forests are somewhat of a black box in that they do not directly create coefficient estimates as more traditional statistical models do and, therefore, do not offer a direct approach to create price indexes. A random forest model will provide a predicted value but no direct explanation of how that prediction was generated. In short, they are not inherently interpretable.

#### Interpretabilty Methods

As the use of machine learning models has grown, so too have methods to help raise the interpretability of these approaches.  One such set of these enhancements are termed 'model-agnostic interpretability methods' (Molnar 2019). These post-model approaches can be applied to any learner or model in order to provide a specific enhancement or extension in the overal interpretability of the model.  Model agnostic methods can fall into a number of types or classes, some of which have varying aims.  Some of the most common approaches are: 

* **Simulated or counterfactual scoring**. In these approaches, machine learning models compare scored (predicted) values of counterfactual observations across a given variable while holding all others constant in order to estimate the likely marginal impact of the variable in question.  Individual conditional expectations (ICE) and partial dependence (PD) are standard examples of this approach (Friedman 2001).  Accumlated local effects (ALE) can also be used when extensive correlations exist in the independent variables (Apley 2016). Often a goal of these approaches is to understand marginal contribution of one or more features towards the predicted value. 

* **Global and local surrogates**.  Surrogate interpretable models that roughly approximate a black box model can provide human-interpretable explanations of black box models.  These surrogate models can be global -- spanning all observations -- or local -- confined to a small subset of the data, such as location.  The locally interpretable model explaination (LIME) method proposed by Ribiero et al (2016) is the most widely known local surrogate approach.  Local and global surrogates are usually used to understand the prediction of one or a few individual instances. 

* **Game Theory (Shapley Values)**. A game theory or bargaining approach where variables or features (the players) compete to determine the optimal payout (coefficient) for their contributions to each observed price (Molner 2019).  Shapley values, like counterfactual scoring, seek to measure marginal contribution of specific features. 

* **Feature importance via permutation**. Judging the importance of a particular feature or variable within a black box model can be estimated via a permutation method (Gregorutti et al 2017).  This approach works by estimating a baseline model with all variables as is. For each feature, permute or randomize the data for that feature and re-estimate the model.  Do this for all features one at a time and measure the relative degradation of model performance when each feature is randomized.  This provides a (relative) measure of which variables or features are the most important in the model.  Feature importance measures are used to identify which features is the model provided the biggest (relative) gains in model performance.   

In the paper, I will use measures of individual conditional expectations and partial dependence to extract interpretable insights on real estate market behavior over time. I have chosen this approach for two primary reasons.  First, this approach conceptually mimics the basic questions that drive real estate price indexes, namely, what would this property/house have sold for at given interval over time. In fact, it does exactly that by simulating a home sale for a given property at every time period in the study (individual condition expectation) and then combinines those changes in price over time across all properties (partial dependence). 

Second, ICEs and PD are one of the easiest of the above methods to compute. Partial dependence calculations are known to be potentally biased when the variable of interest is highly correlated with other independent variables. However, for the purposes of house price index generation the variable of interest -- time of sale -- is generally highly orthogonal to other control variables making partial dependence an acceptable approach.  

Partial dependence, and the individual conditional expectations that drive them, can be used to extract the marginal impact of each time period, conditionally, on the reponse or dependent variable: house prices in this case.  The resulting shape of the partial dependency -- linear, monotonic, sinusonoidal, spline-like, etc. -- is entirely depending on the underlying model being evaluated. Conceptually, an individual conditional expectation plot takes a single observations, $X_i$, and for one of the feature or variables, $X_s$, simulates the predicted value of that observation under the hypothetical condition that this observation has the each individual unique value of $X_s$ in the entire dataset.  By holding all other features constant, the marginal value of feature *s* on observation $X_i$ can be simulated. Averaging across all X create a measure of partial dependency, often visualized by plotting, known as a partial dependency plot.  

Converting this process to a real estate use for the purpose generating a house price index means valuing a given property ($X_i$) as if it had each unique value of time of sale ($X_s$) in the dataset.  Do this for all properties in the dataset and average to get the full partial dependency of sale price on time of sale.  

## Conceptual Framework

In conceptualizing a machine learning process for creating house price indexes, it is helpful to abstract the generic process.  Broadly, estimating a house price index involves the following steps:

1) Choose a model and apply it to the data with the purpose of explaining house prices.  The chosen model will need to have a specification that accounts for one or more temporal variables or features in order to allow the model to capture or express any impacts that time may be having on prices.  Additionally, note that the choice of model class may be driven by data availablility -- e.g. data without rich hedonic features may be limited to a median or repeat sales specification.

2) Subject the model results to an interpretability method to generate insight into the data generating process.  For some models, this is inherent (time period medians) and for others it is a standard output (regression beta coefficients).  However, the output of many machine learning models will provide only predicted values.  In these cases, a post-model interpretability method will need to be applied. 

3) Take the inherent or derived insights into the DGP -- the marginal contributions of each time period to price -- and convert those into an index via one of a standard set of indexes procedures. 

<!-- (REDO this FIGURE) -->
**Figure 1: Conceptual Mode**
![](figures/concepts.png)

More simply, this can be mapped to three decisions or steps in the process.  The table below maps the three steps to actual processes from a standard hedonic price model example. 

| Step | Description |
| :----------------: | :------------------------------------------- | 
| Choose a model | Specify a hedonic regression model using some configuration of temporal control variables |
| Choose an interpretability method | Extract the coefficients on the temporal variables as the marginal contribution of each time period toward prices in the data |
| Choose an indexing method | Convert these coefficients to an index via the Laspreyes approach |
| | |

Within this framework, we can now extend the creation of house price indexes to any class of model, machine learning or otherwise, provided that a sufficient interpretability method can be applied to extract or explain the marginal impact of time period on prices. 

### A Machine Learning Example

In this section I create an example house price index using the interpretable random forest method as discussed above. All computations and plotting are done in the R statistical language (CIT) and reproduction code is available on the paper's Github site.

The `hpiR` package provides a sample datasets to work with. This data includes over 43,000 sales of single family homes and townhouses within the City of Seattle over the 2010 to 2016 time frame. The source of the data is the King County Assessor's office.^[ A small amount of data cleaning has gone into the creating the data, for more information on this process please contact the author.] The data is open and free to share.

We begin by specifying a random forest model using a number of hedonic characteristics -- bedrooms, bathrooms, building quality, total square feet, age, latitude, longitude and use type (SFR or Townhome) -- and a monthly indicator of sale date. To create a single Individual Conditional Expectations analysis and plot, we select the first observation in the data and predict the sale price of that property as if it sold in each period in the analysis.  This provides us with 84 individual expectations or predicted prices, converted to an index by dividing each by the prediction in time period 1 multiplied by 100 (Figure 2).

![Figure 2: Example - Individual Conditional Expectation](figures/ice1.png)

Applying this same method to all 43,313 sales in the dataset we generate the light gray lines shown in Figure 3.  Averaging these values at each time period provides the Partial Dependency, shown visually in Figure 3.

![Example - Partial Dependence Plots](figures/iceall.png)

Given the hot housing market in Seattle over this time period this suggested House Price Index appears reasonable and is relatively smooth considering these are the raw results. In Figure 4, we compare this index to those created by more traditional repeat sales and hedonic price models -- using the same data.  The model specifications used in the random forest are the replicated in the hedonic model here. Overall, the three models track each other very well (Figure 4), with the exception of the interpretable random forest (IRF) model showing slighly lower price gains in 2016 compared to the others. The next section evaluates the performance or quality of each index.

![Comparison of Approaches](figures/comp.png)

## Index Comparison

Despite the volume of work on comparing house price indexes over the past thirty years, no true concensus has emerged on a framework of comnparison.  Visual or tabular comparisons of index values over time is one of the most common, and usually the first line of evaluation (CIT).  Such a relative comparison can prove apt when extending or improving on an existing, and well tested, method such as a repeat sales model.  A visual inspection the three index produced above (Figure X) shows a general agreement in trend, though there are differences in terms of index values in the early and late periods.  Additionally, the interpretable random forest (IRF) approach shows reduced month to month volatility compared to the standard hedonic and repeat sales models. 

This quick, visual inspection suggests that the newly developed IRF approach appears reasonable.  But is it better?  And, more specifically, better at what? The remainder of the paper set out to answer this question by comparing the performance of the three approaches on the same data across three different metrics: volatility, accuracy and revision. Additionally, the models are estimated using the entire dataset as well as local subsamples to test how each responds to reduced sample sizes.

### Metrics

As noted above, there is not a standard set of tests, metrics or criteria for evaluating the fitness of house price indexes.  At the most conceptual level, we want our indexes to exhibit perfect fidelity to the actual house price market movements.  This target, however, does not exist and, in fact, this absence is the reason for developing indexes in the first place. Further, some uses and users of house price indexes may be willing to trade off some small amount of error in the actual measurement if it reduced other index related pathologies.  Two of the most commonly cited pathologies or problems with house price indexes are volatility -- unnecessarily high period-to-period movements (CIT) -- and revisions -- the tendency of earlier index values to change once new data is added (CIT). Conceptually this can be seen as trading off bias (error in fidelity of the index to actual trend) against variance in the period-to-period index values -- both across time in a single index (volatility) and across individual index values in series of indexes (revision).  

In this work, I will examine all three metrics, accuracy, volatility and revision. I do this without preference to one over another as different users and broad use cases of house price indexes may wish to optimize one of these at the expense of the others. For each measurement, i've employed a metric this is intended to be model agnostic, or rather, than can be calculated for the index itself as is not dependent on any particular functional form of the model or process that creates the index.  An example of a model-dependent metric would be assessing the confidence intervals of the time period coefficients from a regression model.  

#### Accuracy

Next, I define accuracy as measuring the closeness which which the index predicts the second sale of a sale-resale pair.  Predictions are made by taking the price of the first sale and indexing it to the date of the second sale by the estimated index and measuring the difference (error) from the actual price of the second sale. Accuracy is best measured out-of-sample -- not allowing the second sale itself to influence the creation of the index. 

I use two approaches to out-of-sample accuracy measurements.  The first uses a standard k-fold approach in which, for example, 90% of the data is used to fit the model and the predictions are made on the remaining 10%.  This process is then repeated 9 more times for another random 10% of the data as a holdout.  Each observation spends one iteration in the holdout and the prediction error across all observations is measured.  

The convention k-fold approach can be a bit problematic in a longitudinal setting such as estimating house price indexes.  In any of the 90/10 splits, most of the holdout set is being valued by an index that 'knows the future'; or one that was estimated with information well after the holdout observation occured.  This situation does not well approximate many of the actual use cases of house price indexes which are most interested in the fidelity of the index at the most recent point in time (i.e. last month or quarter).  Another approach to out-of-sample measurement is to forward predict, or to predict 'out-of-time'.  As an example, to measure out of sample (time) accuracy on a sale-resale pair that sold in period 1 and then again in period 30, we would use the data from period 1 to 29 to create an index, then foreward cast the index one period and evaluate the forward indexed price from period 1 against the subsequent sale in period 30.  In other words, we want to ensure the model is ignorant of the validation point (the period 30 sale) as well as an other future knowledge of market trends (as they are highly correlated within a market area across time). One major downfall of this approach is that is requires specificying and implementing a forecasting approach, which itself adds additional uncertainty to the process.  

As both accuracy approaches have downfalls, I measure them both with an eye towards understanding if there are relative differences in performance based on the metric chosen.  I discuss these implications in the Discussion section concluding this paper. 

#### Volatility

Volatility measures the variation in the index value from period to period.  While, there is no ideal minimal level of volatility that is desired; no volatility at all signifies a perfectly flat index which is not desirable if there are market movements -- in general lower volatility is usually preferred to higher. High volatilty may be a sign of overfitting from the underlying model, or, as is often the case in areas with few sales, simply a product of small sample sizes.  

What is desirable is an index that tracks the market without fluctuating widely above and below the actual trend each period.  In this research, volatility is measured as the standard deviations of period-to-period changes in a rolling four-period time span.

$V = sd(D_{t, t+1, t+2})$ where $D = index_k - index_{k-1}$

This is an appealing metric as consistent, monotonic changes over a four month span -- the three measures of period changes -- will produce very low standard deviations.  On the contrary, wildly fluctuating indexes with irregular directionaly movements will produce high volatility measures. 

#### Revision

The final metric, revision, is the amount that previous index values change as a new period is added to the index.  For example, imagine the 5th period in our index is estimated at 110.  We then receive data for period 6 and the index value for period 5 is revised down to 109 due to changes in our model's coefficients as a result of the additional sample observations.  This is a revision of 1.  Here, we measure revision as the global mean of the individual mean of the revisions for each period in the index as it expands out to cover the entire time period.  Or, take an average of the combined average revisions to period 1, the average revisions to period 2, ..., the average revisions to period k.

$R = \sum{R_k}/k$ where $R_k = \sum{(K_j - K_{j-1})}/j$ where $j$ is the new index being generated after each addition of data. 

Revisions are particularly interesting and worthwhile metric for house price use cases that are continuously updated an index over time.  Large and consistent re-statements of prior index periods can be problematic, especially if the indexes are used to back financial instruments (Deng and Quigley 2008).  For indexes used to make adjustments to training data for automated valuation models and other appraisal purposes, systematic revisions in same direction -- sustained downward adjustments over time -- can result in biased property valuation estimates other propogated errors.  

### Data

The data for this study originate with the King County Assessor.  All transactions of single family and townhome properties in the County over the January 2010 through December 2016 period are included.  The data are found in the `hpiR` R package and can be freely downloaded and accessed within this package. Home were filtered to keep only arms-length transactions based on the County's Instrument, Sale Reason and Warning codes.  Additionally, any sale that sold more than twice and underwent a major renovation between sales was removed as these transactions violate the constant quality assumptions made in the repeat sales models estimated below. 

The data includes the following information for all 43,313 transactions:

| Field Name | Type | Example | Description |
| :----- | :-----: | :-----: | :------------------------- |
| pinx   | chr  | ..0007600046  | Tax assessor parcel identification number |
| sale_id  | chr | 2011..2621   | Unique sale identifier   |
| sale_price  | integer  | 308900   | Sale price  |
| sale_date  | Date   | 2011-02-22   | Date of sale   |
| use_type  | factor  | sfr   | Structure type   |
| area  | factor  | 15   | Tax assessor defined neighborhood or area   |
| lot_sf  | integer  | 5160   | Size of lot in square feet  |
| wfnt  | binary   | 1  | Is the property waterfront?  |
| bldg_grade  | integer  | 8 | Structure building quality  |
| tot_sf  | integer  | 2200   | Total finished square feet of the home |
| beds  | integer  | 3   | Number of bedrooms |
| baths  | numeric   |  2.5 | Numbrer of bathrooms   |
| age  | integer   | 100 | Age of home   |
| eff_age  | integer   | 12   | Years since major renovation   |
| longitude  | numeric   | -122.30254   | Longitude  |
| latitude  | numeric   | 47.60391  | Latitude  |

Within the 43,313 total sales, there are 4,067 transaction which sold twice.  This set of repeat transactions is limited to those which re-sold at least one year after the initial sale.  This constraint is applied to avoid potential home flips, which more often than not violate constant quality assumptions (Steele and Goy 1997). 

### Local Subsamples

In addition to comparison on performance at the global (City of Seattle) level, I also break the data into the 25 major tax assessment zones for residential, single family properties.  Using the tax assessment zones (Shown in Figure X) are preferable to common disaggregating zones such as Zip Codes as the tax assessment zones are relatively balanced in size and purposefully contructed to, generally, follow local housing submarket boundaries.  Of the 25 zones, 22 of them have between 1100 and 2300 sales over the 7 year period of this study.  The remaining three have 747, 2792 and 2827, sales.  

![Assessment Areas and Sales](maps.png)

<!-- #### Global -->

<!-- The indexes from the three global models are shown below in Figure X.  It is clear that the Repeat Transaction and Hedonic models have considerably more period to period movement thant he much smoother Random Forest index.  By our metric discussed above, the Random Foreset model has about 1/6 of the volatility.  Interestingly, while the Repeat Transaction and Hedonic models do show differences in movements, overall their volatilities are very similar at the global scale.  -->

<!-- ```{r fig.width = 10, fig.height=3} -->
<!--  data_$gindex_plot -->

<!-- ``` -->

<!-- #### Local -->

<!-- Indexes for all 25 local areas across all three models are shown in Figure X.  Here the volatility varies widely across the three models.  The Repeat Transaction indexes move widely when estiated at a local level, a direct product of the greatly reduced sample sizes.  Volatility at the local level increasess signficantly from 0.018 at the global level to a mean of 0.231 (+1200%) at the local level.   The hedonic indexes also increase markedly, from 0.018 to  0.061 (+300%).  Remarkably, the volatility for the Random Forest indexes remains unchanged, as each local area maintains a relatively smooth progression of index estimates.  -->

<!-- Certainly, these very high values are being driven upwards by some of the more volatile areas, but, nontheless the decrease in variation from left to right across the panels in Figure X is obvious.  -->

<!-- ```{r fig.width = 10, fig.height=4} -->
<!--   data_$lindex_plot -->
<!-- ``` -->

<!-- <!-- #### Seasonal Adjustments --> -->

<!-- <!-- * Maybe add something here --> -->



<!--  ### Use Cases and Scenario -->

<!--  * Global vs Local -->
<!--  * K_Fold (fitting) vs Pred (forecasting) -->


<!-- We begin by select the first observation in our sales data and creating an individual conditional expectations (ICE) plot for this observation over the entire 84 month time period of our data. To do so, we assume that this home sold 84 times, once each period, and then estimate the predicted value from the random forest across these 83 hypothetical sales (and one true sale).  Plotting these predicted values create the time series seen in Figure 1 below. -->

<!-- ```{r} -->
<!--  data_ <- readRDS(file = file.path(getwd(), '/data/rf_pdp/data_.RDS')) -->
<!-- ``` -->
<!-- ### Accuracy -->

<!-- We begin our comparison of index quality by assessing the accuracy of the indexes.  In this context, accuracy refers to the ability of the index to predict the second sale in a repeat sale pair.  More simply, if we take the first sale in a repeat sale pair and adjust it with the index, how close is this adjusted value to the actual price of the second sale. When measure the error -- or the difference between predicted and actual second sale -- we use log metrics due to their ability to avoid denominator bias and the skewness in possible errors that results (Tofallis 2014).  The formula for evaluating accuracy is:  -->

<!-- $log(price_{pred}) - log(price_{actual})$ -->

<!-- where the $price_{pred}$ is the time adjusted prediction and $price_{actual}$ is the actual sale price of the repeat transaction in the sales pair.  -->

<!-- Using repeat sale as our validation criteria does impart some advantage to the repeat transaction method; however, we evaluate accuracy in two distinct ways that lessen any perceived advantage this may impart.  First, we evaluate the ability of indexes to predict prices out-of-sample using a k-fold approach.  In this case, we use a 10-fold approach, whereby 90% of the sample is used to create an index that is then used to predict repeat sale prices on the 10% that was held out of the samnple.  This is done for each 10% random holdout. By doing so, no evaluation observations (repeat transaction) can influence the index used to predict its second sale price. We refer to error metrics from this approach as K-Fold errors.  -->

<!-- A potential shortcoming of the K-Fold approach is that it allows the indexes to 'know the future', in the sense that when creating an index future transactions and market activity is used to create current index values.  This omniscience does not map well to a primary use case of house price indexes which involve estimate accurate price movements at the current time (for which no future is known).  To best simulate this use case, we also calculate error metrics via a forward prediction approach.  In this approach, we estimate an index using all data for time periods 1 to K and then use this index to estimate all repeat sales occuring in time period K+1. To avoid systematic under (over) predictions in times of rising (falling) markets, we 'forecast' the index value from time period K to period K+1 with an ANN prediction approach (R `forecast` package...[NEED more info on this]). We refer to these error metrics as Prediction errors.   -->

<!-- Both types of error metrics are evaluated at both the Global and Local scales below.  Additionally, we comparing accuracy statistcs we example both the median absolute percentage error (MdAPE) and the median percentage error (MdPE).  MdAPE measures the accuracy of the index while MdPE measures its bias.   -->

<!-- #### Global Accuracy -->

<!-- Global accuracy result are shown in Table X.  For the K-Fold metrics, the Random Forest approach shows the best accuracy (MdAPE), though the Repeat Transaction models show less bias (lower MdPE).   Moving over to Prediction evaluation, the Hedonic approach is the clear winner in terms of accuracy, with the Repeat Transaction model again showing the lowest bias.   -->

<!-- Based on the global accuracy values, neither of the three index approach methods clearly outperms the others.  Repeat transactions do hold lower biases in this sample, but, as is often the case, at the expensive of some bit of accuracy.  -->

<!-- ```{r} -->

<!--   print_df <- data_$gaccr_pdf -->
<!--   print_df$Model <- forcats::fct_relevel(print_df$Model, 'RepeatTrans', 'Hedonic') -->
<!--   knitr::kable(print_df %>% dplyr::arrange(Model)) -->

<!-- ``` -->

<!-- #### Local Accuracy -->

<!-- Examining the local accuracy numbers shows are marked change from the Global ones.  The much smaller sample sizes in the Assessment zones creates a considerable decrease in accuracy (errors +70%) for the Repeat Transaction model across both the K-Fold and Prediction metrics.  Accuracy numbers for the Hedonic and Random Forest also increased, but very slightly so.  In terms of accuracy, the Random Forest approach remains the most accurate in the K-Fold scenario, while the Hedonic again dominates in a predictive sense.  Biases remain high in the Random Forest approach.  Despite the large degradation in accuracy, the Repeat Transaction model remains unbiased in the K-fold, but not in a prediction framework.   -->

<!-- ```{r} -->

<!--   print_df <- data_$laccr_pdf -->
<!--   print_df$Model <- forcats::fct_relevel(print_df$Model, 'RepeatTrans', 'Hedonic') -->
<!--   knitr::kable(print_df %>% dplyr::arrange(Model)) -->

<!-- ``` -->

<!-- The accuracy evaluation suggests a number of stylized facts to be considered in the remainder of this paper: -->

<!-- * The move from Global to Local models did not improve accuracy in any model, and greatly harmed the Repeat Transaction models -->
<!-- * All models are either unbiased (Repeat Transactions) or show bias on the low end; are underpredicting second sale pricdes -->
<!-- * Random Forest models are more accurate than Hedonic in K-Fold, but this relationship switches in a Prediction scenario.   -->

<!-- We spend the remainder of this paper exploring each of these facts through additional measures of model performance.  -->

<!-- #### Spatial Dependence -->

<!-- If price changes occur at spatial scales below that of the city, we would expect local models to outperform global ones.  This assumption, however, assumes that we are correctly specifying local areas of differing levels of appreciation.  As this is a broad task, we leave this optimization to future research.  What we can test here is wether or not the use of local models reduced the spatial dependence of the prediction errors.  The Moran's I statistic (CIT) measures the likelihood of a set of spatial values (in this case model residuals) being randomly located as opposed to having a spatial pattern.  If the statistic is positive it suggests that the spatial values are not randomly located, or rather, that high values are located near high values and vice versa.   -->
<!-- In this context, we would expect local models to have lower spatial dependence that global ones.   -->

<!-- Calculating Moran's I requires specifying a spatial weights matrix -- or a set of beliefs about which observations potentially influence or are 'neighbors' to others.  As this decision can influence measures of spatial dependence, we choose three levels of dependence or spatial weights matrices -- 5, 10 and 25.  In the case of 5, each observation's value (model error) is compared against the nearest 5 observations.  -->

<!-- Figure X shows the results of the Moran's I calculations.  In each panel, the left hand point is the measure from the global model, the right hand that from the local models.  Across both accuracy types -- K-Fold and Prediction -- and for each of the three model types we see that local models have drastically reduced the level of spatial auto-correlation in the model residuals.  In fact, in all cases the results move from being significantly auto-correlated to being statisticially indistinguishable from a random pattern.  The differences between the choice of spatial weights matrix (number of KNN) is largely irrelevant.  -->

<!-- ```{r fig.height = 8, fig.width = 6} -->
<!--  data_$spdep_plot -->
<!-- ``` -->


<!-- ### Revision -->

<!-- A third criteria to examine house price indexes by is revision.  As more data is collected over time (this periods sales are recorded and analyzed) how much do previous index estimates change? -->

<!-- To measure revision, we start with a 24 month period of data and estimate a base index for each model.  We then add in the 25th month's data and reestimate the index, noting the change in the values for the periods 1 to 24.  Next, we take the 26th months data, reestimate the index for periods 1 to 25, and so on up til the end of our data (period 84). -->

<!-- For each period, we then measure the mean change or revision that occurs across the 60 sequentially longer indexes that we estimated.  Early periods will have more observations than later periods through this approach.   -->

<!-- Figure X below shows the mean revision amount across the time period, by each model for the global models.  There are three key takeaways here: 1) The hedonic model has almost no revisions over time; 2) The Repeat Transactions model has higher revisions in the earlier periods (final period aside); and 3) the Random Forest approach suffers from the highest revisions in the later periods.   -->

<!-- The stability in the Hedonic approach is a statistical deriative.  The only method by which revisions would occur is if the hedonic control variables -- the non-time variables in the model -- showed considerable temporal variation.  In other words, if the marginal value of a bathroom changed markedly over the study period, that could have the impact of changing the coefficient for period 17, for example, when estimating the model in period 84 versus period 83.   -->

<!-- Repeat Transaction models are continually adding new, early period, observations over time and as time progresses, the number of times an original sale from an earlier period resells increases.  As a result, revision to earlier periods is common occurence in Repeat Transaction models, and one that doesn't necessarily dissappear as the size of the data grows. Interestingly, these adjustments are usually downwards, suggesting that the first resales that occur (the shortest time period ones) over-estimate appreciation.  This matches with what we would expect as many of these are flips where the property has been improved, thus violating a principle assumption of the repeat transaction model.  In this study we only use sales at least 12 months apart, but, nontheless some flipping activity is likely to remain in our data.  -->

<!-- The behavior of the Random Forest model in regards to revisions can likely be explained by the functioning of the underlying random forests themselves.  Each tree of a random forest makes binary splits of the data on a single variables as it grows out it (decision/regression) trees.  For the purposes of building house price indexes, we are primarily concerned about how it splits on the time period variable, a numeric value.  The binary splits divide the data into two subsets which then are further split until some minimum size 'leaf' node is created.  This binary splitting process make it difficult for the random forests to properly 'keep up' with high periods of change as they aggregate all the recent time periods into the right-hand most split on time.  In short, in an 84 period data set with, for example, constant appreciation, the time split is more likely to occur at time period 82 than at 83, thus grouping time perios 83 and 84 together and under-estimating actual appreciation in time 84.  What this means is that when growing out a series of house price indexes during a time of rapidly increasing prices (as 2013 to 2017 saw) we would expect the latest periods in the index to be lagging (lower than) the active market price movements.  The data is Figure X do seem to support this hypothesis.  -->

<!-- #### Global -->

<!-- ```{r fig.width = 10, fig.height=5} -->

<!--  data_$grev_plot -->

<!-- ``` -->

<!-- We can go one step further to test the above hypotheses. In Figure X we plot the change in the index from period to period on the X axis and the mean amount of revision for that period on the Y-axis.  For the Repeat Transaction model we see very consistent negative revisions regardless of the actual index movements.  In other words, as we collect more data, Repeat Transaction indexes generally revise downwards.  As expected, there is little going on with the hedonic model as there is little revision to measure. -->

<!-- For the Random Forest model, we observe a distinct positive relationship between upward revision and index (market) movements.  When markets are moving upwards quickly, the Random Forest model lags and need to make upwards revisions later on.  When markets are relatively stable, there are few revisions.  Note that although their are few negative revisions in the right hand panel this is not a product of the model, but rather a product of the fact that over this particular time period there were very few periods where the market declined.  During times of steep decline, it is likely that revisions would be downward for the same reason -- the splitting process -- that we see upward ones in high appreciation periods.  -->

<!-- ```{r fig.width = 10, fig.height=5} -->

<!--  data_$grev_delta_plot -->

<!-- ``` -->

<!-- #### Local -->

<!-- We then extending this same analysis to the local markets in Figure X.  The first thing to note about these plots are that the scales of the X-axis vary widely.  This is due to the high volatility in the Repeat Transaction and, to a lesser extent, the Hedonic local models.  The variable scales were necessary to adequately display the trends in the data. The Y-axis are contant across the three panels.  -->

<!-- For the Repeat Transaction models there is a strong negative correlation between market movements and revisions.  In periods of high price growth (decline), the models tend to overshoot and suggest even more extreme upward (downward) movements, only to have later data temper those initial values.  Conversely, the Random Forest models tend to under state changes, evenually being revised upwards over time.  For the Hedonic model, even in times of high volatility (see Figure X above) the overall revisions are very minimal, speaking to the stability of the Hedonic approach over time.   -->

<!-- Again, note that the relative lack of negative index period changes in the Random Forest model is a product of the time period of this analysis and not, necessarily, any underlying functioning of the model.  In short, it is more difficult for the random forest approach to create short term variability which, in a time of consistent annual price growth, equates to very few decreases in the index values from period to period.  -->



<!-- ```{r fig.width = 10, fig.height=5} -->

<!--  data_$lrev_delta_plot -->

<!-- ``` -->


<!-- ### Comparison of index values -->

<!-- I begin by deriving house price indexes from a hedonic and a repeat sales method for the same data over the same period. In both approaches I robust statistical model (Bourassa et al. references) to create more stable estimates.  These two indexes along with the random forest derived trend are shown in Figure 5. -->

<!-- ```{r, echo = FALSE} -->
<!--  readRDS('c:/code/research/hpir/papers/ares_2019/rhrplot.rds') -->
<!-- ``` -->

<!-- The random forest approach tracks the hedonic and repeat sales models very well, with the only deviation coming in the last year or so of the time period.  The random forest approach is noticably smoother month to month than the traditional approaches. The next section examines a number of quality metrics for each index to try to answer whether or not this new approach is better, or even, comparable to the hedonic model or repeat sales approach.  It is certainly smoother, but is it too smooth? -->

<!-- ```{r, echo = FALSE} -->
<!--  readRDS('c:/code/research/hpir/papers/ares_2019/rhsplot.rds') -->
<!-- ``` -->

<!-- ## Comparative Analysis -->

<!-- In this section I highlight the functionality of the `hpiR` package by using it to compare the 'quality' of the price index (and related series) generated by the Random Forest method with those from more traditional Repeat Sales and Hedonic Price approaches.  -->

<!-- Tables 2 through 4 shows three different metrics attempting to gauge model quality: -->

<!-- 1. Volatility: Standard deviation of a three-month moving window -->
<!-- 2. Revision: Mean change in index estimate re-statement as a series of indexes is grown over time -->
<!-- 3. Accuracy: Ability of the index to predict the second sale price in a repeat sale pair.  Accuracy is calculated three ways: -->
<!-- * In Sample (IS): With no holdout or cross-validation -->
<!-- * KFold (KF): Cross-validated with a 10-fold approach -->
<!-- * Prediction (Pred): A temporal holdout with errors estimated by a `t+1` prediction comparison -->

<!-- #### Full City, 2010 through 2016 -->

<!-- Table 2 compares the three indexes across the full (in both space and time) dataset. As noted above (and visual apparent), the random forest method is considerably less volatile than the other two approaches.  From a revision perspective, the hedonic model moves very little as more data (time) is added -- a feature that is useful when re-statements can be costly.  The random forest approach does see some re-statement, an average of about 1/20 of an index point each period. While more than the hedonic model this is considerably less than the repeat sales model.  Revision and restatatement are known concerns with this approach (.cit.).   -->

<!-- From an accuracy perspective, the random forest models bests both model in-sample and in the k-fold cross-validation approach, though narrowly so.  In the out of time prediction approach, the hedonic model is slightly better than the random forest, both of which handly outperform the repeat sales approach. The smoothness of the random forest model does not seem to be 'too smooth', though it does lose out a bit on forward forecasts.   -->

<!-- ```{r, echo = FALSE} -->
<!--  full_df <- readRDS('c:/code/research/hpir/papers/ares_2019/full_summ.rds') -->
<!--  names(full_df) <- c('Approach', "Volatility", 'Revision', 'Accr (IS)',  -->
<!--                      'Accr (KF)', 'Accr (Pred)') -->
<!--  full_df <- full_df[c(1,3,6), ] -->
<!--  full_df$Approach <- c('Repeat Sales', 'Hedonic', 'Random Forest') -->
<!--  knitr::kable(full_df, format = 'latex', digits = 3, row.names = FALSE) -->
<!-- ``` -->

<!-- ### Small Geographic Areas -->

<!-- The above used a relative large data sample (43,000 observations) to generate the indexes.  Such a large set of sales should generate relatively stable estimates.  Do these same relative performance metrics hold over smaller geographic areas.  -->

<!-- To test this, we divide the sample into the 25 residential assessment areas within the city of Seattle, as determined by the King County Assessor.  Most of these areas have around 1,500 sales over the eight year period, with the most active have 2,800 and the least 750.  We then estimate indexes and series for each small areas and aggregate the results, shown in Table 3.  -->

<!-- ```{r, echo = FALSE} -->
<!--  geo_df <- readRDS('c:/code/research/hpir/papers/ares_2019/geo_summ.rds') -->
<!--  names(geo_df) <- c('Approach', "Volatility", 'Revision', 'Accr (IS)',  -->
<!--                      'Accr (KF)', 'Accr (Pred)') -->
<!--  geo_df <- geo_df[c(1,3,6), ] -->
<!--  geo_df$Approach <- c('Repeat Sales', 'Hedonic', 'Random Forest') -->
<!--  knitr::kable(geo_df, format = 'latex', digits = 3, row.names = FALSE) -->
<!-- ``` -->

<!-- Within the small geographic area index, we see similar relative results across all metrics.  The random forest models are the least volatile and the most accurate in-sample and cross-valided with k-fold approach.  The hedonic models are more stable over time (lower revision) and offer the most accurate predictive estimates. Compared to the city-wide figures in Table 3, small area estimates are slighly more volatile and less accurate, with the exception being those figures for repeat sales models which perform much worse in small areas than in larger ones due to the much smaller samples used in this model.  -->

<!-- ### Short Time Frames -->

<!-- Finally, we test shorter time frames --24 months each -- to see if this constraint has any effect on relative performance differences. This figures in Table 5 are an aggregate of indexes and series estimated on 6, 24-month period segments from the full dataset. Here too, we see nearly identical relative rankings on all metrics.  The absolute number here are much worse in terms of accuracy, likely due to the fact that our validation sets probably contains a higher percentage of flips or other non-constant quality transaction pairs during the reduced time period.  -->

<!-- ```{r, echo = FALSE} -->
<!--  time_df <- readRDS('c:/code/research/hpir/papers/ares_2019/time_summ.rds') -->
<!--  names(time_df) <- c('Approach', "Volatility", 'Revision', 'Accr (IS)',  -->
<!--                      'Accr (KF)', 'Accr (Pred)') -->
<!--  time_df <- time_df[c(1,3,6), ] -->
<!--  time_df$Approach <- c('Repeat Sales', 'Hedonic', 'Random Forest') -->
<!--  knitr::kable(time_df, format = 'latex', digits = 3, row.names = FALSE) -->
<!-- ``` -->

<!-- ## Discussion -->

<!-- Despite the explosion of the use of machine learning models in a variety of pursuits such as natural language processing, image recognition and a broad swath of classification- and regression-based prediction problems, their use in house price index generation has been minimal, at best.  I believe the primary reason for this is their lack of, or perceived lack of, interpretability.  In short, they don't produce coefficients that can be used to generate an index.  -->

<!-- The recent development of a suite of interpretability tools, some of which are model-agnostic, has helped open up the black-box.  In this paper, I show that using two, related, model agnostic interpretability methods -- individual conditional expectations and partial dependence plots -- allow the use of random forest models to generate estimates of home price trends which can be easy converted into a house price index.  -->

<!-- On a sample of home sales in Seattle from 2010 through 2016, the indexes created by this approach roughly mimic indexes derived through hedonic price and repeat sales models.  In fact, the random forest derived models show lower volatility and roughly comparable accuracy to the hedonic models, with the exception of forward prediction accuracy where the hedonic models have a slight edge.  Across all metrics considered, the random forest models are smoother, less susceptible to revision and more accurate than traditional repeat sales models. The relative performance results on the full sample, also hold for model estimated across smaller geographic areas as well as smaller time periods.  -->

<!-- All data used and the models, indexes and the comparative analyses are created with the author's open source, `hpiR` package.  As a result this work is entirely reproducible and, hopefully, easily extensible. The model-agnostic interpretability methods used here could naturally be extended to other dataset and/or machine learning approaches to see if the same promising performances are found elsewhere.  -->

<!-- ### Conclusion -->

<!-- As the development of interpretability methods continues to grow in the machine learning field, use cases for core learning models such as random forest and neural networks will continue to expand.  The above work suggests that, for the house price index use case, estimating the partial dependence plot of a random forest model trained on local home sales can produce a house price index that is comparable in both values and performance to traditional hedonic model and repeat sales methods.  The simulated sales approach used in this method also offers a simple contextual connection to the problem: Imagine my house sold once a month over the entire period, how much would it have changed each month?   -->

\pagebreak

# Bibliography

Abraham, J. M., & Schauman, W. S. (1991). New evidence on home prices from Freddie Mac repeat sales. *Real Estate Economics*, 19(3), 333-352.

Allaire, JJ, Joe Cheng, Yihui Xie, Jonathan McPherson, Winston Chang, Jeff Allen, Hadley Wickham, Aron Atkins, and Rob Hyndman. 2016. Rmarkdown: Dynamic Documents for R. https://CRAN.R-project.org/package=rmarkdown.

Apley, D. (2016). Visualizing the Effects of Predictor Variables in Black Box Supervised Learning Models. arXiv:1612.08468. 

Bailey, M., Muth, R., & Nourse, H. (1963). A Regression Method for Real Estate Price Index Construction. *Journal of the American Statistical Association*, 58, 933-942.

Bivand, Roger, and Nicholas Lewin-Koh. 2016. Maptools: Tools for Reading and Handling Spatial Objects. https://CRAN.R-project.org/package=maptools

Bogin, A. N., Doerner, W. M., Larson, W. D., & others. (2016). Local House Price Dynamics: New Indices and Stylized Facts *FHFA Working Paper*.

Bokhari, S. & Geltner, D. J. (2012). Estimating Real Estate Price Movements for High Frequency Tradable Indexes in a Scarce Data Environment. *The Journal of Real Estate Finance and Economics* 45(2), 533-543.

Bourassa, S., Cantoni, E., & Hoesli, M. (2013). Robust repeat sales indexes. *Real Estate Economics*, 41(3), 517-541.

Bourassa, S., Cantoni, E., & Hoesli, M. (2016). Robust hedonic price indexes. *International Journal of Housing Markets and Analysis*, 9(1), 47-65.

Bourassa, S. C., & Hoesli, M. (2016). High Frequency House Price Indexes with Scarce Data. *Swiss Finance Institute Research Paper*, (16-27).

Bourassa, S. C., Hoesli, M., & Sun, J. (2006). A simple alternative house price index method. *Journal of Housing Economics*, 15(1), 80-97.

Butler, J. S., Chang, Y., & Cutts, A. C. (2005). Revision bias in repeat-sales home price indices. *Freddie Mac Working Paper*

Can, A., & Megbolugbe, I. (1997). Spatial dependence and house price index construction. *The Journal of Real Estate Finance and Economics*, 14(1-2), 203-222.

Cannaday, R. E., Munneke, H. J., & Yang, T. T. (2005). A multivariate repeat-sales model for estimating house price indices. *Journal of Urban Economics*, 57(2), 320-342.

Case, B., Pollakowski, H. O., & Wachter, S. M. (1991). On choosing among house price index methodologies. *Real Estate Economics*, 19(3), 286-307.

Case, B., Pollakowski, H. O., & Wachter, S. (1997). Frequency of transaction and house price modeling. *The Journal of Real Estate Finance and Economics*, 14(1), 173-187.

Case, B., & Quigley, J. M. (1991). The dynamics of real estate prices. *The Review of Economics and Statistics*, 50-58.

Case, K., & Shiller, R. (1987). Prices of Single Family Homes Since 1970: New Indexes for Four Cities. *New England Economic Review*, Sept/Oct, 45-56.

Chau, K. W., Wong, S. K., & Yiu, C. Y. (2005). Adjusting for non-linear age effects in the repeat sales index. *The Journal of Real Estate Finance and Economics*, 31(2), 137-153.

Chinloy, P. T. (1977). Hedonic price and depreciation indexes for residential housing: A longitudinal approach. *Journal of Urban Economics*, 4(4), 469-482.

Clapham, E., Englund, P., Quigley, J. M., & Redfearn, C. L. (2006). Revisiting the past and settling the score: index revision for house price derivatives. *Real Estate Economics*, 34(2), 275-302.

Clapp, J. M. (2004). A semiparametric method for estimating local house price indices. *Real Estate Economics*, 32(1), 127-160.

Clapp, J., & Giaccotto, C. (1992). Estimating price indices for residential property: a comparison of repeat sales and assessed value methods. *Journal of the American Statistical Association*, 87(418), 300-306.

Clapp, J. M., & Giaccotto, C. (1999). Revisions in Repeat-Sales Price Indexes: Here Today, Gone Tomorrow? *Real Estate Economics*, 27(1), 79-104.

Clapp, J. M., Giaccotto, C., & Tirtiroglu, D. (1991). Housing price indices based on all transactions compared to repeat subsamples. *Real Estate Economics*, 19(3), 270-285.

Clapp, J. M., Giaccotto, C., & Tirtiroglu, D. (1992). Repeat sales methodology for price trend estimation: an evaluation of sample selectivity. *Journal of Real Estate Finance and Economics*, 5(4), 357-374.

Coulson, N. E., & McMillen, D. P. (2007). The dynamics of intraurban quantile house price indexes. *Urban Studies*, 44(8), 1517-1537.

Crone, T. M., & Voith, R. (1992). Estimating house price appreciation: a comparison of methods. *Journal of Housing Economics*, 2(4), 324-338.

Dahl, David B. 2016. Xtable: Export Tables to Latex or Html. https://CRAN.R-project.org/package=xtable

de Haan, J., & Diewert, W. E. (2013). Handbook on Residential Property Price Indices. Eurostat, Belgium.

De Vries, P., de Haan, J., van der Wal, E., & Mari?n, G. (2009). A house price index based on the SPAR method. *Journal of Housing Economics*, 18(3), 214-223.

Deng, Y., & Quigley, J. M. (2008). Index revision, house price risk, and the market for house price derivatives. *The Journal of Real Estate Finance and Economics*, 37(3), 191-209.

Dorsey, R. E., Hu, H., Mayer, W. J., & Wang, H. (2010). Hedonic versus repeat-sales housing price indexes for measuring the recent boom-bust cycle. *Journal of Housing Economics*, 19(2), 75-93.

Dreiman, M. H., & Pennington-Cross, A. (2004). Alternative methods of increasing the precision of weighted repeat sales house prices indices. *The Journal of Real Estate Finance and Economics*, 28(4), 299-317.

Englund, P., Quigley, J. M., & Redfearn, C. L. (1998). Improved price indexes for real estate: measuring the course of Swedish housing prices. *Journal of Urban Economics*, 44(2), 171-196.

Englund, P., Quigley, J. M., & Redfearn, C. L. (1999). The choice of methodology for computing housing price indexes: comparisons of temporal aggregation and sample definition. *The Journal of Real Estate Finance and Economics*, 19(2), 91-112.

Francke, M. K. (2010). Repeat sales index for thin markets. *The Journal of Real Estate Finance and Economics*, 41(1), 24-52.

Francke, M. K., & Vos, G. A. (2004). The hierarchical trend model for property valuation and local price indices. *The Journal of Real Estate Finance and Economics*, 28(2), 179-208.

Friedman, J. (2001). Greedy function approximation: A gradient boosting machine. *Annals of statistics* 1189-1232.

Gatzlaff, D. H., & Haurin, D. R. (1997). Sample Selection Bias and Repeat-Sales Index Estimates. *The Journal of Real Estate Finance and Economics*, 14, 33-50.

Gatzlaff, D. H., & Haurin, D. R. (1998). Sample Selection and Biases in Local House Value Indices. *Journal of Urban Economics*, 43, 199-222.

Gatzlaff, D. H., & Ling, D. C. (1994). Measuring Changes in Local House Prices: An Empirical Investigation of Alternative Methodologies. *Journal of Urban Economics*, 35, 221-244.

Gelfand, A. E., Ecker, M. D., Knight, J. R., & Sirmans, C. F. (2004). The Dynamics of Location in Home Prices. *Journal of Real Estate Finance and Economics*, 29(2), 149-166.

Goetzmann, W., & Spiegel, M. (1997). A Spatial Model of Housing Returns and Neighborhood Substitutability. *Journal of Real Estate Finance and Economics*, 14(1), 11-31.

Goetzmann, W., & Peng, L. (2006). Estimating house price indexes in the presence of seller reservation prices. *Review of Economics and Statistics*, 88(1), 100-112.

Goodman, A. C. (1978). Hedonic prices, price indices and housing markets. *Journal of Urban Economics*, 5, 471-484.

Goodman, A. C., & Thibodeau, T. (1997). Dwelling-age-related heteroskedasticity in hedonic house price equations: an extension. *Journal of Housing Research*, 8, 299-317.

Gregorutti, B., Bertrand, M., and Saint-Pierre, P. (2017) Correlation and variable importance in random forests. *Statistics and Computing*, 27(3), 659-678.

Guntermann, K. L., Liu, C., & Nowak, A. D. (2016). Price Indexes for Short Horizons, Thin Markets or Smaller Cities. *Journal of Real Estate Research*, 38(1), 93-127.

Guo, X., Zheng, S., Geltner, D., & Liu, H. (2014). A new approach for constructing home price indices: The pseudo repeat sales model and its application in China. Journal of Housing Economics, 25, 20-38.

Guttery, R. S., & Sirmans, C. F. (1998). Aggregation Bias in Price Indices for Multi-Family Rental Properties. *Journal of Real Estate Research*, 15(3), 309-325.

Haurin, D. R., & Hendershott, P. H. (1991). House price indexes: issues and results. *Real Estate Economics*, 19(3), 259-269.

Haurin, D. R., Hendershott, P. H., & Kim, D. (1991). Local house price indexes: 1982--1991. *Real Estate Economics*, 19(3), 451-472.

Hill, R. C., Knight, J. R., & Sirmans, C. F. (1997). Estimating capital asset price indexes. *Review of Economics and Statistics*, 79(2), 226-233.
Jansen, S. J. T., de Vries, P., Coolen, H., Lamain, C. J. M., & Boelhouwer, P. J. (2008). Developing a house price index for the Netherlands: A practical application of weighted repeat sales. *The Journal of Real Estate Finance and Economics*, 37(2), 163-186.

Knight, J. R., Dombrow, J., & Sirmans, C. F. (1995). A varying parameters approach to constructing house price indexes. *Real Estate Economics*, 23(2), 187-205.

Leishman, C., & Watkins, C. (2002). Estimating local repeat sales house price indices for British cities. *Journal of Property Investment & Finance*, 20(1), 36-58.

Phil Maguire, Robert Miller, Philippe Moser & Rebecca Maguire (2016)
A robust house price index using sparse and frugal data, Journal of Property Research, 33:4,
293-308, DOI:
10.1080/09599916.2016.1258718
To link to this article:
https://doi.org/10.1080/09599916.2016.1258718
Published online: 09 Dec 2016.
Submit your article to this journal
Article views: 136
View Crossmark data
Citing articles: 1 View citing articles


McMillen, D. P. (2003). Neighborhood house price indexes in Chicago: a Fourier repeat sales approach. *Journal of Economic Geography*, 3(1), 57-73.

McMillen, D. (2012). Repeat sales as a matching estimator. *Real Estate Economics*, 40(4), 745-773.

Mcmillen, D. P., & Dombrow, J. (2001). A Flexible Fourier Approach to Repeat Sales Price Indexes. *Real Estate Economics*, 29(2), 207-225.

Mcmillen, D. P., & Thorsnes, P. (2006). Housing Renovations and the Quantile Repeat-Sales Price Index. *Real Estate Economic*s, 34(4), 567-584.

Mark, J. H., & Goldberg, M. (1984). Alternative housing price indices: an evaluation. *Real Estate Economics*, 12(1), 30-49.

Meese, R. A., & Wallace, N. (1991). Nonparametric estimation of dynamic hedonic price models and the construction of residential housing price indexes. *Journal of the American Real Estate & Urban Economics Association*, 19(3), 308-332.

Meese, R. A., & Wallace, N. (1997). The construction of residential housing price indices: a comparison of repeat-sales, hedonic-regression, and hybrid approaches. *The Journal of Real Estate Finance and Economics*, 14(1), 51-73.

Mayer, M., Bourassa, S., Hoesli, M., and Scognamiglio, D. (2019). Estimation and updating methods for hedonic valuation. *Journal of European Real Estate Research.* 12(1), 134-150. https://doi.org/10.1108/JERER-08-2018-0035.

Munneke, H. J., & Slade, B. A. (2000). An empirical study of sample-selection bias in indices of commercial real estate. *The Journal of Real Estate Finance and Economics*, 21(1), 45-64.

Munneke, H. J., & Slade, B. A. (2001). Metropolitan Transaction-Based Commercial Price Index : A Time-Varying Parameter Approach. *Real Estate Economics*, 29(1), 55-84.

Nagaraja, C., Brown, L., & Wachter, S. (2014). Repeat sales house price index methodology. *Journal of Real Estate Literature*, 22(1), 23-46.

Nappi-Choulet, I., & Maury, T.-P. (2009). A spatiotemporal autoregressive price index for the Paris office property market. *Real Estate Economics*, 37(2), 305-340.

Pebesma, E. J., and R. S. Bivand. 2005. "Classes and Methods for Spatial Data in R." *R News*, 2(5): 211-22.

Pollakowski, H. O., Stegman, M. A., & Rohe, W. (1991). Rates of return on housing of low-and moderate-income owners. *Journal of the American Real Estate & Urban Economics Association*, 19(3), 417-426.

Prasad, N., & Richards, A. (2009). Improving median housing price indexes through stratification. *Journal of Real Estate Research*, 30, 45-71.

Ribiero, M., Singh, S., and Guestrin, C. (2016) "Why Should I Trust You?": Explaining the Predictions of Any Classifier. *Proceedings of the 22nd ACM SIGKDD International Conference on Knowledge Discovery and Data Mining.* pp 1135--1144, doi: 10.1145/2939672.2939778.

Quigley, J. M. (1995). A simple hybrid model for estimating real estate price indexes. *Journal of Housing Economics*, 4(1), 1-12.

Schwann, G. M. (1998). A real estate price index for thin markets. *The Journal of Real Estate Finance and Economics*, 16(3), 269-287.

Steele, M., & Goy, R. (1997). Short holds, the distributions of first and second sales, and bias in the repeat-sales price index. *The Journal of Real Estate Finance and Economics*, 14(1), 133-154.

Tofallis, C (2015). A better measure of relative prediction accuracy for model selection and model estimation. *Journal of the Operational Research Society*, 66, 1352-1362. doi:10.1057/jors.2014.103

Tu, Y., Shi-Ming, Y., & Sun, H. (2004). Transaction-based office price indexes: A spatiotemporal modeling approach. *Real Estate Economics*, 32(2), 297.

Wickham, Hadley. 2007. "Reshaping Data with the reshape Package." *Journal of Statistical Software*, 21 (12): 1-20. http://www.jstatsoft.org/v21/i12/.

---. 2009. Ggplot2: *Elegant Graphics for Data Analysis.* Springer-Verlag New York. http: //ggplot2.org.

---. 2011. "The Split-Apply-Combine Strategy for Data Analysis." *Journal of Statistical Software*, 40 (1): 1-29. http://www.jstatsoft.org/v40/i01/.

---. 2016. Stringr: Simple, Consistent Wrappers for Common String Operations. https: //CRAN.R-project.org/package=stringr.

Wright, M. and Ziegler, A. (2017), Ranger: a fast implementation of random forests for high
dimensional data in C++ and R, *Journal of Statistical Software*, 77(1), 1-17.

Xie, Yihui. 2015. *Dynamic Documents with R and Knitr*, 2nd Edition. Chapman; Hall.

Zabel, J. E. (1999). Controlling for quality in house price indices. *The Journal of Real Estate Finance and Economics*, 19(3), 223-241.


