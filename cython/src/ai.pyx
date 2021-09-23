#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False
# @author: Guen Yanik, 2021


cimport cython
from libc.stdlib cimport free 
from libc.time cimport time,time_t

from structures cimport _MovesStruct
from numpy cimport npy_bool
from board cimport Board
from heuristics cimport move_count, territorial_eval_heurisic, territorial_eval_heurisick

cdef void get_ai_move(short[:, ::1] board, int mode, npy_bool wturn, unsigned short qnumber, short[:,::1] ops,short[:,:,::1] hb, unsigned int param, time_t ressources) nogil:  
    cdef:
        DTYPE_t best_score = -1000000.0
        DTYPE_t score = 0.0
        time_t timestamp
        unsigned short token = 1 if wturn else 2

        _MovesStruct*_ptr = NULL
        _MovesStruct*_best_move = NULL
        _MovesStruct*_head = Board.fast_moves(board, token, qnumber)
        unsigned short depth = 2 if param > 10 else 6

    while _head is not NULL:
        timestamp = time(NULL)
        # move
        board[_head.dx,_head.dy] = token
        board[_head.sx,_head.sy] = 0
        board[_head.ax,_head.ay] = -1

        score = alphabeta(board,not wturn, qnumber, depth, best_score, 1000000.0, False, mode, ops, hb, wturn, param-1)#depth
        # undo 
        board[_head.ax,_head.ay] = 0
        board[_head.dx,_head.dy] = 0
        board[_head.sx,_head.sy] = token
        
        if score > best_score:
            best_score = score
            _ptr = _best_move
            _best_move = _head
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
        
    board[_best_move.dx, _best_move.dy] = token
    board[_best_move.sx, _best_move.sy] = 0
    board[_best_move.ax, _best_move.ay] = -1
    free(_best_move)
    return 


cdef DTYPE_t alphabeta(short[:, ::1] board,npy_bool wturn, unsigned short qn, unsigned short depth, DTYPE_t a, DTYPE_t b, npy_bool maximizing, int mode, short[:,::1] ops,short[:,:,::1] hb, npy_bool callerwturn, unsigned int param)nogil:
    cdef:
        DTYPE_t val,heuval1,heuval2
        short token = 1 if wturn else 2
        short nottoken = 2 if wturn else 1
    val = 0.0

    if depth == 0 or Board.iswon(board,token, qn, ops):
        if Board.iswon(board,nottoken, qn, ops):
            if callerwturn == wturn:
                val = -1.0
            else:
                val = 1.0
        else:
            if callerwturn == wturn:
                val = 1.0
            else:
                val = -1.0
        if mode == 1:
            heuval1 = move_count(board, 1, qn)
            heuval2 = move_count(board, 2, qn)
            
            if callerwturn:
                return heuval1-heuval2+val
            else:
                return heuval2-heuval1+val

        elif mode == 2:
            if callerwturn:
                return territorial_eval_heurisic(board, 1, qn,hb)+val
            else:
                return territorial_eval_heurisic(board, 2, qn,hb)+val
        else:
            if callerwturn:
                return territorial_eval_heurisick(board, 1, qn,hb, param)+val
            else:
                return territorial_eval_heurisick(board, 2, qn,hb, param)+val
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