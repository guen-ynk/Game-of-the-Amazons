#!python
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=True
#cython: nonecheck=False
#cython: initializedcheck=False

cimport cython
import os
import time
import player
import math
cimport numpy as np
import numpy as np
import multiprocessing
from libc.math cimport sqrt
#arrow -1
#empty  0
#white  1
#black  2
cdef extern from "math.h":
    double log(double x) nogil  

DTYPE = np.float64
ctypedef np.float64_t DTYPE_t

cdef DTYPE_t calculateUCB(DTYPE_t winsown, DTYPE_t countown, DTYPE_t winschild, DTYPE_t countchild ) nogil:
        cdef:
            DTYPE_t ratio_kid = winschild/countchild
            DTYPE_t visits_log = log(countown)
            DTYPE_t wurzel = sqrt((visits_log/countchild) * min(0.25, ratio_kid-(ratio_kid*ratio_kid), sqrt(2*visits_log/countchild)) )
        return (ratio_kid + wurzel)

cdef class Amazons:
    cdef: 
        unsigned short n,white_mode, black_mode
        list white_init, black_init
        public Board board
        public list player
        int MCTS

    def __init__(self, config="config.txt", A=1,B=1,MCTS=10000):
        info = open(config, "r")
        self.n = int(info.readline())
        white = info.readline().split(":")
        self.white_mode = int(white[0])
        self.white_init = list(map(alphabet2num, white[1].split()))
        black = info.readline().split(":")
        self.black_mode = int(black[0])
        self.black_init = list(map(alphabet2num, black[1].split()))
        self.player = [A,B]
        self.board = Board(self.n, self.white_init, self.black_init)
        self.MCTS = MCTS

    def game(self):
        cdef:
            np.ndarray[short, ndim=2] opso = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]],dtype=np.short)
            short [:,::1] ops = opso
        while True:
            for n, x in enumerate(self.player):
                if Board.iswon(self.board.board_view, self.board.wturn, self.board.qnumber, ops):
                    #print("No Moves possible", "black" if n else "white", "lost")
                    return not self.board.wturn
                if not x:
                    player.player(self.board) 
                elif x==1 or x==2:
                    self.board.board_view = AI.get_ai_move(self.board.board, x, self.board.wturn, self.board.qnumber, ops)
                    self.board.wturn = not self.board.wturn
                else:
                    self.board.board_view [...] = MonteCarloTreeSearchNode.best_action(MonteCarloTreeSearchNode(self.board.board, self.board.qnumber, self.board.wturn, None, None),self.MCTS, 0.1,ops)
                    self.board.wturn = not self.board.wturn
                #print(self.board)

    def __str__(self):
        return str(self.n) + " " + ["player", "AB", "MCTS"][self.white_mode] + str(self.white_init) + " " + ["player", "AB", "MCTS"][self.black_mode] + str(
            self.black_init) + "\n" + str(self.board)


