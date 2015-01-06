IMLP
====

This repository provides data and source code for the Iterative Most-Likely Oriented 
Point (IMLP) algorithm described in the paper:

Seth Billings, Emad Boctor, and Russell Taylor, "Iterative Most-Likely Point Registration
(IMLP): A Robust Algorithm for Computing Optimal Shape Alignment", PLoS One (2015)


To generate IMLP source code: see "cisstICP" folder
To run PLoS One experiments: see "PLOSONE" folder

Source code is provided for the following algorithms (see PLoS One paper for details):
 - IMLP
 - IMLP-CP
 - IMLP-MD
 - ICP
 - Robust ICP
 
Other prior-work algorithms evaluated in the PLoS One paper, for which source code is not
provided, include:

GICP:
 - was downloaded from:  http://www.robots.ox.ac.uk/~avsegal/generalized_icp.html
 - see IMLP paper for minor modifications required for termination condition and to set
   covariance matrices
 
CPD:
 - was downloaded from: www.bme.ogi.edu/~myron/matlab/cpd
 - now available at: https://sites.google.com/site/myronenko/research/cpd   
 - see IMLP paper for minor modifications required for termination condition    
    
 These algorithms can be downloaded at the URLs provided above and run using output \
  from the IMLP algorithm above; i.e. point sets, noisy points, covariances, etc. 
  are all saved and can be loaded and run by these algorithms. 

  