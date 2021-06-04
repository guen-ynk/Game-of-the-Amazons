#!python
#cython: language_level=3
import copy as cp
import time
import numpy as np
cimport numpy as np
cimport cython

cdef int INF = 1000000
cdef MODES = ["player", "AB", "MCTS"]

# codes
cdef short NARROW, NEMPTY, NWHITEQ, NBLACKQ
NARROW = -1
NEMPTY = 0
NWHITEQ = 1
NBLACKQ = 2

cdef class Amazons:
    cdef unsigned short n,white_mode, black_mode
    cdef list white_init, black_init, player
    cdef object board

    def __init__(self, config="config.txt"):
        info = open(config, "r")
        self.n = int(info.readline())
        white = info.readline().split(":")
        self.white_mode = int(white[0])
        self.white_init = list(map(alphabet2num, white[1].split()))
        black = info.readline().split(":")
        self.black_mode = int(black[0])
        self.black_init = list(map(alphabet2num, black[1].split()))
        self.player = [self.white_mode, self.black_mode]
        self.board = Board(self.n, self.white_init, self.black_init)

    cpdef game(self):
        ongoing : bool = True
        while ongoing:
            for n, x in enumerate(self.player):
                if Board.iswon(self.board.board_view, self.board.wturn, self.board.qnumber):
                    print("No Moves possible", "black" if n else "white", "lost")
                    ongoing = False
                    break
                if not x:
                    player(board=self.board) 
                else:
                    self.board.board = AI.get_ai_move(self.board.board, x, self.board.wturn, self.board.qnumber)
                    self.board.wturn = not self.board.wturn
                print(self.board)

    def __str__(self):
        return str(self.n) + " " + MODES[self.white_mode] + str(self.white_init) + " " + MODES[self.black_mode] + str(
            self.black_init) + "\n" + str(self.board)