cdef class Board:
    cdef public:
        np.npy_bool wturn 
        unsigned short size, qnumber
        np.ndarray board
        short[:,::1] board_view

    def __init__(self, size, white_init, black_init):
        self.wturn = True
        self.size = size
        self.board = np.zeros((size, size), dtype=np.short)  # fill size x size  with empty fields
        self.qnumber = len(white_init)
        self.board[tuple(zip(*white_init))] = 1  # fill in Amazons
        self.board[tuple(zip(*black_init))] = 2       
        self.board_view = self.board

   
    @staticmethod # max optimized 
    cdef short[:,::1] get_queen_pos(short[:, ::1] a,short color, unsigned short num, unsigned short adder):
      #  print(np.asarray(a))
        cdef:
            short[:, ::1] result_view = np.empty(shape=(num,2),dtype=np.short)
            unsigned short ind = 0
            size_t x,y,leng
        leng = a.shape[0]

        for x in range(leng):
            for y in range(leng):
                if a[x, y]==color:
                    result_view[ind, 0]= x+adder
                    result_view[ind, 1]= y+adder
                    ind+=1
                    if ind==num:
                        return result_view

    
   
    @staticmethod
    cdef short[:,::1] get_amazon_moves(short[:, ::1] board, short[::1] s, short[:,::1] boardx):
        cdef:
            list ret = []
            Py_ssize_t x, lengthb
            unsigned short y
           # short [:,::1] boardx = np.pad(board, 1, "constant", constant_values=-1)  

        lengthb = boardx.shape[0]
        for y in range(1,lengthb): # hardcode thanks to cython north 
            s[0]-=1
            if boardx[s[0],s[1]]==0:
                ret.append(np.array(s))
            else:
                s[0]+=y
                break
             
        for y in range(1,lengthb): # hardcode thanks to cython south
            s[0]+= 1
            if boardx[s[0],s[1]]==0:
                ret.append(np.array(s))
            else:
                s[0]-=y
                break
             
        for y in range(1,lengthb): # hardcode thanks to cython left
            s[1]-= 1
           # if 0 <= s[1] < lengthb:
            if boardx[s[0],s[1]]==0:
                ret.append(np.array(s))
            else:
                s[1]+=y
                break
             
        for y in range(1,lengthb): # hardcode thanks to cython  right
            s[1]+= 1
            if boardx[s[0],s[1]]==0:
                ret.append(np.array(s))
            else:
                s[1]-=y
                break
            
        for y in range(1,lengthb): # hardcode thanks to cython  south left
                    s[0]-= 1
                    s[1]-= 1
                    if boardx[s[0],s[1]]==0:
                        ret.append(np.array(s))
                    else:
                        s[0]+=y
                        s[1]+=y
                        break
                    
         
        for y in range(1,lengthb): # hardcode thanks to cython  south right
                    s[0]-= 1
                    s[1]+= 1
                    if boardx[s[0],s[1]]==0:
                        ret.append(np.array(s))
                    else:
                        s[0]+=y
                        s[1]-=y
                        break
         
        for y in range(1,lengthb): # hardcode thanks to cython  north left
                    s[0]+= 1
                    s[1]-= 1
                    if boardx[s[0],s[1]]==0:
                        ret.append(np.array(s))
                    else:
                        s[0]-=y
                        s[1]+=y
                        break
              
        for y in range(1,lengthb): # hardcode thanks to cython  north right
                    s[0]+= 1
                    s[1]+= 1
                    if boardx[s[0],s[1]]==0:
                        ret.append(np.array(s))
                    else:
                        s[0]-=y
                        s[1]-=y
                        break
        if len(ret)==0:
            return None
        return np.asarray(ret)
       
   
    @staticmethod
    cdef np.ndarray[short, ndim=3] fast_moves(short[:, ::1] board, unsigned short token, unsigned short qn):
        cdef:
            np.ndarray[short, ndim=2] boardx = np.pad(board, 1, "constant", constant_values=-1)  
            short[:,::1] amazons = Board.get_queen_pos(board, token, qn,1)
            short[:,::1] boardx_view = boardx
            short[:,::1] qmove
            short[::1] qmoveo = np.empty((2),dtype=np.short)

            Py_ssize_t j,s,x, lengthb
            list ret = []
            unsigned short y

        lengthb = boardx.shape[0]

        for s in range(qn):
            qmove = Board.get_amazon_moves(board, amazons[s], boardx_view)
            if qmove is None:
                continue
            for j in range(qmove.shape[0]):
                qmoveo[...] = qmove[j]
                # move 
                boardx_view[qmove[j,0],qmove[j,1]] = boardx_view[amazons[s,0],amazons[s,1]]
                boardx_view[amazons[s,0],amazons[s,1]] = 0
    
                for y in range(1,lengthb): # hardcode thanks to cython north 
                    qmove[j,0]-=1
                    if boardx_view[qmove[j,0],qmove[j,1]]==0:
                        ret.append(np.array([amazons[s],qmoveo, qmove[j]])-1)
                    else:
                        qmove[j,0]+=y
                        break
                    
                for y in range(1,lengthb): # hardcode thanks to cython south
                    qmove[j,0]+= 1
                    if boardx_view[qmove[j,0],qmove[j,1]]==0:
                        ret.append(np.array([amazons[s],qmoveo, qmove[j]])-1)
                    else:
                        qmove[j,0]-=y
                        break
                    
                for y in range(1,lengthb): # hardcode thanks to cython left
                    qmove[j,1]-= 1
                # if 0 <= qmove[j,1] < lengthb:
                    if boardx_view[qmove[j,0],qmove[j,1]]==0:
                        ret.append(np.array([amazons[s],qmoveo, qmove[j]])-1)
                    else:
                        qmove[j,1]+=y
                        break
                    
                for y in range(1,lengthb): # hardcode thanks to cython  right
                    qmove[j,1]+= 1
                    if boardx_view[qmove[j,0],qmove[j,1]]==0:
                        ret.append(np.array([amazons[s],qmoveo, qmove[j]])-1)
                    else:
                        qmove[j,1]-=y
                        break
                    
                for y in range(1,lengthb): # hardcode thanks to cython  south left
                            qmove[j,0]-= 1
                            qmove[j,1]-= 1
                            if boardx_view[qmove[j,0],qmove[j,1]]==0:
                                ret.append(np.array([amazons[s],qmoveo, qmove[j]])-1)
                            else:
                                qmove[j,0]+=y
                                qmove[j,1]+=y
                                break
                            
                for y in range(1,lengthb): # hardcode thanks to cython  south right
                            qmove[j,0]-= 1
                            qmove[j,1]+= 1
                            if boardx_view[qmove[j,0],qmove[j,1]]==0:
                                ret.append(np.array([amazons[s],qmoveo, qmove[j]])-1)
                            else:
                                qmove[j,0]+=y
                                qmove[j,1]-=y
                                break
                
                for y in range(1,lengthb): # hardcode thanks to cython  north left
                            qmove[j,0]+= 1
                            qmove[j,1]-= 1
                            if boardx_view[qmove[j,0],qmove[j,1]]==0:
                                ret.append(np.array([amazons[s],qmoveo, qmove[j]])-1)
                            else:
                                qmove[j,0]-=y
                                qmove[j,1]+=y
                                break
                    
                for y in range(1,lengthb): # hardcode thanks to cython  north right
                            qmove[j,0]+= 1
                            qmove[j,1]+= 1
                            if boardx_view[qmove[j,0],qmove[j,1]]==0:
                                ret.append(np.array([amazons[s],qmoveo, qmove[j]])-1)
                            else:
                                qmove[j,0]-=y
                                qmove[j,1]-=y
                                break

                # undo queen move
                boardx_view[amazons[s,0],amazons[s,1]] = boardx_view[qmove[j,0],qmove[j,1]]
                boardx_view[qmove[j,0],qmove[j,1]] = 0

        return np.asarray(ret)
      
      
   
    @staticmethod
    cdef np.npy_bool iswon(short[:, ::1] board ,np.npy_bool wturn, unsigned short qn, short [:,::1] ops):

        cdef:
            short[:,::1] amazons = Board.get_queen_pos(board, 1 if wturn else 2, qn, 0)
            Py_ssize_t x,leng,i,opsl

        opsl = 8
        leng = board.shape[0]
        for i in range(amazons.shape[0]):
            for x in range(opsl):
                amazons[i,0]+=ops[x,0]
                amazons[i,1]+=ops[x,1]

                if 0 <= amazons[i,0] < leng and 0 <= amazons[i,1] < leng:
                    if board[amazons[i,0], amazons[i,1]] == 0:
                        return False
                amazons[i,0]-=ops[x,0]
                amazons[i,1]-=ops[x,1]
        return True

    def __str__(self):
        return "{0}\n{1}".format(("   " + "  ".join([chr(ord("a") + y) for y in range(self.size)])), "\n".join(
            [(str(x + 1) + ("  " if x < 9 else " ")) + "  ".join(map(lambda x: ['■','.','W','B'][x+1], self.board[x])) for x in
             range(self.size - 1, -1, -1)]))

