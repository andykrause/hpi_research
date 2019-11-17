---
title: "A Machine Learning Approach to House Price Indexes"
author: 
 Andy Krause
 -- Zillow Group
 -- Seattle, WA
date: "2019-11-17"
output: 
  html_document:
      keep_md: yes
header-includes:
  - \usepackage{setspace}\doublespacing
editor_options: 
  chunk_output_type: console
---







### Abstract

The previously researched approaches for generating house price indexes are almost exclusively found in the realm of traditional statistics, ranging from simple median calculation to complex multiple regression formats. This paper offers a new approach, using a maching learning model class -- random forests -- combined with a model-agnostic interpretability method -- partial dependency -- to derive home price indexes. After developing this method and providing an example, I then test the Interpretable Random Forest (IRF) approach against a repeat sales model and a hedonic pricing model approach.  Using data from the City of Seattle, my comparison suggests that the IRF is competitive (and occasionally superior to) existing methods across measures of accuracy, volatility and revision.

## Introduction

Traditionally, house price indexes have been generated through highly interpretable (statistical) modeling approaches such as measures of changes in median value or multiple regression models.  Both the repeat sales and the hedonic approach -- the two most commonly published approaches (Hill 2012; MacGuire et al 2013) -- are regression models. Parametric statistical models are a good fit for this task as the coefficient estimates are easily convertable into standardized price indexes. In short, house price index generation is not viewed as a prediction problem, but rather a scientific endeavor in which the attribution of the effects of time on market movements is sought. As a result, many of the rapidly growing set of machine learning algorithms -- e.g. support vector machines, random forests and neural networks -- have not been used in the production of price indexes due to the fact that they do not directly and/or easily attribute price impacts to the variables or features in the model. However, with the rise of interpretability methods (Ribiero et al. 2016; Doshi-Velez and Kim 2017; Molnar 2019), these 'black-box' models can be made more explainable and suitable for a more diverse set of tasks. 

This paper highlights the use of partial dependence -- a model-agnostic interpretability method (Molnar 2019) -- to generate house price indexes from a machine learning and inherently non-interpretable model. One of the major appeals of using a model-agnostic approach is that any underlying model class could be used on the data. In this work, I use a random forest, one of the more common and intuitive machine learning models. However, this choice of model class is only for convenience, as a neural network, for example, could just as easily have been used. Along with an explanation of the method and examples, the results from this application of a model-agnostic interpretability method are compared to the more traditional repeat sales and hedonic model approaches. The findings suggest that an Interpretable Random Forest appraoch to house price generation is competitive with (and occasionally prefereable to) the standard approaches across measure of accuracy, volatility and revision on a set of data from the City of Seattle. 

The remainder of this work is organized as follows:  Section two provides a brief literature review, focused on tying in machine learning approaches to the task of house price indexing. Next, I discuss the interpretable random forest (IRF) approach to creating a house price index and provide details using a dataset from the `hpiR` R package: Seattle, WA homes sales in the 2010 through 2016 period. In section four, the random forest method is compared to more traditional models across three metrics -- volatility, revision and accuracy. Finally, I conclude with a discussion and suggestions for future work. 

All data, analysis and visualization used and presented in this study are entirely reproducible.  Please see [www.github.com/anonymousREAuthor/irf](www.github.com/anonymousREAuthor/irf)^[NOTE TO REVIEWERS: This link will be changed to the official repository after blind peer review.  The linked site is an anonymous placeholder used solely for the purposes of review.] for details on downloading the code, accessing the raw data and reproducing the results.  

## Previous Work

Since the seminal Bailey et al. (1963) study there has been considerable and sustained research effort put into comparing and improving competing methods for generating house price indexes.  Published work in this subfield of housing economics is generally focused on one or more of four aims: 1) Comparison of model differences (Case et al 1991; Crone & Voith 1992; Meese and Wallace 1997; Nagaraja et al 2014; Bourassa et al 2016); 2) Identification and correction of estimation issues or problems (Abraham & Schauman 1991; Haurin & Henderschott 1991; Clapp et al 1992; Case et al 1997;  Steele & Goy 1997; Gatzlaff & Haurin 1997, 1998; Munneke & Slade 2000); 3) Creation of local or submarket indexes (Goodman 1978; Hill et al 1997; Gunterman et al 2016; Bogin et al 2019); and 4) Development of a new model or estimator (Case & Quigley 1991; Quigley 1995; Hill et al 1997; Englund et al. 1998, McMillen 2012; Bokhari & Geltner 2012; Bourassa et al 2016). 

