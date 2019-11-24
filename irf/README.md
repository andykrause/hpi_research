# A Machine Learning Approach to House Price Indexes



This repository contains the code necessary to reproduce the results in the 'A Machine Learning Approach to House Price Indexes' paper.

To reproduce the results and render the final paper follow these steps:

### Step 1

Ensure you have R 3.5.0 or greater installed.  Clone this directory from this [Github location](www.github.com/anonymousreauthor/irf_house_price_index)

### Step 2

Install the `hpiR` package from its github repository

```{r}
devtools::install_github('andykrause/hpir')
```

The extent to which you will need to install supporting libraries will depend on your current R environment

*Please note that a Docker solution to full reproducibility is coming soon*

### Step 3

Open the **irf_index_generation_script.rmd** file.  Execute all code in this script.  Note that it will likely take a few hours to run all of the analyses.  When this is complete it will write the results to the **/data** directory

There is no need to download any data as it is contained in the `hpiR` package. 

### Step 4

Open the **irf_comparison_script.RMD**.  Execute all code in this script.  Run time should be approximately 10 minutes, again depending on your configurations. Here to, results will be written to the **/data** directory

### Step 5

Open the **irf_draft_pdf.RMD** file in RStudio.  Click on the "knit" button to reproduce this paper.  



