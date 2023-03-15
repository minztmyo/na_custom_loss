# na_custom_loss

As part of the internship, you will develop ways to utilize a custom loss function which allows missing values(NAs) to pass through our nueral network. The data that you'll be working on is a simulated Single Cell count data with 4 groups of cells. Missing values are added completely at random to 15% of the data (single_cell.csv). Group metadata can be found in column 'group'; the rest of the data are numerical log counts.

single_cell.R is a reference code for how the data was generated. You can use either Python or R for this exercise. You will need to utilize some keras or tensorflow backend functions.
