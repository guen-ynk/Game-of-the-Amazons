#!python
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=True
#cython: nonecheck=False
#cython: initializedcheck=False

from numpy cimport npy_bool, ndarray
from structures cimport _LinkedListStruct, _MovesStruct

cdef class Board:
    cdef public:
        npy_bool wturn 
        unsigned short size, qnumber
        ndarray board
        short[:,::1] board_view
        
    @staticmethod
    cdef _LinkedListStruct* get_queen_posn(short[:, ::1] ,short  , unsigned short) nogil

    @staticmethod
    cdef _LinkedListStruct* get_amazon_moves(short[:, ::1] , _LinkedListStruct*) nogil

    @staticmethod
    cdef _MovesStruct* fast_moves(short[:, ::1] , unsigned short , unsigned short) nogil

    @staticmethod
    cdef npy_bool iswon(short[:, ::1] ,short , unsigned short , short [:,::1] )nogil