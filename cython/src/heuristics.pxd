#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False


from structures cimport _LinkedListStruct, add
from numpy cimport float64_t

ctypedef float64_t DTYPE_t

'''
    @class:
        Heuristics
    @info:
        provides functions for the calculation of heuristic values
        whole class 100% C - no GIL
'''
    
'''
    @args:
        board memview, source coordinates, depth also number of moves required so far, heuristic board
    @info:
        function for Territorial evaluation
    @return:
        nothing, but updates the heuristic values in hboard if a field can be reached in less moves than noted
'''
 
cdef _LinkedListStruct* getMovesInRadius(short[:,::1], _LinkedListStruct*, unsigned short, short[:,::1] ) nogil
'''
    @args:
        board memview, source coordinates, depth also number of moves required so far, heuristic board
    @info:
        function for Territorial evaluation
    @return:
        nothing, but updates the heuristic values in hboard if a field can be reached in less moves than noted
'''
cdef _LinkedListStruct* kgetMovesInRadius(short[:,::1], _LinkedListStruct*, unsigned short, short[:,::1] ) nogil
'''
    @args:
        board memview, amazon coordinates, heuristic board
    @info:
        function for Territorial evaluation
    @return:
        nothing, but updates the heuristic values in hboard if a field can be reached in less moves than noted
        utilizing BFS 
'''
cdef void amazonBFS(short [:,::1], _LinkedListStruct*, short[:,::1] ) nogil
'''
    @args:
        board memview, amazon coordinates, heuristic board
    @info:
        function for Territorial evaluation
    @return:
        nothing, but updates the heuristic values in hboard if a field can be reached in less moves than noted
        utilizing BFS 
'''
cdef void kingBFS(short [:,::1], _LinkedListStruct*, short[:,::1] ) nogil
'''
    @args:
        board memview, color of player maximizing, #of amazons per side, heuristic board white, heuristic board black
    @info:
        function for Territorial evaluation
    @return:
        the heuristic value for the maximizing player 
'''
cdef DTYPE_t territorial_eval_heurisic(short[:,::1] ,short , unsigned short , short[:,:,::1] )nogil
'''
    @args:
        board memview, color of player maximizing, #of amazons per side, heuristic board white, heuristic board black
    @info:
        function for Territorial evaluation
    @return:
        the heuristic value for the maximizing player 
'''
cdef DTYPE_t territorial_eval_heurisick(short[:,::1] ,short ,unsigned short , short[:,:,::1] , unsigned int )nogil
'''
    @args:
        board memview, color of player 1 or 2, # of amazons per side
    @info:
        function for mobility evaluation
    @return:
        the number of possible moves of player 1 or 2
'''
cdef DTYPE_t move_count( short[:, ::1] , unsigned short , unsigned short ) nogil