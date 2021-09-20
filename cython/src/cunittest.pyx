#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False

from numpy cimport npy_bool, float64_t
import numpy as np
from libc.time cimport time,time_t
from structures cimport _LinkedListStruct, add, _MovesStruct, readlist, readmoves, freelist, freemoves
from ai cimport get_ai_move
from board cimport Board
from newmcts cimport get_amazon_moves, get_amazon_moveslib2rule, get_arrow_moves
from heuristics cimport move_count, territorial_eval_heurisick, territorial_eval_heurisic
ctypedef float64_t DTYPE_t
import amazons as am
 
#@cytest
cpdef test_mobeval4x4():
    cdef:
        short[:,::1] field = np.array(
            (
                (0,1,-1,0),
                (0,-1,2,0),
                (-1,0,-1,-1),
                (0,1,0,2)
            ),
            dtype=np.short
        )
        DTYPE_t erw, echt
        unsigned short qn = 2
        unsigned short white = 1
        unsigned short black = 2
    erw = 17.0
    echt = move_count(field, white, qn)
    assert erw == echt
    echt = move_count(field, black, qn)
    assert erw == echt

cpdef test_tereval4x4():
    cdef:
        short [:,:,::1] hboard = np.full((4,4,4), fill_value=999, dtype=np.short)  

        short[:,::1] field = np.array(
            (
                (0,1,-1,0),
                (0,-1,2,0),
                (-1,0,-1,-1),
                (0,1,0,2)
            ),
            dtype=np.short

        )

        short[:,:,::1] exhb = np.array(
            (
                (
                (1,999,999,999),
                (1,999,999,999),
                (999,1,999,999),
                (1,999,1,999)
                ),
                (
                (3,999,999,1),
                (2,999,999,1),
                (999,1,999,999),
                (1,999,1,999)
                ),
                (
                (1,999,999,999),
                (1,999,999,999),
                (999,1,999,999),
                (1,999,1,999)
                ),
                (
                (3,999,999,1),
                (2,999,999,1),
                (999,1,999,999),
                (2,999,1,999)
                )
            ),
            dtype=np.short
            
        )

        DTYPE_t erw, echt
        unsigned short qn = 2
        unsigned short white = 1
        unsigned short black = 2
    erw = 0.427125
    echt = territorial_eval_heurisick(field ,white ,qn , hboard , 6)
    np.testing.assert_almost_equal(echt, erw,decimal=2)
    erw = 0.22937499999999933
    echt = territorial_eval_heurisick(field ,black ,qn , hboard , 6)
    np.testing.assert_almost_equal(echt, erw,decimal=2)
    np.testing.assert_allclose(hboard, exhb, rtol=1e-5, atol=0)
cpdef test_ai4x4():
    #DEBUG NO TEST
    cdef:
        short [:,::1] ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]],dtype=np.short)

        short[:,::1] field = np.array(
            (
                (-1,-1,0,2),
                (-1,1,-1,-1),
                (-1,-1,0,2),
                (0,1,-1,-1)
            ),
            dtype=np.short

        )
        short [:,:,::1] hboard = np.full((4,4,4), fill_value=999, dtype=np.short)  
        npy_bool wturn = False
    print(tostr(np.asarray(field),4))
    get_ai_move(field, 2, wturn, 2, ops, hboard, 3, 100) 
    print(tostr(np.asarray(field),4))

cpdef test_mctsamazonlibs6x6():
    #DEBUG NO TEST
    cdef:
 
        short[:,::1] field = np.array(
            (
                (-1,0,0,0,0,0),
                (-1,0,-1,1,0,0),
                (-1,2,-1,0,0,0),
                (-1,-1,-1,2,0,0),
                (-1,0,0,0,0,0),
                (1,0,-1,0,0,0)
            ),
            dtype=np.short

        )
        _LinkedListStruct*amazon = NULL
        _LinkedListStruct*eamazons = NULL
        _MovesStruct*res = NULL
        npy_bool wturn = False
    print(tostr(np.asarray(field),6))
    amazon = Board.get_queen_posn(field, 1, 2)
    print("amazons w")
    readlist(amazon)
    res = get_amazon_moveslib2rule(field , amazon,2)
    print("moves w")
    readmoves(res)
    freemoves(res)

    amazon = Board.get_queen_posn(field, 2, 2)
    print("amazons b")
    readlist(amazon)
    res = get_amazon_moveslib2rule(field , amazon,2)
    print("moves b")
    readmoves(res)
    freemoves(res)
    
    amazon = Board.get_queen_posn(field, 1, 2)
    eamazons = Board.get_queen_posn(field, 1, 2)
    print("+++++++++++++++++++++++++")
    readlist(amazon)

    res = get_arrow_moves(field , amazon, eamazons)
    print("moves b")
    readmoves(res)
    freemoves(res)

