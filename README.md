# SQPnP 
C++ Implementation of the SQPnP algorithm 

Algorithm is based on the paper [A Consistently Fast and Globally Optimal Solution to the Perspective-n-Point Problem" by G. Terzakis and M.Lourakis](http://www.ecva.net/papers/eccv_2020/papers_ECCV/papers/123460460.pdf). For more intuition, refer to the supplementary material [here](https://www.ecva.net/papers/eccv_2020/papers_ECCV/papers/123460460-supp.pdf).

## Required libraries
SQPnP requires Eigen to build. Besides the SVD, the use of the library is confined to matrix addition, transposition and multiplication. Choosing Eigen was motivated by its increasing popularity and lightweight form. However, the example uses OpenCV, just for the sake of demonstrating the initialization of SQPnP with ``cv::Point_<>`` and ``cv::Point3_<>`` structures.    

Build
-----

Create a ``build`` directory in the root of the cloned repository and run ``cmake``:

``mkdir build``

``cd build``

``cmake ..``

or, for a *release* build,

``cmake .. -DCMAKE_BUILD_TYPE=Release``

The latter will allow for more accurate timing of average execution time.Finally,
``make``

To run the example, once in the ``build`` directory,
``./example/sqpnp_example``  