cdef class Board:
    cdef public np.npy_bool wturn 
    cdef public unsigned short size, qnumber
    cdef public np.ndarray wboard, bboard, board
    cdef public long[:,:] board_view

    def __init__(self, size, white_init, black_init):
        self.wturn = True
        self.size = size
        self.board = np.zeros((size, size), dtype=long)  # fill size x size  with empty fields
        self.qnumber = len(white_init[0])
        self.board[tuple(zip(*white_init))] = NWHITEQ  # fill in Amazons
        self.board[tuple(zip(*black_init))] = NBLACKQ
        self.board_view = self.board
        self.wboard, self.bboard = np.array([]), np.array([])

    @cython.profile(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod # max optimized 
    cdef np.ndarray[long ,ndim=2] get_queen_pos(long[:, :] a,short color, unsigned short num):
    
        cdef np.ndarray[long,  ndim=2] pos = np.zeros(shape=(num,2),dtype=long)
        cdef long[:, :] result_view = pos
        cdef unsigned short ind = 0

        for x in range(a.shape[0]):
            for y in range(a.shape[0]):
                if a[x, y]==color:
                    result_view[ind, 0]= x
                    result_view[ind, 1]= y
                    ind+=1
                    if ind==num:
                        return pos

    
    @cython.profile(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    cdef list get_amazon_moves(long[:, :] board, np.ndarray s):
        cdef np.ndarray[long, ndim=2] boardx, ops, sused
        cdef np.ndarray[long, ndim=1] calcmoves
        cdef unsigned short i
        cdef list ret
        ret = []
        boardx = np.pad(board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
        ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
        i = 1
        while True:
            sused = (s + ops)
            calcmoves = boardx[tuple(zip(*sused))]
            ops = (ops[calcmoves == 0] / i).astype(long)
            if ops.shape[0]==0:
                return ret
            for y in range(sused[calcmoves == 0].shape[0]):
                ret.append(sused[calcmoves == 0][y])
            i += 1
            ops = ops * i
        return ret
    @cython.profile(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    cdef np.ndarray[long, ndim=3] fast_moves(long[:, :] board, unsigned short token, unsigned short qn):
        cdef np.ndarray[long, ndim=2] amazons, boardx, ops, sused
        cdef np.ndarray[long, ndim=1] calcmoves
        cdef list ret, tmp
        cdef unsigned int i
        ret = []

        amazons = Board.get_queen_pos(board, token, qn)+1
        boardx = np.pad(board, 1, "constant", constant_values=-1)  

        for s in range(amazons.shape[0]):
            tmp = Board.get_amazon_moves(board, amazons[s])
            for qmove in tmp:
                i = 1
                ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
                boardx[qmove[0],qmove[1]] = boardx[amazons[s][0],amazons[s][1]]
                boardx[amazons[s][0],amazons[s][1]] = NEMPTY
                while True:
                    sused = (qmove + ops)
                    calcmoves = boardx[tuple(zip(*sused))]
                    ops = (ops[calcmoves == 0] / i).astype(long)
                    if len(ops)==0:
                        break
                    for y in sused[calcmoves == 0]:
                        ret.append((np.array([amazons[s], qmove, y])-1))
                    i += 1
                    ops = ops * i
                boardx[amazons[s][0],amazons[s][1]] = boardx[qmove[0],qmove[1]]
                boardx[qmove[0],qmove[1]] = NEMPTY
        return np.array(ret)
    @cython.profile(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    cdef np.npy_bool iswon(long[:, :] board ,np.npy_bool wturn, unsigned short qn):

        cdef np.ndarray[long, ndim=2] amazons
        cdef np.ndarray[long, ndim=2] a
        cdef np.ndarray[long, ndim=2] ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])

        amazons = Board.get_queen_pos(board, NWHITEQ if wturn else NBLACKQ, qn)
        for i in range(amazons.shape[0]):
            a = amazons[i]+ops
            for x in range(a.shape[0]):
                if 0 <= a[x,0] < board.shape[0] and 0 <= a[x,1] < board.shape[0]:
                    if board[a[x,0], a[x,1]] == 0:
                        return False
        return True

    cpdef move(self, s, d):
        self.board[d] = self.board[s]
        self.board[s] = NEMPTY

    cpdef shoot(self, d):
        self.board[d] = NARROW
   
    cpdef evaluate(self):
        self.wturn = not self.wturn 
    
    cpdef try_move(self, input_tup: tuple):

        (s, d) = input_tup

        if d[0] not in range(self.board.shape[0]) or d[1] not in range(self.board.shape[0]):
            print("ERR outofbounds")
            return False

        if (self.wturn and self.board[s] != NWHITEQ) or (not self.wturn and self.board[s] != NBLACKQ):
            print("Err TURN")
            return False

        (h, v) = (s[0] - d[0], s[1] - d[1])

        if (h and v and abs(h / v) != 1) or (not h and not v):
            print("ERR DIR", h, v)
            return False

        op = (0 if not h else (-int(h / abs(h))), 0 if not v else (-int(v / abs(v))))
        indx = np.arange(self.board.shape[0])
        # own approach on is_free check, excluding any loops -> could be used to generate random moves later on
        les = s[0] if not op[0] else indx[
                                     max(0, min(s[0] + op[0], d[0]))
                                     :min(self.size, max(s[0], d[0] + op[0]))][
                                     ::op[0]]

        res = s[1] if not op[1] else indx[
                                     max(0, min(s[1] + op[1], d[1]))
                                     :min(self.size, max(s[1], d[1] + op[1]))][
                                     ::op[1]]

        if np.any(self.board[(les, res)]):
            print("ERR NOT FREE")
            return False

        return True

    def __str__(self):
        return "{0}\n{1}".format(("   " + "  ".join([chr(ord("a") + y) for y in range(self.size)])), "\n".join(
            [(str(x + 1) + ("  " if x < 9 else " ")) + "  ".join(map(lambda x: ['■','.','W','B'][x+1], self.board[x])) for x in
             range(self.size - 1, -1, -1)]))


cpdef alphabet2num(pos_raw):
    return int(pos_raw[1:]) - 1, ord(pos_raw[0]) - ord('a')


cpdef player(board : Board):

    while True:
        (s, d) = map(alphabet2num,
                     input(("white" if board.wturn else "black") + " amazonmove please: e.g. a8-a4: ").split("-"))
        if board.try_move((s, d)):
            board.move(s, d)
            break
        else:
            print("invalid move or input")

    print(board)

    while True:
        a = alphabet2num(input("arrow coords please: e.g. a5: "))
        if board.try_move((d, a)):
            board.shoot(a)
            break
        else:
            print("invalid arrow pos or input")

    board.evaluate()
    print(s,d,a)
    return

cdef class Heuristics:     
    @cython.profile(False)   
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    cdef int move_count( long[:, :] board, unsigned short token, unsigned short qn):
        cdef np.ndarray[long, ndim=2] amazons, ops, sused, boardx
        boardx = np.pad(board, 1, "constant", constant_values=-1)  
        cdef long[:,:] boardx_view = boardx
        cdef np.ndarray[long, ndim=1] calcmoves
        cdef list tmp
        cdef unsigned int i, ret,x,y
        ret = 0

        amazons = Board.get_queen_pos(board, token, qn)+1
       

        for s in range(amazons.shape[0]):
            tmp = Board.get_amazon_moves(board, amazons[s])
            for qmove in tmp:
                i = 1
                x= qmove[0]
                y= qmove[1]
                ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
                boardx_view[x,y] = boardx_view[amazons[s,0], amazons[s,1]]
                boardx_view[amazons[s,0],amazons[s,1]] = NEMPTY
                while True:
                    sused = (qmove + ops)
                    calcmoves = boardx[tuple(zip(*sused))]
                    ops = (ops[calcmoves == 0] / i).astype(long)
                    if ops.shape[0]==0:
                        break
                    ret += sused[calcmoves == 0].shape[0]
                    i += 1
                    ops = ops * i
                boardx_view[amazons[s,0],amazons[s,1]] = boardx_view[x,y]
                boardx_view[x,y] = NEMPTY
        return ret
    

cdef class AI:
    @cython.profile(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    cdef np.ndarray[long,ndim=2] get_ai_move(long[:, :] oboard, int mode, np.npy_bool owturn, unsigned short qnumber):  

        cdef int best_score = INF
        cdef np.npy_bool found = False
        cdef unsigned short token = 1 if owturn else 2
        cdef np.ndarray[long, ndim=3] MOVES = Board.fast_moves(oboard, token, qnumber)
        cdef long[:, :, :] MOVES_view = MOVES

        cdef int score
        cdef np.ndarray[long, ndim=2] best_move
        cdef np.ndarray[long,ndim=2] board = np.copy(oboard)
        cdef np.npy_bool wturn = owturn
        
        stamp = time.time()

        for i in range(MOVES_view.shape[0]):

            # move
            board[MOVES_view[i,1,0], MOVES_view[i,1,1]] = token
            board[MOVES_view[i,0,0], MOVES_view[i,0,1]] = NEMPTY
            board[MOVES_view[i,2,0], MOVES_view[i,2,1]] = NARROW
            wturn = not wturn
           
            score = AI.alphabeta(board, wturn, qnumber, 2, -INF, INF, True, mode)
          
            # undo 
            board[MOVES_view[i,2,0], MOVES_view[i,2,1]] = NEMPTY
            board[MOVES_view[i,1,0], MOVES_view[i,1,1]] = NEMPTY
            board[MOVES_view[i,0,0], MOVES_view[i,0,1]] = token
            wturn = not wturn

            print(time.time() - stamp)
            stamp = time.time()
            if score < best_score:
                found = True
                best_score = score
                best_move = MOVES[i]
        if found:
            board[best_move[1,0], best_move[1,1]] = token
            board[best_move[0,0], best_move[0,1]] = NEMPTY
            board[best_move[2,0], best_move[2,1]] = NARROW
            return board
        else:
            return oboard
   
    
    @cython.profile(False)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    cdef int alphabeta(long[:, :] board,np.npy_bool wturn, unsigned short qn, unsigned short depth, int a, int b, np.npy_bool maximizing, int mode):
        cdef int heuval, ha
        cdef np.npy_bool token = 1 if wturn else 2

        if depth == 0 or Board.iswon(board, wturn, qn):
            if mode == 1:
                return Heuristics.move_count(board, token, qn)
            #  else:
            #     return Heuristics.terraeval(board, token, qn)

      
        cdef int best_score
        cdef np.ndarray[long, ndim=3] MOVES = Board.fast_moves(board, token, qn)
        cdef long[:, :, :] MOVES_view = MOVES

        cdef np.ndarray[long, ndim=1] indicies = np.arange(MOVES.shape[0],dtype=int)
        np.random.shuffle(indicies) # randomizer ->>>>>>>>>>>>>>> good speedup somehow
        if maximizing:
            best_score = -INF
            for i in range(indicies.shape[0]):

                # do move
                board[MOVES_view[indicies[i],1,0], MOVES_view[indicies[i],1,1]] = token # unpythonic way .. thanks to cython
                board[MOVES_view[indicies[i],0,0], MOVES_view[indicies[i],0,1]] = NEMPTY
                board[MOVES_view[indicies[i],2,0], MOVES_view[indicies[i],2,1]] = NARROW
                wturn = not wturn

                best_score = max(best_score, AI.alphabeta(board, wturn, qn, depth - 1, a, b, False, mode))
                
                # undo 
                board[MOVES_view[indicies[i],2,0], MOVES_view[indicies[i],2,1]] = NEMPTY
                board[MOVES_view[indicies[i],1,0], MOVES_view[indicies[i],1,1]] = NEMPTY
                board[MOVES_view[indicies[i],0,0], MOVES_view[indicies[i],0,1]] = token
                wturn = not wturn

                a = max(a, best_score)
                if b <= a:
                    break

            return best_score
        else:
            best_score = INF

            for i in range(indicies.shape[0]):

                # move
                board[MOVES_view[indicies[i],1,0], MOVES_view[indicies[i],1,1]] = token
                board[MOVES_view[indicies[i],0,0], MOVES_view[indicies[i],0,1]] = NEMPTY
                board[MOVES_view[indicies[i],2,0], MOVES_view[indicies[i],2,1]] = NARROW
                wturn = not wturn

                best_score = min(best_score, AI.alphabeta(board,wturn, qn, depth - 1, a, b, True, mode))
                
                # undo 
                board[MOVES_view[indicies[i],2,0], MOVES_view[indicies[i],2,1]] = NEMPTY
                board[MOVES_view[indicies[i],1,0], MOVES_view[indicies[i],1,1]] = NEMPTY
                board[MOVES_view[indicies[i],0,0], MOVES_view[indicies[i],0,1]] = token
                wturn = not wturn

                b = min(b, best_score)
                if b <= a:
                    break
            return best_score


cpdef main():
    game = Amazons("../configs/config6x6.txt")
    # example situation
    print(game.board)
    stamp = time.time()
    game.game()
    print(time.time()-stamp)