cpdef test_tereval4x422():
    cdef:
        short [:,:,::1] hboard = np.full((4,10,10), fill_value=999, dtype=np.short)  

        short[:,::1] field = np.array(
            (
                (0 ,0 ,-1,0 , 0, 0, 0, 0, 0, 0),
                (-1,-1,-1,0 , 0, 0, 0, 0, 0, 0),
                (0 ,1 ,-1,-1,-1, 0,-1,-1,-1, 0),
                (0 ,0 ,-1,0 , 0,-1, 2, 1, 0, 0),
                (-1,2 ,-1,0 , 1,-1,-1,-1, 0, 0),

                (0 ,0 ,-1,0 , 0, 0,-1, 0, 0, 0),
                (0 ,0 ,-1,2 , 0,-1, 0, 0, 0,-1),
                (0 ,0 ,-1,0 , 0,-1, 0, 0, 0, 0),
                (0 ,0 ,-1,0 ,-1,-1, 0,-1, 1, 0),
                (0 ,0 ,-1,0 ,-1, 0, 0,-1, 0, 2)
          
                 
            ),
            dtype=np.short

        )
 
    territorial_eval_heurisick(field ,1 ,4 , hboard,6)
    #print(tostr(np.asarray(hboard),10))
def time_benchmark_mobility():#
    import time as t
    #4x4
    board4 = am.Amazons("../configs/config4x4.txt",4,2,0,1,10000)
    stamp = t.time()
    move_count(board4.board.board_view, 1, board4.board.qnumber)
    print("4x4 4 is white wc: ", t.time()-stamp, " seconds" )
    #6x6
    board6 = am.Amazons("../configs/config6x6.txt",4,2,0,1,10000)
    stamp = t.time()
    move_count(board6.board.board_view, 1, board6.board.qnumber)
    print("6x6 4 is white wc: ", t.time()-stamp, " seconds" )
    #8x8
    board8 = am.Amazons("../configs/config8x8.txt",4,2,0,1,10000)
    stamp = t.time()
    move_count(board8.board.board_view, 1, board8.board.qnumber)
    print("8x8 4 is white wc: ", t.time()-stamp, " seconds" )
    #10x10
    board10 = am.Amazons("../configs/config10x10.txt", 4,2,0,1,10000)
    stamp = t.time()
    move_count(board10.board.board_view, 1, board10.board.qnumber)
    print("10x10 4 is white wc: ", t.time()-stamp, " seconds" )

def time_benchmark_territory():#
    import time as t
    #4x4
    board4 = am.Amazons("../configs/config4x4.txt",4,2,0,1,10000)
    stamp = t.time()
    territorial_eval_heurisick(board4.board.board_view ,1 , board4.board.qnumber, np.full((4,4,4), fill_value=999, dtype=np.short)  ,6)

    print("4x4 4 is white wc: ", t.time()-stamp, " seconds" )
    #6x6
    board6 = am.Amazons("../configs/config6x6.txt",4,2,0,1,10000)
    stamp = t.time()
    territorial_eval_heurisick(board6.board.board_view ,1 , board6.board.qnumber, np.full((4,6,6), fill_value=999, dtype=np.short)  ,6)
    print("6x6 4 is white wc: ", t.time()-stamp, " seconds" )
    #8x8
    board8 = am.Amazons("../configs/config8x8.txt",4,2,0,1,10000)
    stamp = t.time()
    territorial_eval_heurisick(board8.board.board_view ,1 , board8.board.qnumber, np.full((4,8,8), fill_value=999, dtype=np.short)  ,6)
    print("8x8 4 is white wc: ", t.time()-stamp, " seconds" )
    #10x10
    board10 = am.Amazons("../configs/config10x10.txt", 4,2,0,1,10000)
    stamp = t.time()
    territorial_eval_heurisick(board10.board.board_view ,1 , board10.board.qnumber, np.full((4,10,10), fill_value=999, dtype=np.short)  ,6)
    print("10x10 4 is white wc: ", t.time()-stamp, " seconds" )
    
def tostr(board,n):
        return "{0}\n{1}".format(("   " + "  ".join([chr(ord("a") + y) for y in range(4)])), "\n".join(
            [(str(x + 1) + ("  " if x < 9 else " ")) + "  ".join(map(lambda x: ['■','·','♛','♕'][x+1], board[x])) for x in
             range(n - 1, -1, -1)]))