cdef class Heuristics:
    
    @staticmethod
    cdef list getMovesInRadius(short[:,::1] board,short[:,::1] check,short [::1] s,unsigned short depth, short[:,::1] boardh):
        cdef:
            list ret = []
            Py_ssize_t x, lengthb
            unsigned short y
            short [:,::1] boardx = np.pad(board, 1, "constant", constant_values=-1)  

        lengthb = boardx.shape[0]
        for y in range(1,lengthb): # hardcode thanks to cython north 
            s[0]-=1
            if boardx[s[0],s[1]]==0:
                if not check[s[0]-1,s[1]-1]:
                        boardh[s[0]-1,s[1]-1] = min(
                            boardh[s[0]-1,s[1]-1],
                            depth
                        )
                        check[s[0]-1,s[1]-1] = 1
                        ret.append(s)
            else:
                s[0]+=y
                break
             
        for y in range(1,lengthb): # hardcode thanks to cython south
            s[0]+= 1
            if boardx[s[0],s[1]]==0:
                if not check[s[0]-1,s[1]-1]:
                        boardh[s[0]-1,s[1]-1] = min(
                            boardh[s[0]-1,s[1]-1],
                            depth
                        )
                        check[s[0]-1,s[1]-1] = 1
                        ret.append(s)
            else:
                s[0]-=y
                break
             
        for y in range(1,lengthb): # hardcode thanks to cython left
            s[1]-= 1
           # if 0 <= s[1] < lengthb:
            if boardx[s[0],s[1]]==0:
                if not check[s[0]-1,s[1]-1]:
                        boardh[s[0]-1,s[1]-1] = min(
                            boardh[s[0]-1,s[1]-1],
                            depth
                        )
                        check[s[0]-1,s[1]-1] = 1
                        ret.append(s)
            else:
                s[1]+=y
                break
             
        for y in range(1,lengthb): # hardcode thanks to cython  right
            s[1]+= 1
            if boardx[s[0],s[1]]==0:
                if not check[s[0]-1,s[1]-1]:
                        boardh[s[0]-1,s[1]-1] = min(
                            boardh[s[0]-1,s[1]-1],
                            depth
                        )
                        check[s[0]-1,s[1]-1] = 1
                        ret.append(s)
            else:
                s[1]-=y
                break
            
        for y in range(1,lengthb): # hardcode thanks to cython  south left
                    s[0]-= 1
                    s[1]-= 1
                    if boardx[s[0],s[1]]==0:
                        if not check[s[0]-1,s[1]-1]:
                            boardh[s[0]-1,s[1]-1] = min(
                                boardh[s[0]-1,s[1]-1],
                                depth
                            )
                            check[s[0]-1,s[1]-1] = 1
                            ret.append(s)
                    else:
                        s[0]+=y
                        s[1]+=y
                        break
                    
         
        for y in range(1,lengthb): # hardcode thanks to cython  south right
                    s[0]-= 1
                    s[1]+= 1
                    if boardx[s[0],s[1]]==0:
                        if not check[s[0]-1,s[1]-1]:
                            boardh[s[0]-1,s[1]-1] = min(
                                boardh[s[0]-1,s[1]-1],
                                depth
                            )
                            check[s[0]-1,s[1]-1] = 1
                            ret.append(s)
                    else:
                        s[0]+=y
                        s[1]-=y
                        break
         
        for y in range(1,lengthb): # hardcode thanks to cython  north left
                    s[0]+= 1
                    s[1]-= 1
                    if boardx[s[0],s[1]]==0:
                        if not check[s[0]-1,s[1]-1]:
                            boardh[s[0]-1,s[1]-1] = min(
                                boardh[s[0]-1,s[1]-1],
                                depth
                            )
                            check[s[0]-1,s[1]-1] = 1
                            ret.append(s)
                    else:
                        s[0]-=y
                        s[1]+=y
                        break
              
        for y in range(1,lengthb): # hardcode thanks to cython  north right
                    s[0]+= 1
                    s[1]+= 1
                    if boardx[s[0],s[1]]==0:
                        if not check[s[0]-1,s[1]-1]:
                            boardh[s[0]-1,s[1]-1] = min(
                                boardh[s[0]-1,s[1]-1],
                                depth
                            )
                            check[s[0]-1,s[1]-1] = 1
                            ret.append(s)
                    else:
                        s[0]-=y
                        s[1]-=y
                        break

        return ret
    
    @staticmethod
    cdef amazonBFS(short [:,::1] board, short[::1] s, short[:,::1] hboard):
        cdef:
            Py_ssize_t x,n,m
            list movesebene, temp
            list moves = [s]
            short [:,::1] checkboard = np.zeros_like(hboard)

        for x in range(1, board.shape[0]**2):
            movesebene = []
            for m in range(len(moves)):
                temp = Heuristics.getMovesInRadius(board, checkboard, moves[m], x, hboard)
                for n in range(len(temp)):
                    movesebene.append(temp[n])
            moves = movesebene
            if len(moves) == 0:
                break

    
    @staticmethod
    cdef DTYPE_t territorial_eval_heurisic(short[:,::1]board,short token,unsigned short qn):
        cdef:
            Py_ssize_t a,i,j
            DTYPE_t ret = 0.0

            np.ndarray[short, ndim=2] wboardo = np.full((board.shape[0],board.shape[0]), fill_value=999, dtype=np.short)
            np.ndarray[short, ndim=2] bboardo = np.full((board.shape[0],board.shape[0]), fill_value=999, dtype=np.short)

            short [:,::1] wboard = wboardo
            short [:,::1] bboard = bboardo
            short [:,::1] amazons = Board.get_queen_pos(board, 1, qn, 1)

        for a in range(amazons.shape[0]):
            Heuristics.amazonBFS(board, amazons[a], wboard)

        amazons = Board.get_queen_pos(board, 2, qn, 1)
        for a in range(amazons.shape[0]):
            Heuristics.amazonBFS(board, amazons[a], bboard)
        
        for i in range(board.shape[0]):
            for j in range(board.shape[0]):
                if wboard[i,j] == bboard[i,j] and wboard[i,j] != 999:
                        ret += 1 / 5
                else: 
                    if token == 1:
                        if wboard[i,j] < bboard[i,j]:
                            ret += 1
                        else:
                            ret -= 1
                    else:
                        if wboard[i,j] > bboard[i,j]:
                            ret += 1
                        else:
                            ret -= 1
        return ret
   
    
    @staticmethod
    cdef DTYPE_t move_count( short[:, ::1] board, unsigned short token, unsigned short qn):
        cdef:
            np.ndarray[short, ndim=2] boardx = np.pad(board, 1, "constant", constant_values=-1)  
            short[:,::1] amazons = Board.get_queen_pos(board, token, qn,1)
            short[:,::1] boardx_view = boardx
            short[:,::1] qmove
            Py_ssize_t j,s,x, lengthb
            DTYPE_t ret = 0.0
            unsigned short y

        lengthb = boardx.shape[0]
        for s in range(qn):
            qmove = Board.get_amazon_moves(board, amazons[s],boardx_view)
            if qmove is None:
                continue
            for j in range(qmove.shape[0]):
                # move 
                boardx_view[qmove[j,0],qmove[j,1]] = boardx_view[amazons[s,0],amazons[s,1]]
                boardx_view[amazons[s,0],amazons[s,1]] = 0
    
                for y in range(1,lengthb): # hardcode thanks to cython north 
                    qmove[j,0]-=1
                    if boardx_view[qmove[j,0],qmove[j,1]]==0:
                        ret+=1.0
                    else:
                        qmove[j,0]+=y
                        break
                    
                for y in range(1,lengthb): # hardcode thanks to cython south
                    qmove[j,0]+= 1
                    if boardx_view[qmove[j,0],qmove[j,1]]==0:
                        ret+=1.0
                    else:
                        qmove[j,0]-=y
                        break
                    
                for y in range(1,lengthb): # hardcode thanks to cython left
                    qmove[j,1]-= 1
                # if 0 <= qmove[j,1] < lengthb:
                    if boardx_view[qmove[j,0],qmove[j,1]]==0:
                        ret+=1.0
                    else:
                        qmove[j,1]+=y
                        break
                    
                for y in range(1,lengthb): # hardcode thanks to cython  right
                    qmove[j,1]+= 1
                    if boardx_view[qmove[j,0],qmove[j,1]]==0:
                        ret+=1.0
                    else:
                        qmove[j,1]-=y
                        break
                    
                for y in range(1,lengthb): # hardcode thanks to cython  south left
                            qmove[j,0]-= 1
                            qmove[j,1]-= 1
                            if boardx_view[qmove[j,0],qmove[j,1]]==0:
                                ret+=1.0
                            else:
                                qmove[j,0]+=y
                                qmove[j,1]+=y
                                break
                            
                
                for y in range(1,lengthb): # hardcode thanks to cython  south right
                            qmove[j,0]-= 1
                            qmove[j,1]+= 1
                            if boardx_view[qmove[j,0],qmove[j,1]]==0:
                                ret+=1.0
                            else:
                                qmove[j,0]+=y
                                qmove[j,1]-=y
                                break
                
                for y in range(1,lengthb): # hardcode thanks to cython  north left
                            qmove[j,0]+= 1
                            qmove[j,1]-= 1
                            if boardx_view[qmove[j,0],qmove[j,1]]==0:
                                ret+=1.0
                            else:
                                qmove[j,0]-=y
                                qmove[j,1]+=y
                                break
                    
                for y in range(1,lengthb): # hardcode thanks to cython  north right
                            qmove[j,0]+= 1
                            qmove[j,1]+= 1
                            if boardx_view[qmove[j,0],qmove[j,1]]==0:
                                ret+=1.0
                            else:
                                qmove[j,0]-=y
                                qmove[j,1]-=y
                                break


                # undo queen move
                boardx_view[amazons[s,0],amazons[s,1]] = boardx_view[qmove[j,0],qmove[j,1]]
                boardx_view[qmove[j,0],qmove[j,1]] = 0
        return ret
    
    