This work develops and tests a framework for using random forest models combined with an inerpretability layer to create a house price index.  The review of literature focuses on these two novel components of the work. Readers interested in a broader coverage of approaches to and issues with existing house price index methods are direct to the "Handbook on Residential Property Prices Indices (Eurostat 2013).

### Random Forests

The term 'machine learning' often conjures the pejorative term 'black box'.  Or rather, a model for which predictions are given but for reasons unknown and, perhaps, unknowable, by humans. For use cases where a predicted outcome or response, be it a classfication or a regression problem, in itself is all that is required the 'black box'-ness of a model or algorithm may not be an issue (Molnar 2019).  However, in cases where model biases need to be diagnosed and/or individual feature or variable contributions are a key concern of the research or model application -- such as constructing house price indexes -- machine learning models need to be extended with interpretabilty methods.  

There are many options for the choice of machine learning model, though most all specific model classes fall into four generalized classes: 1) logical model (decision trees); 2) linear and linear combinations of trees or other features (random forests); 3) case-based reasoning (support vector machines); and 4) iterative summarization (neural networks) (Rudin and Carlson 2019). This paper uses random forests (Breiman 2001) as an example as they are a common modeling approach in the machine learning literature and industry. Random forests create a large set of many decision trees, each based on a random set of the data.  As each tree is grown, the partitions in the tree are limited to a random set of the variables (features) in the data. This set of (decision) trees 'grown' via random-ness makes a random forest.  To make a prediction, simply evaluate the subject instance (house in a real estate valuation context) in each tree -- which gives a predicted value -- and then combine all of these evaluations and take the mean (or some other measure of central tendency). The choice of the number of trees to use and the number of random variables to be considered at each partition step are (hyper) parameters that must be determined by the modeler.  

Random forests, essentially bootstrapped submarketing routines, also have a natural link to real estate valuation via the selection of small subsets of like homes to drive predictions. Interestingly, random forests have been little used in academic real estate studies (see Mayer et al 2019 for an exception) and not at all in house price index creation (to the knowledge of the author). This lack of use can likely be explained by the fact that random forests are somewhat of a black box in that they do not directly create coefficient estimates as more traditional statistical models do and, therefore, do not offer a direct approach to create price indexes. A random forest model by itself will provide a predicted value but no direct explanation of how that prediction was generated. In short, they are not inherently interpretable.

#### Interpretabilty Methods

As the use of machine learning models has grown, so too have methods to help raise the interpretability of these approaches (Slack 2019).  One such set of enhancements are termed 'model-agnostic interpretability methods' (Molnar 2019). Model agnostic interpretability methods are post-hoc models that can be applied to any learner or model in order to provide a specific enhancement or extension in the overal interpretability of the model.  Model agnostic interpretabilty methods can fall into a number of types or classes, some of which have varying aims.  Some of the most common approaches are:

* **Simulated or counterfactual scoring**. In these approaches, machine learning models compare scored (predicted) values of counterfactual observations across a given variable(s) while holding all others constant.  Individual conditional expectations (ICE) (Goldstein et al 2014) and partial dependence (PD) (Friedman 2001) are standard examples of this approach . Accumlated local effects (ALE) can also be used when extensive correlations exist in the independent variables (Apley 2016) of interest. Often a goal of these approaches is to understand the marginal contribution of one or more features towards the predicted value.

* **Game Theory (Shapley Values)**. A game theory or bargaining approach where variables or features (the players) compete to determine the optimal payout (coefficient) for their contributions to each observed price (Cohen et al 2005; Molner 2019).  Shapley values, like counterfactual scoring, seek to measure marginal contribution of specific features.

