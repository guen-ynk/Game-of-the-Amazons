#!python
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=True
#cython: nonecheck=False
#cython: initializedcheck=False

from numpy cimport float64_t, npy_bool
from libc.time cimport time_t

ctypedef float64_t DTYPE_t

 
cdef void get_ai_move(short[:, ::1] , int , npy_bool , unsigned short , short[:,::1] ,short[:,:,::1] , unsigned int , time_t ) nogil
    
cdef DTYPE_t alphabeta(short[:, ::1] ,npy_bool , unsigned short , unsigned short , DTYPE_t , DTYPE_t , npy_bool , int , short[:,::1] ,short[:,:,::1] , npy_bool , unsigned int)nogil
    