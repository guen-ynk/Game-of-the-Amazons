#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False

from numpy cimport float64_t, npy_bool
from libc.time cimport time_t

ctypedef float64_t DTYPE_t

'''
    @author: Guen Yanik, 2021
   
    @Methodclass:
        AI ( Alpha Beta prunning)

    @info:
        provides functions for choosing the next move, utilizing alphabeta and heuristics
        whole class 100% C - no GIL
'''
 
'''
    @args:
        board memview, mode 1 2 or 4-> see choosing heuristic, its white turn y/n?, # of amazons per side, operations, (TEH) heuristic board white and black
    @info:
        entrance function for alphabeta prunning

        currently using the following optimizations:
            -   depth = 8 not 2 for the endgame ( #possible moves < 50)
            -   cutoffs
            - *not anymore randomized playorder 
            -   100% C for speed
            -   move and undo move -> using only the original board not wasting space
        open ideas:
            -   move ordering
            -   multithreading for calling instance of AB -> buying time for space

    @return:
        nothing but chooses the best move for wturn as the maximizing player and performs it
'''
cdef void get_ai_move(short[:, ::1] , int , npy_bool , unsigned short , short[:,::1] ,short[:,:,::1] , unsigned int , time_t ) nogil

'''
    @args:
        board memview,  its white turn y/n?, # of amazons per side, depth of AB, alpha, beta, maximizing?, mode 1 2  or 4 -> see choosing heuristic,operations, (TEH) heuristic board white and black, origin color 
    @info:
        function for alphabeta prunning
    @return:
        the alphabeta values for the calling AB instance
'''

cdef DTYPE_t alphabeta(short[:, ::1] ,npy_bool , unsigned short , unsigned short , DTYPE_t , DTYPE_t , npy_bool , int , short[:,::1] ,short[:,:,::1] , npy_bool , unsigned int)nogil
    