* **Global and local surrogates**.  Surrogate interpretable models that roughly approximate a black box model can provide human-interpretable explanations of black box models.  These surrogate models can be global -- spanning all observations -- or local -- confined to a small subset of the data, such as location.  The locally interpretable model explaination (LIME) method proposed by Ribiero et al (2016b) is the most widely known local surrogate approach.  Local and global surrogates are usually used to more deeply understand the prediction of one or a few individual instances.

* **Feature importance via permutation**. Judging the importance of a particular feature or variable within a black box model can be estimated via a permutation method (Gregorutti et al 2017).  This approach works by estimating a baseline model with all variables as is. For each feature (variable), permute or randomize the data for that feature and re-estimate the model.  Do this for all features one at a time and measure the relative degradation of model performance when each feature is randomized.  This provides a (relative) measure of which variables or features are the most important to the performance of the model. Feature importance measures are used to identify which features in the model provided the biggest (relative) gains in model performance.

In this work, I use measures of individual conditional expectations and partial dependence to extract interpretable insights on real estate market behavior over time. I have chosen this approach for two primary reasons.  First, the ICE/PD approach - via counterfactual scoring across the variable of interest, time -- conceptually mimics the basic questions that drive real estate price indexes, namely: What would this property/house have sold for at given intervals of time, had it sold repeated? In fact, this approach does exactly that by simulating a home sale for a given property at every time period in the study (individual condition expectation) and then combinines those changes in price over time across all properties (partial dependence).

Second, ICEs and PD are one of the easiest of the above methods to compute. Partial dependence calculations are known to be potentally biased when the variable of interest is highly correlated with other independent variables (Molnar 2019). Most variable used in standard hedonic pricing models, such as bedrooms, bathrooms and home size are often highly correlated.  Fortunately, for the purposes of house price index generation the variable of interest -- time of sale -- is generally highly orthogonal to other control variables making partial dependence an acceptable approach. This assumption could be violated if the quality or location of housing that transacts varies greatly over time.  Practically, this is only likely to occur in a relatively small geographic area that experienced significant new construction sales.  The data in our empirical tests span a large, built-out urban municipality so this concern is minimized. 

Partial dependence, and the individual conditional expectations that drive them, can be used to extract the marginal impact of each time period, conditionally, on the reponse or dependent variable: house prices in this case.  The resulting shape of the partial dependency -- linear, monotonic, sinusonoidal, spline-like, etc. -- is entirely depending on the underlying model being evaluated. Conceptually, an individual conditional expectation plot takes a single observation, $X_i$, and for one of the features or variables, $X_s$, simulates the predicted value of that observation under the hypothetical condition that this observation has the each individual unique value of $X_s$ found in the entire dataset.  By holding all other features constant, the marginal value of feature *s* on observation $X_i$ can be simulated. This represents an Individual Conditional Expectation. Averaging across all $X$ create a measure of partial dependency, often visualized by plotting, known as a partial dependency plot (Friedman 2001).

Converting this process to a real estate use for the purpose generating a house price index means valuing a given property ($X_i$) as if it had each unique value of time of sale ($X_s$) in the dataset. In other words, simulate the value of each property as if it had sold once in each time period. Do this for all properties in the dataset and average to get the full partial dependency of sale price on time of sale.  A key point here is that any type or class of model could be used to simulate the series of value predictions; the approach is model agnostic.  

#### An Example 

Figure 1 illustrates example plots of an individual condition expectation (left panel) and partial dependency (right) derived from a random forest model. The left hand panel applies an Individual Conditional Expectation approach on top of a random forest model with time as the variable of interest. Each point on the line, 48 in total, represent the estimated price of an example property for each month over hypothetical four-year time frame.  Applying this same approach to all homes in a dataset (695 in this example), provides the thin black lines in the right hand panel.  Averaging the full set of ICEs results in the partial dependency, shown in thick red.  

**Figure 1: Example of ICE and PD Plots**
![](irf_draft_files/figure-html/unnamed-chunk-1-1.png)<!-- -->

## Conceptual Framework

In conceptualizing how an interpretable machine learning process could map onto the standard approach(es) for creating house price indexes, it is helpful to abstract the generic process.  Broadly, estimating a house price index involves the following steps:

