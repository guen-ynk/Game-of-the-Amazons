#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False

from numpy cimport npy_bool, float64_t
from structures cimport _MCTS_Node, _MovesStruct, _LinkedListStruct
from libc.time cimport time_t

ctypedef float64_t DTYPE_t
'''
    @info:
        This Module contains functionalities for the optimizied UCT Algorithm.
        It translates 100% into C so no GIL functions work in this scope ! 
        ------------------------------------------------------------------------
'''


'''
    @args:
        board memview,  coordinates of amazon, color
    @return:
        list of the amazon coordinates of the reachable fields or enemies
    @info:
        100% C - no GIL !
'''

cdef _LinkedListStruct* get_nopath(short[:, ::1] , _LinkedListStruct* , short ) nogil
'''
    @args:
        One Amazon, color of Player, Board, operational directions (N,NE,E,SE,S,SW,S,NW)
    @return:
        Booleantype {
                        1: not isolated
                        0: isolated
                    }
    
'''
cdef npy_bool prunning(_LinkedListStruct*, short , short[:,::1] , short[:,::1] )nogil
'''
    @args:
        Amazons, color of Player, Board, operational directions (N,NE,E,SE,S,SW,S,NW)
    @return:
        List of Amazons that which fit the not isolated criterion
    
'''
cdef _LinkedListStruct* filteramazons(_LinkedListStruct*, short , short[:,::1] , short[:,::1] )nogil
'''
    @args:
        Board, color of Player, #Amazons per Side
    @return:
        List of Amazons of given player
    
'''
cdef _LinkedListStruct* get_queen_posn(short[:, ::1] ,short , unsigned short ) nogil
'''
    @args:
        Board, List of Amazons, Flag if 
    @return:
        List of Amazons of given player
    
'''
cdef _MovesStruct* get_amazon_moves(short[:, ::1] , _LinkedListStruct* , npy_bool) nogil
'''
    @args:
        calling MCTS node, board memview
    @info:
        function for MCTS
    @return:
        the next unexpanded child of the calling MCTS node
'''
cdef _MovesStruct* get_amazon_moveslib2rule(short[:, ::1] , _LinkedListStruct*, unsigned short) nogil

# compute Arrowmoves including librules
cdef _MovesStruct* get_arrow_moves(short[:, ::1] , _LinkedListStruct* , _LinkedListStruct* ) nogil

cdef _MCTS_Node * expand(_MCTS_Node * , short[:,::1] , short[:,::1] )nogil

'''
    @args:
        calling MCTS node, operations memview, board memview, copyboard memview, iteration+threadid for better seeding
    @info:
        function for MCTS
    @return:
        1 if the calling node wins the Rollout else -1
'''
cdef short rollout(_MCTS_Node * , short[:,::1] , short[:,::1] , short[:,::1] , int , npy_bool )nogil
'''
    @args:
        calling MCTS node, result of the rollout ,board memview
    @info:
        function for MCTS
    @return:
        nothing, but traverses back to the root, updating the nodes and reversing the moves (board) for space effiency
'''
cdef void backpropagate(_MCTS_Node * , short , short[:,::1] , npy_bool )nogil
'''
    @args:
        parent wins, parent visits, child wins, child visits
    @info:
        function for MCTS
    @return:
        the UCB1 value for a child node : see paper []
    @note:
        could try a diffrent formula
'''
cdef DTYPE_t calculateUCB(DTYPE_t  , DTYPE_t  , DTYPE_t  , DTYPE_t   ) nogil
'''
    @args:
        calling MCTS node as parent, param ( not important for this UCB1 score but can be used for future versions including an exploration bonus)
    @info:
        function for MCTS
    @return:
        the best child node
'''
cdef _MCTS_Node * best_child(_MCTS_Node * , DTYPE_t )nogil
'''
    @args:
        calling MCTS node, param ( not important also see best_child()), operations memview, board memview
    @info:
        function for MCTS
    @return:
        the next node for the rollout 
'''
cdef _MCTS_Node * tree_policy(_MCTS_Node * , DTYPE_t , short[:,::1] , short[:,::1] )nogil
'''
    @args:
        calling MCTS node, how many games per turn, param ( not important also see best_child()), operations memview, board memview, boardcopy memview
    @info:
        function for MCTS - ENTRANCE
    @return:
        nothing but performs the best move according to the MCTS on the original board
'''
cdef void best_action_op(_MCTS_Node  * , unsigned long   , DTYPE_t , short[:,::1], short[:,::1] , short[:,::1] , int  , time_t )nogil
'''
    @args:
        calling MCTS node
    @info:
        function for MCTS - utility
    @return:
        nothing but frees the Tree structure 
    @note:
        so far no leaks found via valgrind but they are still possible !
'''
cdef void freetree(_MCTS_Node * )nogil

cdef void debugt(_MCTS_Node * , short  )nogil
