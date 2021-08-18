#!python
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=True
#cython: nonecheck=False
#cython: initializedcheck=False

from numpy cimport npy_bool, float64_t
from structures cimport _MCTS_Node
from libc.time cimport time_t

ctypedef float64_t DTYPE_t

cdef _MCTS_Node* expand(_MCTS_Node* , short[:,::1] )nogil

cdef short rollout(_MCTS_Node* , short[:,::1] ,short[:,::1] ,short[:,::1] , int , npy_bool )nogil

cdef void backpropagate(_MCTS_Node* ,short ,short[:,::1] ,npy_bool )nogil

cdef DTYPE_t calculateUCB(DTYPE_t  , DTYPE_t  , DTYPE_t  , DTYPE_t   ) nogil

cdef _MCTS_Node* best_child(_MCTS_Node* , DTYPE_t  )nogil

cdef _MCTS_Node* tree_policy(_MCTS_Node* , DTYPE_t  , short[:,::1] , short[:,::1] )nogil

cdef void best_action(_MCTS_Node * , unsigned long , DTYPE_t  , short[:,::1], short[:,::1] , short[:,::1] , int  , time_t  )nogil

cdef void freetree(_MCTS_Node* )nogil

