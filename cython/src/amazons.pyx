#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False

'''
   @author: Guen Yanik, 2021
   @startup: run python setup.py build_ext --inplace & run.py
   @info:
        Cython Version of 'Game of the Amazons' for Boards of size nxn,
        to setup Board create nxnconfig.txt with startpositions of m queens
        -> also see /configs for examples

        Player modes: 
        0 human
        1 AlphaBeta - Mobility eval heuristic
        2 Alphabeta - Territorial eval heuristic
        3 MCTS      - k Games per turn

        for multithreading see run.py 

'''

cimport cython
import player
from structures cimport _LinkedListStruct, _MCTS_Node, newnode
from board cimport Board
import board  
import sqlite3
import numpy as np
cimport numpy as np
from plainmcts cimport best_action
from newmcts cimport best_action_op, get_amazon_moves, filteramazons
from ai cimport get_ai_move
from libc.time cimport time,time_t

DTYPE = np.float64
ctypedef np.float64_t DTYPE_t

 
cdef class Amazons:
    cdef: 
        unsigned short n
        list white_init, black_init
        public Board board
        public list player
        unsigned long MCTS
        int id
        time_t ressources

    def __init__(self, config="config.txt", A=1,B=1,MCTS=10000, j=1, ressources=20):
        info = open(config, "r")
        self.n = int(info.readline())
        self.white_init = list(map(alphabet2num, info.readline().split()))
        self.black_init = list(map(alphabet2num, info.readline().split()))
        self.player = [A,B]
        self.board = Board(self.n, self.white_init, self.black_init)
        self.MCTS = MCTS
        self.id = j
        self.ressources = ressources

    cdef game(self):
        cdef:
            short [:,::1] ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]],dtype=np.short)
            short token
            Py_ssize_t bsize = self.board.board.shape[0]
            short [:,:,::1] hboard = np.full((4,bsize,bsize), fill_value=999, dtype=np.short)  
            short [:,::1] copyboard = np.empty((bsize, bsize), dtype=np.short)
            _MCTS_Node*root = NULL
            _MCTS_Node*rooto = NULL
            _LinkedListStruct*amazon = NULL
            unsigned int param = (self.board.size**2)-(2*self.board.qnumber)

        while True:
            for n, x in enumerate(self.player):
                token = 1 if self.board.wturn else 2
                if Board.iswon(self.board.board_view, token, self.board.qnumber, ops):
                    print(self.board)
                    return not self.board.wturn
                print(self.board)

                if not x:
                    player.player(self.board) 
                elif x==1 or x==2 or x==4:
                   
                    get_ai_move(self.board.board_view, x, self.board.wturn, self.board.qnumber, ops, hboard, param, self.ressources)
                 
                    self.board.wturn = not self.board.wturn
                else:
                    if x==3:
                        root = newnode(NULL,self.board.wturn, self.board.qnumber, NULL)
                        root._untried_actions = Board.fast_moves(self.board.board_view, root.token, root.qnumber)
                        best_action(root,self.MCTS, 0.1,ops,self.board.board_view, copyboard, self.id, self.ressources)
                    else:
                        rooto = newnode(NULL,self.board.wturn, self.board.qnumber, NULL)
                        amazon = Board.get_queen_posn(self.board.board_view, 1 if self.board.wturn else 2, self.board.qnumber)
                        amazon = filteramazons(amazon, rooto.backtoken, self.board.board_view, ops)
                        rooto._untried_actions = get_amazon_moves(self.board.board_view, amazon, False)
                        best_action_op(rooto,self.MCTS, 0.1,ops,self.board.board_view, copyboard, self.id, self.ressources)
                        rooto = NULL
                    self.board.wturn = not self.board.wturn
                
                param -= 1

    
'''
        @args:
            fen format move string
        
        @return:
            board coordinate format tuple
'''
cpdef alphabet2num(pos_raw):
    return int(pos_raw[1:]) - 1, ord(pos_raw[0]) - ord('a')

'''
        @args:
            threadID, Processqueue, #simulations, "nxn" for the respective file, A:mode 0 1 2 3, B:mode 0 1 2 3, MCTS: #simulations per turn
        @info:
            MAIN ENTRANCE
        @return:
            nothing but performs the simulations and stores the results in the queue
'''
def main(i,q, times,inputfile,A,B,MCTS, res):
    cdef int j = i
    cdef Amazons field
    cdef int f = 0
    cdef int k 
    for k in range(times):    
        field = Amazons("../configs/config"+inputfile+".txt",A,B,MCTS,j+k, res) 
        f += int(field.game())
  
    FIL = open("stableres.txt", "a")
    FIL.write("wins:"+str(f)+ " A:"+str(A)+" B:"+str(B)+" MCTS:"+str(MCTS) + " time:"+str(res) +"\n")
    FIL.close()


def simulate(times=1,inputfile="6x6",A=4,B=4,MCTS=10000, res=100000):
    import time
    cdef Amazons field
    stamp = time.time()
    for _ in range(times):    
        field = Amazons("../configs/config"+inputfile+".txt",A,B,MCTS,0, res)
        print( field.game(), time.time()-stamp)
