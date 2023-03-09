clear; clc;

mex -largeArrayDims fullCRFinfer.cpp util.cpp bipartitedensecrf.cpp permutohedral.cpp densecrf.cpp filter.cpp 

disp('Done!');