1) Choose a **model** and apply it to the data with the purpose of explaining house prices.  The chosen model will need to have a specification that accounts for one or more temporal variables or features in order to allow the model to capture or express any impacts that time may be having on prices.  Additionally, note that the choice of model class may be driven by data availablility -- e.g. data without rich hedonic features may be limited to a median or repeat sales specification.

2) Subject the model results to an **interpretability method** to generate insight into the data generating process.  For some models this is inherent (median by time period) and for others it is a standard output (regression beta coefficients).  However, the output of many machine learning models will provide only predicted values.  In these cases, a post-model interpretability method will need to be applied. 

3) Take the inherent or derived **insights into the DGP** -- the marginal contributions of each time period to price -- and convert those into an index via one of a standard set of indexes procedures. 

**Figure 2: Conceptual Model**
![](../figures/process.png)

More simply, this can be mapped to three decisions or steps in the process.  The table below maps the three steps to actual processes from a standard hedonic price model example. 

| Step | Description |
| :---------------- | :------------------------------------------- | 
| (1) Choose a model | Specify a hedonic regression model using some configuration of temporal control variables |
| (2) Choose an interpretability method | Extract the coefficients on the temporal variables as the marginal contribution of each time period toward prices in the data |
| (3) Choose an indexing method | Convert these coefficients to an index via the Laspreyes approach |
| | |

Within this framework, we can now extend the creation of house price indexes to any class of model, machine learning or otherwise, provided that a sufficient interpretability method can be applied to extract or explain the marginal impact of time period on prices. In the interpretable random forest example above (Figure 1), the partial dependence estimates provide the 'insight into the data generating process' -- the impact of time on price -- that is used to generate the house price index. 

## Data and Model

In this section, I describe the data used in the empirical tests that follow as well as the particular model specifications employed.  As part of the data discussion, I describe the geographic subsetting employed to provide local tests as well as the city-wide global analyses. 

### Data

The data for this study originate with the King County Assessor.  All transactions of single family and townhome properties within the City of Seattle during the January 2010 through December 2016 period are included.  The data are found in the `hpiR` R package and can be freely downloaded and accessed within this package. The transactions were filtered to keep only arms-length transactions based on the County's Instrument, Sale Reason and Warning codes.  Additionally, any sale that sold more than once and underwent a major renovation between sales was removed as these transactions violate the constant quality assumptions made in the repeat sales models estimated below. Finally, a very small number of outlying observations -- those with sales under $150,000 and over $10,000,000 were removed. 

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

Within the data, there are 4,067 sale-resale pairs. This set of repeat transactions is limited to those which have at least a one year span between the two sales. This constraint is applied to avoid potential home flips, which more often than not violate constant quality assumptions (Steele and Goy 1997; Clapp and Giacotto 1999). 

### Local Subsamples

In addition to comparison on performance at the global (City of Seattle) level, I also break the data into the 25 major tax assessment zones for residential, single family properties.  Using the tax assessment zones (Shown in Figure 3) are preferable to common disaggregating regions such as Zip Codes as the tax assessment zones are relatively balanced in size and purposefully contructed to follow local housing submarket boundaries.  Of the 25 zones, 22 of them have between 1,100 and 2,300 sales over the 7-year period of this study.  The remaining three have 747, 2792 and 2827 sales.  

**Figure 3: Assessment Areas and Sales**
![](../figures/maps.png)
### Models

Three different models are compared in this work; 1) Interpretable random forest (IRF); 2) Hedonic price (HED); and 3) Repeat sales (RS).  The particular specifications, described in detail below, remain the same across the global and 25 local geographic areas. In all cases, indexes are estimated at a monthly frequency.  All models and associated metrics and visualizations are computed in the R statistical language (R Core Team 2019), details on package usage are contained in the discussion on each model. 

#### Interpretable Random Forest

Model specification for random forest are similar to those of standard hedonic price model.  The dependent variable (response) is the price of the home and the independent variables (features) are those factors that are believed to explain variance in the price.  The specification:

$log(P) = f(S, L, T)$

