#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False

from numpy cimport npy_bool, float64_t
ctypedef float64_t DTYPE_t

# coordinates list struct
ctypedef struct _LinkedListStruct:
    Py_ssize_t x,y, length
    _LinkedListStruct*next   

# move coordinates list struct
ctypedef struct _MovesStruct:
    # s: source; d: destination; a: arrow; length: length of list
    Py_ssize_t sx,sy,dx,dy,ax,ay,length
    _MovesStruct*next 

# MCTS Node struct
ctypedef struct _MCTS_Node:
    # turn of player
    npy_bool wturn, backwturn
    # amazons count per side, player token
    unsigned short qnumber, token, backtoken, num
    DTYPE_t wins, loses, _number_of_visits
    
    _MCTS_Node* parent
    _MCTS_Node* children 
    _MCTS_Node* next
    _MovesStruct* move
    _MovesStruct*_untried_actions   


cdef _LinkedListStruct* add(_LinkedListStruct*  , Py_ssize_t  , Py_ssize_t  ) nogil 

cdef _MovesStruct* push(_MovesStruct*  , Py_ssize_t  ,Py_ssize_t  ,Py_ssize_t  ,Py_ssize_t  ,Py_ssize_t  ,Py_ssize_t )nogil 

cdef _MCTS_Node* newnode(_MovesStruct* , npy_bool  , unsigned short  , _MCTS_Node* )nogil

cdef  npy_bool inlist(_LinkedListStruct*, _LinkedListStruct* )nogil

cdef void* freelist(_LinkedListStruct* )nogil

cdef void* readlist(_LinkedListStruct* )nogil
 