cdef class AI:
   
    @staticmethod
    cdef short[:,::1] get_ai_move(short[:, ::1] board, int mode, np.npy_bool owturn, unsigned short qnumber, short[:,::1] ops):  
        cdef:
            DTYPE_t best_score = -1000000.0
            unsigned short token = 1 if owturn else 2
            short[:, :, ::1] MOVES_view =  Board.fast_moves(board, token, qnumber)
            DTYPE_t score
            short[:,::1] best_move
            np.npy_bool wturn = owturn
            unsigned short depth = 2 if MOVES_view.shape[0] > 25 else 4
            Py_ssize_t i
        
        for i in range(MOVES_view.shape[0]):

            # move
            board[MOVES_view[i,1,0], MOVES_view[i,1,1]] = token
            board[MOVES_view[i,0,0], MOVES_view[i,0,1]] = 0
            board[MOVES_view[i,2,0], MOVES_view[i,2,1]] = -1

            score = AI.alphabeta(board,not wturn, qnumber, 2, best_score, 1000000.0, False, mode, ops)
          
            # undo 
            board[MOVES_view[i,2,0], MOVES_view[i,2,1]] = 0
            board[MOVES_view[i,1,0], MOVES_view[i,1,1]] = 0
            board[MOVES_view[i,0,0], MOVES_view[i,0,1]] = token
     
            if score > best_score:
                best_score = score
                best_move = MOVES_view[i]
            
        
        board[best_move[1,0], best_move[1,1]] = token
        board[best_move[0,0], best_move[0,1]] = 0
        board[best_move[2,0], best_move[2,1]] = -1
        return board
    
   
    @staticmethod
    cdef DTYPE_t alphabeta(short[:, ::1] board,np.npy_bool wturn, unsigned short qn, unsigned short depth, DTYPE_t a, DTYPE_t b, np.npy_bool maximizing, int mode, short[:,::1] ops):
        cdef:
            DTYPE_t heuval
            np.npy_bool token = 1 if wturn else 2

        if depth == 0 or Board.iswon(board, wturn, qn, ops):
            if mode == 1:
                if wturn:
                    return Heuristics.move_count(board, 1, qn)-Heuristics.move_count(board, 2, qn)
                else:
                    return Heuristics.move_count(board, 2, qn)-Heuristics.move_count(board, 1, qn)

            else:
                return Heuristics.territorial_eval_heurisic(board, token, qn)

      
        cdef:
            DTYPE_t best_score
            short[:, :, ::1] MOVES_view = Board.fast_moves(board, token, qn)
            np.ndarray[short, ndim=1] indicies = np.arange(MOVES_view.shape[0],dtype=np.short)
            Py_ssize_t i

        np.random.shuffle(indicies) # randomizer ->>>>>>>>>>>>>>> good speedup somehow

        if maximizing:
            best_score = -1000000.0
            for i in range(indicies.shape[0]):

                # do move
                board[MOVES_view[indicies[i],1,0], MOVES_view[indicies[i],1,1]] = token # unpythonic way .. thanks to cython
                board[MOVES_view[indicies[i],0,0], MOVES_view[indicies[i],0,1]] = 0
                board[MOVES_view[indicies[i],2,0], MOVES_view[indicies[i],2,1]] = -1

                best_score = max(best_score, AI.alphabeta(board, not wturn, qn, depth - 1, a, b, False, mode,ops))
                
                # undo 
                board[MOVES_view[indicies[i],2,0], MOVES_view[indicies[i],2,1]] = 0
                board[MOVES_view[indicies[i],1,0], MOVES_view[indicies[i],1,1]] = 0
                board[MOVES_view[indicies[i],0,0], MOVES_view[indicies[i],0,1]] = token
                a = max(a, best_score)
                if b <= best_score:
                    break
        else:
            best_score = 1000000.0

            for i in range(indicies.shape[0]):

                # move
                board[MOVES_view[indicies[i],1,0], MOVES_view[indicies[i],1,1]] = token
                board[MOVES_view[indicies[i],0,0], MOVES_view[indicies[i],0,1]] = 0
                board[MOVES_view[indicies[i],2,0], MOVES_view[indicies[i],2,1]] = -1

                best_score = min(best_score, AI.alphabeta(board,not wturn, qn, depth - 1, a, b, True, mode,ops))
                
                # undo 
                board[MOVES_view[indicies[i],2,0], MOVES_view[indicies[i],2,1]] = 0
                board[MOVES_view[indicies[i],1,0], MOVES_view[indicies[i],1,1]] = 0
                board[MOVES_view[indicies[i],0,0], MOVES_view[indicies[i],0,1]] = token
                b = min(b, best_score)
                if best_score <= a:
                    break
        return best_score