where $P$ is the sale price, $S$ are structural features of the home (including lot size), $L$ are locational features and $T$ are temporal features. More specifically, the structural features, $S$ include home size (sq.ft.), bedroom count, bathroom count, building quality and use type (SFR or townhome), locational features, $L$, are latitude and longitude and the temporal features , $T$, is the month of sale. 

Random forest models also require parameter to control how trees are grown and how many of them contribute to the forest. In each case 500 trees are grown, using an mtry of 3 and a minimum node (or leaf) size of 5.  The `ranger` R package is used to estimate the random forest models (Wright and Ziegler 2017).

#### Hedonic Model

To keep the comparison as 'fair' as possible, the hedonic model uses the same set of independent variables as the random forest:

$log(P) = f(S, L, T)$

where $P$ is the sale price, $S$ are structural features -- hoem size, lot size, bedrooms, baths, quality adn use type -- of the home, $L$ are locational features -- latitude and longitude -- and $T$ are temporal features. The temnporal features in the hedonic model are used as monthly dummy variables instead of a numeric vector as in the random forest.  This allows the hedonic model to identify non-monotonic changes in prices over time -- an ability that would not be possible if time were treated as an interger variable. 

Following the advice of Bourassa et al (2016), I specify a robust regression to help minimize the impact of any outliers or data errors that have avoided filtering.  Specifically, I use the `robustbase` R package to estimate a MM-estimator with a bi-square redescending score function (Maechler et al 2019).

#### Repeat Sales

Many implementations of repeat sales models implement Case and Shiller's (1989) three stage weighted approach that provided greater weight to shorter holds.  Work by Steele and Goy (1997) suggest that this may be a biasing factor as short holds are often less representative of standard home purchases and resales -- the initial sale is more likely to be an opportune buyer.  As a result of this and of work by Bourassa et al (2013), here too I opt for a robust regression approach to help moderate influence from outlying observation and/or changes to quality between sales that was not caught in the data preparate stage.  Again, the `robustbase` R package is used with an MM-estimate with a bi-square redescending score function (Maechler et al 2019). The standard formulation of the repeat sales model with a logged dependent variable:

$log(y_{it})-log(y_{is}) = \delta_2(D_{2,it} - D_{2,is}) + ... + \delta_\tau(D_{\tau,it} - D_{\tau,is} ) + u_{it} - u_{is}$

where $y_{it}$ is the resale, $y_{is}$ is the initial sale and the $D_{\tau,i}$s are the temporal period dummies, -1 for the period of the first sale, 1 for the period of the second sale and 0 for all others. 

## Results

![](irf_draft_files/figure-html/unnamed-chunk-2-1.png)<!-- -->

<!-- ## Comparison -->

<!-- I compare the Interpretable Random Forest with the two most common approaches to generating house price indexes -- Repeat Sales and Hedonic Price models.  I begin by describing the model specification and parameters. A discussion of the data and geographic subsetting tested follows.  After a simple visual comparison of the three global indexes, the models are compared based on accuracy, volatility and revision, both at global and local scales.  -->

<!-- ### Visual -->

<!-- ### Accuracy -->

<!-- ### Volatility -->

<!-- ### Revision -->




## References

Abraham, J. M., & Schauman, W. S. (1991). New evidence on home prices from Freddie Mac repeat sales. *Real Estate Economics*, 19(3), 333-352.

