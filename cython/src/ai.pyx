#!python
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=True
#cython: nonecheck=False
#cython: initializedcheck=False

cimport cython
from libc.stdlib cimport free 
from libc.time cimport time,time_t

from structures cimport _MovesStruct
from numpy cimport npy_bool
from board cimport Board
from heuristics cimport move_count, territorial_eval_heurisic, territorial_eval_heurisick
'''
    @class:
        AI ( Alpha Beta prunning)
    @info:
        provides functions for choosing the next move, utilizing alphabeta and heuristics
        whole class 100% C - no GIL
'''
 
'''
    @args:
        board memview, mode 1 or 2 -> see choosing heuristic, its white turn y/n?, # of amazons per side, operations, (TEH) heuristic board white and black
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

cdef void get_ai_move(short[:, ::1] board, int mode, npy_bool wturn, unsigned short qnumber, short[:,::1] ops,short[:,:,::1] hb, unsigned int param, time_t ressources) nogil:  
    cdef:
        DTYPE_t best_score = -1000000.0
        DTYPE_t rbest_score = 1000000.0
        DTYPE_t score = 0.0
        time_t timestamp

        unsigned short token = 1 if wturn else 2

        _MovesStruct*_ptr = NULL
        _MovesStruct*_head = Board.fast_moves(board, token, qnumber)
        _MovesStruct*best_move = NULL
        unsigned short depth = 2 if _head.length > 50 else 8

    while _head is not NULL:
        timestamp = time(NULL)
        # move
        board[_head.dx,_head.dy] = token
        board[_head.sx,_head.sy] = 0
        board[_head.ax,_head.ay] = -1

        score = alphabeta(board,not wturn, qnumber, 2, best_score, rbest_score, False, mode, ops, hb, wturn, param-1)
        # undo 
        board[_head.ax,_head.ay] = 0
        board[_head.dx,_head.dy] = 0
        board[_head.sx,_head.sy] = token
        
        if score > best_score:
            best_score = score
            _ptr = best_move
            best_move = _head
        else:
            _ptr = _head

        _head = _head.next
        free(_ptr)

        timestamp= (time(NULL) - timestamp)
        
        ressources-= timestamp
        
        if ressources <= 0:
            while _head is not NULL:
                _ptr = _head
                _head = _head.next
                free(_ptr)
            break    
        
    board[best_move.dx, best_move.dy] = token
    board[best_move.sx, best_move.sy] = 0
    board[best_move.ax, best_move.ay] = -1
    free(best_move)
    return 

'''
    @args:
        board memview,  its white turn y/n?, # of amazons per side, depth of AB, alpha, beta, maximizing?, mode 1 or 2 -> see choosing heuristic,operations, (TEH) heuristic board white and black, origin color 
    @info:
        function for alphabeta prunning
    @return:
        the alphabeta values for the calling AB instance
'''
cdef DTYPE_t alphabeta(short[:, ::1] board,npy_bool wturn, unsigned short qn, unsigned short depth, DTYPE_t a, DTYPE_t b, npy_bool maximizing, int mode, short[:,::1] ops,short[:,:,::1] hb, npy_bool callerwturn, unsigned int param)nogil:
    cdef:
        DTYPE_t heuval1,heuval2
        short token = 1 if wturn else 2

    if depth == 0 or Board.iswon(board,token, qn, ops):
        if mode == 1:
            heuval1 = move_count(board, 1, qn)
            heuval2 = move_count(board, 2, qn)
            
            if callerwturn:
                return heuval1-heuval2
            else:
                return heuval2-heuval1

        elif mode == 2:
            if callerwturn:
                return territorial_eval_heurisic(board, 1, qn,hb)
            else:
                return territorial_eval_heurisic(board, 2, qn,hb)
        else:
            if callerwturn:
                return territorial_eval_heurisick(board, 1, qn,hb, param)
            else:
                return territorial_eval_heurisick(board, 2, qn,hb, param)
    cdef:
        DTYPE_t score = 0.0
        _MovesStruct*_ptr = NULL
        _MovesStruct*_head = Board.fast_moves(board, token, qn)

    if maximizing:
        while _head is not NULL:

            # do move
            board[_head.dx,_head.dy] = token
            board[_head.sx,_head.sy] = 0
            board[_head.ax,_head.ay] = -1

            score = alphabeta(board, not wturn, qn, depth - 1, a, b, False, mode,ops,hb, callerwturn, param-1)
            
            # undo 
            board[_head.ax,_head.ay] = 0
            board[_head.dx,_head.dy] = 0
            board[_head.sx,_head.sy] = token

            a = max(a, score)
            if b <= a:
                break
            _ptr = _head
            _head = _head.next
            free(_ptr)
    else:
        while _head is not NULL:

            # move
            board[_head.dx,_head.dy] = token
            board[_head.sx,_head.sy] = 0
            board[_head.ax,_head.ay] = -1

            score = alphabeta(board,not wturn, qn, depth - 1, a, b, True, mode,ops,hb, callerwturn, param-1)
            
            # undo 
            board[_head.ax,_head.ay] = 0
            board[_head.dx,_head.dy] = 0
            board[_head.sx,_head.sy] = token

            b = min(b, score)
            if b <= a:
                break
            _ptr = _head
            _head = _head.next
            free(_ptr)
            
    while _head is not NULL:
        _ptr = _head
        _head = _head.next
        free(_ptr)
    return score