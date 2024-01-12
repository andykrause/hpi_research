# HPI Comparisons

To reproduce the results in the [HPI Comparison paper](https://github.com/andykrause/hpi_research/blob/master/papers/hpi_comp/hpicomp.Rmd) run the following scripts in this order:

* 0_prep_data.R:  Convert the raw `kingco_sales` data into data ready for experimentation
* 1_prep_experiments.R: Create separate experimentation setups (data + configs); save as R objects
* 2_execute_experiments.R: Execute the standard comparative experiments
* 3_prepare_results.R: Flatten the results from #2 into easy to manipulate data.frames
* 4_analyze_experiments.R: Create final analyses for the paper. 



*Note:  The current version of the paper doesn't reflect the updated results as of 1/11/24*