Apley, D. (2016). Visualizing the Effects of Predictor Variables in Black Box Supervised Learning Models. [https://arxiv.org/abs/1612.08468](arxiv.org/abs/1612.08468)

Bailey, M., Muth, R., & Nourse, H. (1963). A Regression Method for Real Estate Price Index Construction. *Journal of the American Statistical Association*, 58, 933-942.

Bogin, A. N., Doerner, W. M., Larson, W. D., & others. (2016). Local House Price Dynamics: New Indices and Stylized Facts *FHFA Working Paper*.

Bokhari, S. & Geltner, D. J. (2012). Estimating Real Estate Price Movements for High Frequency Tradable Indexes in a Scarce Data Environment. *The Journal of Real Estate Finance and Economics* 45(2), 533-543.

Bourassa, S., Cantoni, E., & Hoesli, M. (2016). Robust hedonic price indexes. *International Journal of Housing Markets and Analysis*, 9(1), 47-65.

Breiman, L. (2001) Random Forests. *Machine Learning* 45(1), 5-32. [doi:10.1023/A:1010933404324](https://link.springer.com/article/10.1023/A:1010933404324)

Case, B., Pollakowski, H. O., & Wachter, S. M. (1991). On choosing among house price index methodologies. *Real Estate Economics*, 19(3), 286-307.

Case, B., Pollakowski, H. O., & Wachter, S. (1997). Frequency of transaction and house price modeling. *The Journal of Real Estate Finance and Economics*, 14(1), 173-187.

Case, B. & Quigley, J. M. (1991). The dynamics of real estate prices. *The Review of Economics and Statistics*, 50-58.

Case, K. & Shiller, R. (1987). Prices of Single Family Homes Since 1970: New Indexes for Four Cities. *New England Economic Review*, Sept/Oct, 45-56.

Case, K. & Shiller, R. (1989). The Efficiency of the Market for Single Family Homes. *The American Economic Review*, 79(1), 125-137.

Clapp, J. M., & Giaccotto, C. (1999). Revisions in Repeat-Sales Price Indexes: Here Today, Gone Tomorrow? *Real Estate Economics*, 27(1), 79-104.

Clapp, J. M., Giaccotto, C., & Tirtiroglu, D. (1992). Repeat sales methodology for price trend estimation: an evaluation of sample selectivity. *Journal of Real Estate Finance and Economics*, 5(4), 357-374.

Cohen, SB, Dror, G & Ruppin, E (2005) Feature Selection Based on the Shapley Value. in *Proceedings of IJCAI*. pp. 1-6.

Crone, T. M., & Voith, R. (1992). Estimating house price appreciation: a comparison of methods. *Journal of Housing Economics*, 2(4), 324-338.

Doshi-Velez, F. and Kim, B. (2017) Toward a Rigorous Science of Interpretable Machine Learning. *arXiv::1702.08608*. [https://arxiv.org/abs/1702.08608](https://arxiv.org/abs/1702.08608)

Englund, P., Quigley, J. M., & Redfearn, C. L. (1999). The choice of methodology for computing housing price indexes: comparisons of temporal aggregation and sample definition. *The Journal of Real Estate Finance and Economics*, 19(2), 91-112.

Eurostat (2013) Handbook on Residential Property Prices Indices (RPPIs). *Eurostat: Methodologies and Working Papers* [doi:10.2785/34007](https://op.europa.eu/en/publication-detail/-/publication/cee09dbc-bf48-4126-a7d1-0bb9c028f648/language-en)

Friedman, J. (2001). Greedy function approximation: A gradient boosting machine. *Annals of statistics* 1189-1232.

Gatzlaff, D. H., & Haurin, D. R. (1997). Sample Selection Bias and Repeat-Sales Index Estimates. *The Journal of Real Estate Finance and Economics*, 14, 33-50.

Gatzlaff, D. H., & Haurin, D. R. (1998). Sample Selection and Biases in Local House Value Indices. *Journal of Urban Economics*, 43, 199-222.

Goldstein, A., Kapelner, A., Bleich, J. and Pitkin, E. (2014) Peeking Inside the Black Box: Visualizing Statistical Learning with Plots of Individual Conditional Expectiation.    [https://arxiv.org/pdf/1309.6392.pdf](arxiv.org/pdf/1309.6392.pdf)

Goodman, A. C. (1978). Hedonic prices, price indices and housing markets. *Journal of Urban Economics*, 5, 471-484.

Gregorutti, B., Bertrand, M., and Saint-Pierre, P. (2017) Correlation and variable importance in random forests. *Statistics and Computing*, 27(3), 659-678.

Guntermann, K. L., Liu, C., & Nowak, A. D. (2016). Price Indexes for Short Horizons, Thin Markets or Smaller Cities. *Journal of Real Estate Research*, 38(1), 93-127.

Haurin, D. R., & Hendershott, P. H. (1991). House price indexes: issues and results. *Real Estate Economics*, 19(3), 259-269.

Hill, R. (2013) Hedonic Price Indexes for Residential Housing: A Survey, Evaluation and Taxonomy. *Journal of Economic Surveys* 27(5), 879-914. [https://doi.org/10.1111/j.1467-6419.2012.00731.x](https://doi.org/10.1111/j.1467-6419.2012.00731.x)

Hill, R. C., Knight, J. R., & Sirmans, C. F. (1997). Estimating capital asset price indexes. *Review of Economics and Statistics*, 79(2), 226-233.

McMillen, D. (2012). Repeat sales as a matching estimator. *Real Estate Economics*, 40(4), 745-773.

Maechler, M., Rousseeuw, P. Croux, C., Todorov, V., Ruckstuhl, A., Salibian-Barrera, M., Verbeke, T., Koller, M., Conceicao, E., and di Palma, M.A. (2019). robustbase: Basic Robust Statistics R package version 0.93-5. [http://CRAN.R-project.org/package=robustbase](http://CRAN.R-project.org/package=robustbase)
  
Maguire, P., Miller, R., Moser, P. and Maguire, R. (2016) A robust house price index using sparse and frugal data, *Journal of Property Research*, 33:4, 293-308, [https://doi.org/10.1080/09599916.2016.1258718](https://doi.org/10.1080/09599916.2016.1258718)

Mayer, M., Bourassa, S., Hoesli, M., and Scognamiglio, D. (2019). Estimation and updating methods for hedonic valuation. *Journal of European Real Estate Research.* 12(1), 134-150. https://doi.org/10.1108/JERER-08-2018-0035.

Meese, R. A., & Wallace, N. (1997). The construction of residential housing price indices: a comparison of repeat-sales, hedonic-regression, and hybrid approaches. *The Journal of Real Estate Finance and Economics*, 14(1), 51-73.

Molnar, C. (2019) *Interpretable Machine Learning: A Guide for Making Black Box Model Explainable*. Leanpub. ISBN 978-0-244-76852-2. [https://christophm.github.io/interpretable-ml-book/](https://christophm.github.io/interpretable-ml-book/)

Munneke, H. J., & Slade, B. A. (2000). An empirical study of sample-selection bias in indices of commercial real estate. *The Journal of Real Estate Finance and Economics*, 21(1), 45-64.

Nagaraja, C., Brown, L., & Wachter, S. (2014). Repeat sales house price index methodology. *Journal of Real Estate Literature*, 22(1), 23-46.

Quigley, J. M. (1995). A simple hybrid model for estimating real estate price indexes. *Journal of Housing Economics*, 4(1), 1-12.

R Core Team (2019). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria. URL https://www.R-project.org/.
  
Ribiero, M., Singh, S. and Guestrin, C. (2016) Model-agnostic Interpretability of Machine Learning. *arXiv::1606.05386*. [https://arxiv.org/abs/1606.05386](https://arxiv.org/abs/1606.05386)

Ribiero, M., Singh, S., and Guestrin, C. (2016b) "Why Should I Trust You?": Explaining the Predictions of Any Classifier. *Proceedings of the 22nd ACM SIGKDD International Conference on Knowledge Discovery and Data Mining.* pp 1135--1144, doi: 10.1145/2939672.2939778.

Rudin, C. and Carlson, D. (2019) The Secrets of Machine Learning: Ten Things You Wish You Had Known Earlier to Be More Effective at Data Analysis. *Tutorials in Operations Research* [https://arxiv.org/pdf/1906.01998v1](https://arxiv.org/pdf/1906.01998v1)

Slack, D., Friedler, S., Scheidegger, C. and Roy, C.D. (2019) Assessing the Local Interpretability of Machine Learning Models. [https://arxiv.org/pdf/1902.03501.pdf](https://arxiv.org/pdf/1902.03501.pdf)

Steele, M., & Goy, R. (1997). Short holds, the distributions of first and second sales, and bias in the repeat-sales price index. *The Journal of Real Estate Finance and Economics*, 14(1), 133-154.

Write, M. and Ziegler, A. (2017) ranger: A Fast Implmentation of Random Forests for High Dimensional Data in C++ and R. *Journal of Statistical Software*, 77(1), 1-17. 