cdef class MonteCarloTreeSearchNode():
    cdef public:
        np.npy_bool wturn 
        unsigned short qnumber
        short[:,::1] board
        MonteCarloTreeSearchNode parent
        list children, _untried_actions
        DTYPE_t wins, loses, _number_of_visits
        short [:,::1] parent_action

    def __cinit__(self,short[:,::1] bv,unsigned short qn,np.npy_bool wt,MonteCarloTreeSearchNode parent,short [:,::1] parent_action):
        self.board = bv
        self.qnumber = qn
        self.wturn = wt
        self.parent = parent
        self.parent_action = parent_action
        self.children = []
        self._number_of_visits = 0.0
        self.wins = 0.0
        self.loses = 0.0
        self._untried_actions = list(Board.fast_moves(self.board, 1 if self.wturn else 2, self.qnumber))

    @staticmethod
    cdef MonteCarloTreeSearchNode expand(MonteCarloTreeSearchNode this):
        cdef short[:,::1] oboard = this.board
        cdef short[:,::1] action = this._untried_actions.pop()
        cdef short[:,::1] next_state = np.empty_like(this.board, dtype=np.short)
        next_state[...] = oboard
        next_state[action[1,0],action[1,1]] = 1 if this.wturn else 2
        next_state[action[0,0],action[0,1]] = 0 
        next_state[action[2,0],action[2,1]] = -1

        child_node = MonteCarloTreeSearchNode(
            next_state, this.qnumber, not this.wturn, parent=this, parent_action=action)

        this.children.append(child_node)
        return child_node 

    @staticmethod
    cdef short rollout(MonteCarloTreeSearchNode this):
        cdef:
            short[:,::1] oboard = this.board
            short[:,::1] current_rollout_state  = np.empty_like(this.board)
            short[:,:,::1] possible_moves
            np.npy_bool current_wturn = this.wturn
            Py_ssize_t ind
            np.ndarray[short, ndim=2] opso = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]],dtype=np.short)
            short [:,::1] ops = opso
        current_rollout_state [...] = oboard

        while not Board.iswon(current_rollout_state, current_wturn, this.qnumber, ops):
            possible_moves = Board.fast_moves(current_rollout_state, 1 if current_wturn else 2, this.qnumber)
            ind = np.random.randint(possible_moves.shape[0])
            action = possible_moves[ind]

            current_rollout_state[possible_moves[ind,1,0],possible_moves[ind,1,1]] = 1 if current_wturn else 2
            current_rollout_state[possible_moves[ind,0,0],possible_moves[ind,0,1]] = 0 
            current_rollout_state[possible_moves[ind,2,0],possible_moves[ind,2,1]] = -1
            current_wturn = not current_wturn

        # current_rollout_state.wturn verlierer
        return -1 if current_wturn == this.wturn else 1

    @staticmethod
    cdef void backpropagate(MonteCarloTreeSearchNode this, short result):
        this._number_of_visits +=1.0
        if result == 1:
            this.wins+=1.0
        else:
            this.loses+=1.0

        if this.parent:
            MonteCarloTreeSearchNode.backpropagate(this.parent, result)
        return
    
    @staticmethod
    cdef MonteCarloTreeSearchNode best_child(MonteCarloTreeSearchNode this, DTYPE_t c_param):
        cdef:
            MonteCarloTreeSearchNode best = None
            DTYPE_t best_score = -1000.0
            DTYPE_t score
            DTYPE_t wins = this.wins
            DTYPE_t _number_of_visits = this._number_of_visits
            DTYPE_t cw,cn
            MonteCarloTreeSearchNode c

        for c in this.children:
            # original score
            #score = ((c.wins - c.loses) / c._number_of_visits) + c_param * np.sqrt((2 * logownvisits  / c._number_of_visits))
            cw = c.wins
            cn = c._number_of_visits
            # paper score
            score = calculateUCB(wins, _number_of_visits, cw, cn)
            
            if score > best_score:
                best_score = score
                best = c

        return best
    
    @staticmethod
    cdef MonteCarloTreeSearchNode tree_policy(MonteCarloTreeSearchNode this, DTYPE_t c_param, short[:,::1] ops):
        cdef:
            MonteCarloTreeSearchNode current_node = this
            Py_ssize_t length

        while not Board.iswon(current_node.board, current_node.wturn, current_node.qnumber, ops):
            length = len(current_node._untried_actions)
            if length != 0:
                return MonteCarloTreeSearchNode.expand(current_node)
            else:
                current_node = MonteCarloTreeSearchNode.best_child(current_node, c_param)

        return current_node

    @staticmethod
    cdef short[:,::1] best_action(MonteCarloTreeSearchNode this, unsigned short simulation_no, DTYPE_t c_param, short[:,::1]ops):        
        cdef:
            MonteCarloTreeSearchNode value
            short reward
            unsigned short i
           
        for i in range(simulation_no):
            
            v = MonteCarloTreeSearchNode.tree_policy(this,c_param, ops)
            reward = MonteCarloTreeSearchNode.rollout(v)
            MonteCarloTreeSearchNode.backpropagate(v, reward)
        
        return MonteCarloTreeSearchNode.best_child(this, c_param).board

