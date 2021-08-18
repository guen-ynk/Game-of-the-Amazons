#!python
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=True
#cython: nonecheck=False
#cython: initializedcheck=False


from structures cimport _LinkedListStruct, add
from numpy cimport float64_t

ctypedef float64_t DTYPE_t
 
 
cdef _LinkedListStruct* getMovesInRadius(short[:,::1], _LinkedListStruct*, unsigned short, short[:,::1] ) nogil

cdef _LinkedListStruct* kgetMovesInRadius(short[:,::1], _LinkedListStruct*, unsigned short, short[:,::1] ) nogil

cdef void amazonBFS(short [:,::1], _LinkedListStruct*, short[:,::1] ) nogil

cdef void kingBFS(short [:,::1], _LinkedListStruct*, short[:,::1] ) nogil

cdef DTYPE_t territorial_eval_heurisic(short[:,::1] ,short , unsigned short , short[:,:,::1] )nogil

cdef DTYPE_t territorial_eval_heurisick(short[:,::1] ,short ,unsigned short , short[:,:,::1] , unsigned int )nogil

cdef DTYPE_t move_count( short[:, ::1] , unsigned short , unsigned short ) nogil