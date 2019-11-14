---
title: "A Machine Learning Approach to House Price Indexes"
author: 
 Andy Krause
 -- Zillow Group
 -- Seattle, WA
date: "2019-11-14"
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

## References

Doshi-Velez, F. and Kim, B. (2017) Toward a Rigorous Science of Interpretable Machine Learning. *arXiv::1702.08608*. [https://arxiv.org/abs/1702.08608](https://arxiv.org/abs/1702.08608)

Hill, R. (2013) Hedonic Price Indexes for Residential Housing: A Survey, Evaluation and Taxonomy. *Journal of Economic Surveys* 27(5), 879-914. [https://doi.org/10.1111/j.1467-6419.2012.00731.x](https://doi.org/10.1111/j.1467-6419.2012.00731.x)

Maguire, P., Miller, R., Moser, P. and Maguire, R. (2016) A robust house price index using sparse and frugal data, *Journal of Property Research*, 33:4, 293-308, [https://doi.org/10.1080/09599916.2016.1258718](https://doi.org/10.1080/09599916.2016.1258718)

Molnar, C. (2019) *Interpretable Machine Learning: A Guide for Making Black Box Model Explainable*. Leanpub. ISBN 978-0-244-76852-2. [https://christophm.github.io/interpretable-ml-book/](https://christophm.github.io/interpretable-ml-book/)

Nagaraja, C., Brown, L., & Wachter, S. (2014). Repeat sales house price index methodology. *Journal of Real Estate Literature*, 22(1), 23-46.

Ribiero, M., Singh, S. and Guestrin, C. (2016) Model-agnostic Interpretability of Machine Learning. *arXiv::1606.05386*. [https://arxiv.org/abs/1606.05386](https://arxiv.org/abs/1606.05386)

