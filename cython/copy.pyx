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

CHARS: dict = {
    -1: '■',
    0: '.',
    1: 'W',
    2: 'B'
}



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
                if Board.iswon(self.board):
                    print("No Moves possible", "black" if n else "white", "lost")
                    ongoing = False
                    break
                player(board=self.board) if not x else AI.get_ai_move(cp.deepcopy(self.board), x, self.board)
              

    def __str__(self):
        return str(self.n) + " " + MODES[self.white_mode] + str(self.white_init) + " " + MODES[self.black_mode] + str(
            self.black_init) + "\n" + str(self.board)


cdef class Board:
    cdef public np.npy_bool wturn 
    cdef public unsigned short size, qnumber
    cdef public np.ndarray indx, ops, wboard, bboard, board
    cdef public object tables

    def __init__(self, size, white_init, black_init):
        self.wturn = True
        self.size = size
        self.indx = np.arange(size)
        self.board = np.zeros((size, size), dtype=int)  # fill size x size  with empty fields
        self.qnumber = len(white_init[0])
        self.board[tuple(zip(*white_init))] = NWHITEQ  # fill in Amazons
        self.board[tuple(zip(*black_init))] = NBLACKQ
        self.ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
        self.wboard, self.bboard = np.array([]), np.array([])
        self.tables = [{}, {}]
    
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod # max optimized 
    cdef np.ndarray[np.int64_t ,ndim=2] get_queen_pos(np.ndarray[np.int64_t, ndim=2] a,short color, unsigned short num):
        cdef np.ndarray[np.int64_t,  ndim=2] pos = np.zeros(shape=(num,2),dtype=int)
        cdef unsigned short ind = 0

        for x in range(a.shape[0]):
            for y in range(a.shape[0]):
                if a[x, y]==color:
                    pos[ind][0],pos[ind][1] = x,y
                    ind+=1
                    if ind==num:
                        return pos

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    cdef list get_amazon_moves(np.ndarray[np.int64_t, ndim=2] board, np.ndarray s):
        cdef np.ndarray[np.int64_t, ndim=2] boardx, ops, sused
        cdef np.ndarray[np.int64_t, ndim=1] calcmoves
        cdef unsigned short i
        cdef list ret
        ret = []
        boardx = np.pad(board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
        ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
        i = 1
        while True:
            sused = (s + ops)
            calcmoves = boardx[tuple(zip(*sused))]
            ops = (ops[calcmoves == 0] / i).astype(int)
            if len(ops)==0:
                return ret
            for y in range(sused[calcmoves == 0].shape[0]):
                ret.append(sused[calcmoves == 0][y])
            i += 1
            ops = ops * i
        return ret

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    cdef np.ndarray[np.int64_t, ndim=3] fast_moves(np.ndarray[np.int64_t, ndim=2] board, unsigned short size, unsigned short token, unsigned short qn):
        cdef np.ndarray[np.int64_t, ndim=2] amazons, boardx, ops, sused
        cdef np.ndarray[np.int64_t, ndim=1] calcmoves
        cdef list ret, tmp
        cdef unsigned int i
        ret = []

        amazons = Board.get_queen_pos(board, token, qn)+1
        boardx = np.pad(board, 1, "constant", constant_values=-1)  

        for s in amazons:
            tmp = Board.get_amazon_moves(board, s)
            for qmove in tmp:
                i = 1
                ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
                boardx[qmove[0]][qmove[1]] = boardx[s[0]][s[1]]
                boardx[s[0]][s[1]] = NEMPTY
                while True:
                    sused = (qmove + ops)
                    calcmoves = boardx[tuple(zip(*sused))]
                    ops = (ops[calcmoves == 0] / i).astype(int)
                    if len(ops)==0:
                        break
                    for y in sused[calcmoves == 0]:
                        ret.append((np.array([s, qmove, y])-1))
                    i += 1
                    ops = ops * i
                boardx[s[0]][s[1]] = boardx[qmove[0]][qmove[1]]
                boardx[qmove[0]][qmove[1]] = NEMPTY
        return np.array(ret)
    
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    cdef np.npy_bool iswon(object self):

        cdef list moves, temp
        cdef np.ndarray[np.int64_t, ndim=2] amazons
        cdef np.ndarray[np.int64_t, ndim=2] a
        moves = []
        temp = []
        amazons = Board.get_queen_pos(self.board, NWHITEQ if self.wturn else NBLACKQ, self.qnumber)
        for i in range(len(amazons)):
            a = amazons[i]+self.ops
            for x in a:
                moves.append(x)
        for m in range(len(moves)):
            if 0 <= moves[m][0] < self.size and 0 <= moves[m][1] < self.size:
                if self.board[moves[m][0], moves[m][1]] == 0:
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

        if d[0] not in range(self.size) or d[1] not in range(self.size):
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

        # own approach on is_free check, excluding any loops -> could be used to generate random moves later on
        les = s[0] if not op[0] else self.indx[
                                     max(0, min(s[0] + op[0], d[0]))
                                     :min(self.size, max(s[0], d[0] + op[0]))][
                                     ::op[0]]

        res = s[1] if not op[1] else self.indx[
                                     max(0, min(s[1] + op[1], d[1]))
                                     :min(self.size, max(s[1], d[1] + op[1]))][
                                     ::op[1]]

        if np.any(self.board[(les, res)]):
            print("ERR NOT FREE")
            return False

        return True

   

   

    def __str__(self):
        return "{0}\n{1}".format(("   " + "  ".join([chr(ord("a") + y) for y in range(self.size)])), "\n".join(
            [(str(x + 1) + ("  " if x < 9 else " ")) + "  ".join(map(lambda x: CHARS[x], self.board[x])) for x in
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

    print(board)
    board.evaluate()
    print(s,d,a)
    return

cdef class Heuristics:        
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    cdef int fast_moves(np.ndarray[np.int64_t, ndim=2] board, unsigned short size, unsigned short token, unsigned short qn):
        cdef np.ndarray amazons, boardx, ops, sused,calcmoves
        cdef list tmp
        cdef unsigned int i, ret
        ret = 0
        amazons = Board.get_queen_pos(board, token, qn)+1
        boardx = np.pad(board, 1, "constant", constant_values=-1)  

        for s in amazons:
            tmp = Board.get_amazon_moves(board, s)
            for qmove in tmp:
                i = 1
                ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
                boardx[qmove[0], qmove[1]] = boardx[s[0], s[1]]
                boardx[s[0], s[1]] = NEMPTY
                while len(ops > 0):
                    sused = (qmove + ops)
                    calcmoves = boardx[tuple(zip(*sused))]
                    ops = (ops[calcmoves == 0] / i).astype(int)
                    ret += len(sused[calcmoves == 0])
                    i += 1
                    ops = ops * i
                boardx[s[0], s[1]] = boardx[qmove[0], qmove[1]]
                boardx[qmove[0], qmove[1]] = NEMPTY
        return ret  


cdef class AI:
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    def  get_ai_move(object board, unsigned short mode, object original):  

        cdef int best_score = INF
        cdef np.npy_bool found = False
        cdef unsigned short token = 1 if board.wturn else 2
        cdef np.ndarray[np.int64_t, ndim=3] MOVES = Board.fast_moves(board.board, board.size, token, board.qnumber)

        cdef int score
        cdef np.ndarray[np.int64_t, ndim=2] best_move

        stamp = time.time()

        for i in range(MOVES.shape[0]):

            # move
            board.board[MOVES[i][1][0], MOVES[i][1][1]] = token
            board.board[MOVES[i][0][0], MOVES[i][0][1]] = NEMPTY
            board.board[MOVES[i][2][0], MOVES[i][2][1]] = NARROW
            board.wturn = not board.wturn
           
            score = AI.alphabeta(board, 2, -INF, INF, True, mode)
          
            # undo 
            board.board[MOVES[i][2][0], MOVES[i][2][1]] = NEMPTY
            board.board[MOVES[i][1][0], MOVES[i][1][1]] = NEMPTY
            board.board[MOVES[i][0][0], MOVES[i][0][1]] = token
            board.wturn = not board.wturn

            print(time.time() - stamp)
            stamp = time.time()
            if score < best_score:
                found = True
                best_score = score
                best_move = MOVES[i]
        if found:
            original.board[best_move[1][0], best_move[1][1]] = token
            original.board[best_move[0][0], best_move[0][1]] = NEMPTY
            original.board[best_move[2][0], best_move[2][1]] = NARROW
            original.wturn = not board.wturn
            print(original)
        return best_move if  found else 0
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @staticmethod
    cdef int alphabeta(object board,unsigned short depth, int a, int b, np.npy_bool maximizing,unsigned short mode):
        cdef int heuval, ha
        cdef np.npy_bool token = 1 if board.wturn else 2

        if depth == 0 or Board.iswon(board):

            ha = hash(board.board.tobytes())
            if ha in board.tables[mode - 1].keys():
                heuval = board.tables[mode - 1][ha]
            else:
                heuval =  
                board.tables[mode - 1][hash(board.board.tobytes())] = heuval
                board.tables[mode - 1][hash(np.fliplr(board.board).tobytes())] = heuval
                board.tables[mode - 1][hash(np.flipud(board.board).tobytes())] = heuval
           

            return Heuristics.fast_moves(board.board, board.size, token, board.qnumber)

      
        cdef int best_score
        cdef np.npy_bool token = 1 if board.wturn else 2
        cdef np.ndarray[np.int64_t, ndim=3] MOVES = Board.fast_moves(board.board, board.size, token, board.qnumber)
        cdef np.ndarray[np.int64_t, ndim=1] indicies = np.arange(MOVES.shape[0],dtype=int)
        np.random.shuffle(indicies) # randomizer ->>>>>>>>>>>>>>> good speedup somehow
        if maximizing:
            best_score = -INF
            for i in indicies:

                # move
                board.board[MOVES[i][1][0], MOVES[i][1][1]] = token
                board.board[MOVES[i][0][0], MOVES[i][0][1]] = NEMPTY
                board.board[MOVES[i][2][0], MOVES[i][2][1]] = NARROW
                board.wturn = not board.wturn

                best_score = max(best_score, AI.alphabeta(board, depth - 1, a, b, False, mode))
                
                # undo 
                board.board[MOVES[i][2][0], MOVES[i][2][1]] = NEMPTY
                board.board[MOVES[i][1][0], MOVES[i][1][1]] = NEMPTY
                board.board[MOVES[i][0][0], MOVES[i][0][1]] = token
                board.wturn = not board.wturn

                a = max(a, best_score)
                if b <= a:
                    break

            return best_score
        else:
            best_score = INF

            for i in indicies:

                # move
                board.board[MOVES[i][1][0], MOVES[i][1][1]] = token
                board.board[MOVES[i][0][0], MOVES[i][0][1]] = NEMPTY
                board.board[MOVES[i][2][0], MOVES[i][2][1]] = NARROW
                board.wturn = not board.wturn

                best_score = min(best_score, AI.alphabeta(board, depth - 1, a, b, True, mode))
                
                # undo 
                board.board[MOVES[i][2][0], MOVES[i][2][1]] = NEMPTY
                board.board[MOVES[i][1][0], MOVES[i][1][1]] = NEMPTY
                board.board[MOVES[i][0][0], MOVES[i][0][1]] = token
                board.wturn = not board.wturn

                b = min(b, best_score)
                if b <= a:
                    break
            return best_score



cpdef main():
    game = Amazons("configs/config6x6.txt")
    # example situation
    print(game.board)
    stamp = time.time()
    game.game()
    print(time.time()-stamp)