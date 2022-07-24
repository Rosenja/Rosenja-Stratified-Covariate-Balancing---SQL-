# Rosenja-Stratified-Covariate-Balancing---SQL-
Using SQL to group data and perform calculations such as LOS and Common Odds Ratio
Assignment for Class HAP823 -  Comparative Effectiveness


Question 1: The following data provide the length of stay of patients seen by Dr. Smith (Variable Dr Smith=1) and his peer group (variable Dr. Smith = 0).
 Data
Tutorial
Visually show that Dr. Smith see a different set of patients than his peer group. Show a tree where the nodes are the diagnoses, the consequences are length of stay within the tree branch, and each branch is drawn proportional to the expected length of stay.
Balance the data through stratified covariate balancing. Graphically show that the weighting procedure of stratified covariate balancing results in same number of different types of patients treated by Dr. Smith or his peer. Switch the tree structure of peer group (but not the length of stay) with Dr. Smith's tree.
Report the unconfounded impact of Dr. Smith on length of stay using the common odds ratio of having above average length of stay.
 SQL Common Odds SQL Common Odds - Alternative Formats
Reported the impact of Dr. Smith on length of stay using the weighted length of stay.
 SQL Weighted LOS SQL Weighted LOS - Alternative Formats
 
 
Question 2: The following data provide the survival among stomach cancer patients. The data provides 35 common comorbidities for patients who have or don't have stomach cancer.
Using SQL, group the diagnoses into commonly occurring strata.
Within each strata, calculate the odds of mortality from cancer.
Calculate the common odds ratio across strata.
Conduct sensitivity analysis for the calculated common odds ratio. Sensitivity analysis is the process of changing one variable and re-examining the conclusions. Drop one of the 35 comorbidities from the analysis and repeat the entire analysis and check that 65% of cases are matched to controls. The percent of cases that are matched is called overlap. It is defined as:


Further graphing and additional analysis was performed using R studio and will not be included in this repository.