cpdef alphabet2num(pos_raw):
    return int(pos_raw[1:]) - 1, ord(pos_raw[0]) - ord('a')


def main(times=100,inputfile= "3x3",A=1,B=1,MCTS=10000):
  

    def temp(i,q,inputfile, num,A,B,MCTS):
        cdef Amazons field
        cdef int f = 0
        for _ in range(num):    
            field = Amazons("../configs/config"+inputfile+".txt",A,B,MCTS)
            np.random.seed()
            f += int(field.game())
        q.put(f)

    print(os.cpu_count(), ": CPU COUNT")
    countcpu = os.cpu_count()
    balance = int(times/countcpu)
    processes =[]
    q = multiprocessing.Queue()
    stamp = time.time()
    for i in range(countcpu):
        p = multiprocessing.Process(target=temp,args=(str(i),q,inputfile,balance,A,B,MCTS)) 
        p.start()
        processes.append(p)
    for p in processes:
        p.join()

    results = [q.get() for j in processes]
    print(results)

    f = open("res.txt", "a")
    f.write(str(time.time()-stamp)+"\n"+"white wins: "+str(sum(results))+"\n"+str(times)+ "A: "+str(A)+"B: "+str(B)+"MCTS: "+str(MCTS)+"\n\n")
    f.close()

    #print("white wins: ", white)
    #print("black wins: ", black)
    #3x3
    #white wins:  73    1
    #black wins:  27    3 10000
    #white wins:  91    3 10000
    #black wins:  9     1
    #59/ 100 MCTS


#75.7377610206604
#white wins: 94
#100
    # übergabe von queens
    # boardx übertrag
    # boundary instead of boardx