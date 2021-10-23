#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False
# @Guen Yanik, 2021
from numpy cimport npy_bool, ndarray
from structures cimport _LinkedListStruct, _MovesStruct
'''
    @Class: 
        Board 
    @constructor args: 
        size : board size n
        white_init :  transformed coordinates of white amazons vice versa for black

    @class variables:
        wturn       :   its whites turn
        size        :   board size n
        qnumber     :   count of amazons per side
        board       :   game board -> 0=free    1= white    2=black     -1=Arrow/burned
        board_view  :   Memview representation of board for perforance, see cython documentation 

'''
cdef class Board:
    cdef public:
        npy_bool wturn 
        unsigned short size, qnumber
        ndarray board
        short[:,::1] board_view
    '''
        @args:
            board memview,  player color 1 or 2, #amazons 
        @return:
            list of the amazon coordinates of the respective color
        @info:
            100% C - no GIL !
    '''    
    @staticmethod
    cdef _LinkedListStruct* get_queen_posn(short[:, ::1] ,short  , unsigned short) nogil
    '''
        @args:
            board memview,  coordinates of amazon
        @return:
            list of the amazon coordinates of the reachable fields
        @info:
            100% C - no GIL !
    '''
    @staticmethod
    cdef _LinkedListStruct* get_amazon_moves(short[:, ::1] , _LinkedListStruct*) nogil
    '''
        @args:
            board memview,  player color 1 or 2, #amazons 
        @return:
            list of the possible moves for the player of the respective color
        @info:
            100% C - no GIL !
    '''
    @staticmethod
    cdef _MovesStruct* fast_moves(short[:, ::1] , unsigned short , unsigned short) nogil
    '''
        @args:
            board memview,  player color 1 or 2, #amazons, operations memview 
        @return:
            returns True if color has lost else False
        @info:
            100% C - no GIL !
    '''
    @staticmethod
    cdef npy_bool iswon(short[:, ::1] ,short , unsigned short , short [:,::1] )nogil