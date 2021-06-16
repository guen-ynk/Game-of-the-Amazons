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
import copy
import player
cimport numpy as np
import numpy as np
import multiprocessing
#arrow -1
#empty  0
#white  1
#black  2

cdef class Amazons:
    cdef: 
        unsigned short n,white_mode, black_mode
        list white_init, black_init
        Board board
        public list player

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

    def game(self):
        while True:
            for n, x in enumerate(self.player):
                if Board.iswon(self.board.board_view, self.board.wturn, self.board.qnumber):
                   # print("No Moves possible", "black" if n else "white", "lost")
                    return not self.board.wturn
                if not x:
                    player.player(self.board) 
                elif x==1 or x==2:
                    self.board.board_view = AI.get_ai_move(self.board.board, x, self.board.wturn, self.board.qnumber)
                    self.board.wturn = not self.board.wturn
                else:
                    self.board.board_view [...] = MonteCarloTreeSearchNode.best_action(MonteCarloTreeSearchNode(self.board.board, self.board.qnumber, self.board.wturn, None, None),10000, 0.1)
                    self.board.wturn = not self.board.wturn
               # print(self.board)

    def __str__(self):
        return str(self.n) + " " + ["player", "AB", "MCTS"][self.white_mode] + str(self.white_init) + " " + ["player", "AB", "MCTS"][self.black_mode] + str(
            self.black_init) + "\n" + str(self.board)


cdef class Board:
    cdef public:
        np.npy_bool wturn 
        unsigned short size, qnumber
        np.ndarray board
        long[:,::1] board_view

    def __init__(self, size, white_init, black_init):
        self.wturn = True
        self.size = size
        self.board = np.zeros((size, size), dtype=long)  # fill size x size  with empty fields
        self.qnumber = len(white_init[0])
        self.board[tuple(zip(*white_init))] = 1  # fill in Amazons
        self.board[tuple(zip(*black_init))] = 2       
        self.board_view = self.board

   
    @staticmethod # max optimized 
    cdef long[:,::1] get_queen_pos(long[:, ::1] a,short color, unsigned short num, unsigned short adder):
    
        cdef:
            long[:, ::1] result_view = np.zeros(shape=(num,2),dtype=long)
            unsigned short ind = 0
            Py_ssize_t x,y

        for x in range(a.shape[0]):
            for y in range(a.shape[0]):
                if a[x, y]==color:
                    result_view[ind, 0]= x+adder
                    result_view[ind, 1]= y+adder
                    ind+=1
                    if ind==num:
                        return result_view

    
   
    @staticmethod
    cdef long[:,::1] get_amazon_moves(long[:, ::1] board, long[::1] s):
        cdef:
            np.ndarray[long, ndim=2] boardx, ops, sused
            np.ndarray[long, ndim=1] calcmoves
            unsigned short i = 1
            list ret = []

        boardx = np.pad(board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
        ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])

        while True:
            sused = (np.asarray(s) + ops)
            calcmoves = boardx[tuple(zip(*sused))]
            ops = (ops[calcmoves == 0] / i).astype(long)
            if ops.shape[0]==0:
                if len(ret)==0:
                    return None
                else:
                    return np.asarray(ret)
            for y in range(sused[calcmoves == 0].shape[0]):
                ret.append(sused[calcmoves == 0][y])
            i += 1
            ops = ops * i
        return np.array(ret)
   
    @staticmethod
    cdef np.ndarray[long, ndim=3] fast_moves(long[:, ::1] board, unsigned short token, unsigned short qn):
        cdef:
            np.ndarray[long, ndim=2] boardx = np.pad(board, 1, "constant", constant_values=-1)  
            np.ndarray[long, ndim=2] ops, sused
            np.ndarray[long, ndim=1] calcmoves
        
            long[:,::1] amazons = Board.get_queen_pos(board, token, qn,1)
            long[:,::1] boardx_view = boardx
            long[:,::1] qmove

            list ret = []
            Py_ssize_t i,j,s
        
        for s in range(qn):
            qmove = Board.get_amazon_moves(board, amazons[s])
            if qmove is None:
                continue
            for j in range(qmove.shape[0]):
                i = 1
                ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
                boardx_view[qmove[j,0],qmove[j,1]] = boardx_view[amazons[s,0],amazons[s,1]]
                boardx_view[amazons[s,0],amazons[s,1]] = 0
                while len(ops)>0:
                    sused = (qmove[j]+ ops)
                    calcmoves = boardx[tuple(zip(*sused))]
                    ops = (ops[calcmoves == 0] / i).astype(long)
                    for y in sused[calcmoves == 0]:
                        ret.append((np.array([amazons[s], qmove[j], y])-1))
                    i += 1
                    ops = ops * i
                boardx_view[amazons[s,0],amazons[s,1]] = boardx_view[qmove[j,0],qmove[j,1]]
                boardx_view[qmove[j,0],qmove[j,1]] = 0
        return np.asarray(ret)
      
   
    @staticmethod
    cdef np.npy_bool iswon(long[:, ::1] board ,np.npy_bool wturn, unsigned short qn):

        cdef:
            np.ndarray[long, ndim=2] a
            np.ndarray[long, ndim=2] ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
            long[:,::1] amazons = Board.get_queen_pos(board, 1 if wturn else 2, qn, 0)
            Py_ssize_t x
            unsigned short i
      
        for i in range(qn):
            a = amazons[i]+ops
            for x in range(a.shape[0]):
                if 0 <= a[x,0] < board.shape[0] and 0 <= a[x,1] < board.shape[0]:
                    if board[a[x,0], a[x,1]] == 0:
                        return False
        return True

    def __str__(self):
        return "{0}\n{1}".format(("   " + "  ".join([chr(ord("a") + y) for y in range(self.size)])), "\n".join(
            [(str(x + 1) + ("  " if x < 9 else " ")) + "  ".join(map(lambda x: ['■','.','W','B'][x+1], self.board[x])) for x in
             range(self.size - 1, -1, -1)]))




cdef class Heuristics:
    
    @staticmethod
    cdef list getMovesInRadius(long[:,::1] board,long[:,::1] check,long [::1] s,unsigned short depth, long[:,::1] boardh):
        cdef:
            np.ndarray[long, ndim=2] ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
            np.ndarray[long, ndim=2] boardx = np.pad(board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
            unsigned short i = 1
            np.ndarray[long, ndim=2] one_step_each_dir
            np.ndarray[long, ndim=1] fields
            long[::1]y
            list ret = []

        while ops.shape[0]>0:
            one_step_each_dir = (np.asarray(s) + ops)        # go 1 step in each direction
            fields = boardx[tuple(zip(*one_step_each_dir))]  # get the value of those fields
            ops = (ops[fields == 0] / i).astype(int)         # only keep the free directions, normalize ops and keep the type
            for y in one_step_each_dir[fields == 0]:
                if not check[y[0]-1,y[1]-1]:
                    boardh[y[0]-1,y[1]-1] = min(
                        boardh[y[0]-1,y[1]-1],
                        depth
                    )
                    check[y[0]-1,y[1]-1] = 1
                    ret.append(y)
            i += 1
            ops = ops * i  # jump to nth step
        return ret
    
    @staticmethod
    cdef amazonBFS(long [:,::1] board, long[::1] s, long[:,::1] hboard):
        cdef:
            Py_ssize_t x
            list movesebene, temp
            list moves = [s]
            long [:,::1] checkboard = np.zeros_like(hboard)

        for x in range(1, board.shape[0] **2):
            movesebene = []
            for m in moves:
                temp = Heuristics.getMovesInRadius(board, checkboard, m, x, hboard)
                for n in temp:
                    movesebene.append(n)
            moves = movesebene
            if len(moves) == 0:
                break

    
    @staticmethod
    cdef double territorial_eval_heurisic(long[:,::1]board,short token,unsigned short qn):
        cdef:
            Py_ssize_t a,i,j
            double ret = 0.0

            np.ndarray[long, ndim=2] wboardo = np.full((board.shape[0],board.shape[0]), fill_value=999)
            np.ndarray[long, ndim=2] bboardo = np.full((board.shape[0],board.shape[0]), fill_value=999)

            long [:,::1] wboard = wboardo
            long [:,::1] bboard = bboardo
            long [:,::1] amazons = Board.get_queen_pos(board, 1, qn, 1)

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
    cdef double move_count( long[:, ::1] board, unsigned short token, unsigned short qn):
        cdef:
            np.ndarray[long, ndim=2] boardx = np.pad(board, 1, "constant", constant_values=-1)  
            np.ndarray[long, ndim=2] ops, sused
            np.ndarray[long, ndim=1] calcmoves
            unsigned int i,j
            double ret = 0
            unsigned short s

            long[:,::1] amazons = Board.get_queen_pos(board, token, qn,1)
            long[:,::1] boardx_view = boardx
            long[:,::1] qmove

        for s in range(qn):
            qmove = Board.get_amazon_moves(board, amazons[s])
            if qmove is None:
                continue
            for j in range(qmove.shape[0]):
                i = 1
                ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
                boardx_view[qmove[j,0],qmove[j,1]] = boardx_view[amazons[s,0],amazons[s,1]]
                boardx_view[amazons[s,0],amazons[s,1]] = 0
                while len(ops)>0:
                    sused = (qmove[j] + ops)
                    calcmoves = boardx[tuple(zip(*sused))]
                    ops = (ops[calcmoves == 0] / i).astype(long)
                    ret = ret + sused[calcmoves == 0].shape[0]
                    i += 1
                    ops = ops * i
                boardx_view[amazons[s,0],amazons[s,1]] = boardx_view[qmove[j,0],qmove[j,1]]
                boardx_view[qmove[j,0],qmove[j,1]] = 0
        return ret
    

cdef class AI:
   
    @staticmethod
    cdef long[:,::1] get_ai_move(long[:, ::1] board, int mode, np.npy_bool owturn, unsigned short qnumber):  
        cdef:
            double best_score = -1000000.0
            unsigned short token = 1 if owturn else 2
            long[:, :, ::1] MOVES_view =  Board.fast_moves(board, token, qnumber)

            double score
            long[:,::1] best_move
            np.npy_bool wturn = owturn
            unsigned short depth = 2 if MOVES_view.shape[0] > 25 else 4
            Py_ssize_t i
        
        for i in range(MOVES_view.shape[0]):

            # move
            board[MOVES_view[i,1,0], MOVES_view[i,1,1]] = token
            board[MOVES_view[i,0,0], MOVES_view[i,0,1]] = 0
            board[MOVES_view[i,2,0], MOVES_view[i,2,1]] = -1

            score = AI.alphabeta(board,not wturn, qnumber, 2, best_score, 1000000.0, False, mode)
          
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
    cdef double alphabeta(long[:, ::1] board,np.npy_bool wturn, unsigned short qn, unsigned short depth, double a, double b, np.npy_bool maximizing, int mode):
        cdef:
            double heuval
            np.npy_bool token = 1 if wturn else 2

        if depth == 0 or Board.iswon(board, wturn, qn):
            if mode == 1:
                if wturn:
                    return Heuristics.move_count(board, 1, qn)-Heuristics.move_count(board, 2, qn)
                else:
                    return Heuristics.move_count(board, 2, qn)-Heuristics.move_count(board, 1, qn)

            else:
                return Heuristics.territorial_eval_heurisic(board, token, qn)

      
        cdef:
            double best_score
            long[:, :, ::1] MOVES_view = Board.fast_moves(board, token, qn)
            np.ndarray[long, ndim=1] indicies = np.arange(MOVES_view.shape[0],dtype=int)
            Py_ssize_t i

        np.random.shuffle(indicies) # randomizer ->>>>>>>>>>>>>>> good speedup somehow

        if maximizing:
            best_score = -1000000.0
            for i in range(indicies.shape[0]):

                # do move
                board[MOVES_view[indicies[i],1,0], MOVES_view[indicies[i],1,1]] = token # unpythonic way .. thanks to cython
                board[MOVES_view[indicies[i],0,0], MOVES_view[indicies[i],0,1]] = 0
                board[MOVES_view[indicies[i],2,0], MOVES_view[indicies[i],2,1]] = -1

                best_score = max(best_score, AI.alphabeta(board, not wturn, qn, depth - 1, a, b, False, mode))
                
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

                best_score = min(best_score, AI.alphabeta(board,not wturn, qn, depth - 1, a, b, True, mode))
                
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
        long[:,::1] board
        MonteCarloTreeSearchNode parent
        list children, _untried_actions
        long _number_of_visits
        unsigned long wins, loses
        long [:,::1] parent_action

    def __cinit__(self,long[:,::1] bv,unsigned short qn,np.npy_bool wt,MonteCarloTreeSearchNode parent,long [:,::1] parent_action):
        self.board = bv
        self.qnumber = qn
        self.wturn = wt
        self.parent = parent
        self.parent_action = parent_action
        self.children = []
        self._number_of_visits = 0
        self.wins = 0
        self.loses = 0
        self._untried_actions = list(Board.fast_moves(self.board, 1 if self.wturn else 2, self.qnumber))

    @staticmethod
    cdef MonteCarloTreeSearchNode expand(MonteCarloTreeSearchNode this):
        cdef long[:,::1] oboard = this.board
        cdef long[:,::1] action = this._untried_actions.pop()
        cdef long[:,::1] next_state = np.empty_like(this.board, dtype=long)
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
            long[:,::1] oboard = this.board
            long[:,::1] current_rollout_state  = np.empty_like(this.board)
            long[:,::1] action
            list possible_moves
            np.npy_bool current_wturn = this.wturn
        current_rollout_state [...] = oboard

        while not Board.iswon(current_rollout_state, current_wturn, this.qnumber):
            possible_moves = list(Board.fast_moves(current_rollout_state, 1 if current_wturn else 2, this.qnumber))
            action = possible_moves[np.random.randint(len(possible_moves))]

            current_rollout_state[action[1,0],action[1,1]] = 1 if current_wturn else 2
            current_rollout_state[action[0,0],action[0,1]] = 0 
            current_rollout_state[action[2,0],action[2,1]] = -1
            current_wturn = not current_wturn

        # current_rollout_state.wturn verlierer
        return -1 if current_wturn == this.wturn else 1

    @staticmethod
    cdef void backpropagate(MonteCarloTreeSearchNode this, short result):
        this._number_of_visits +=1
        if result == 1:
            this.wins+=1
        else:
            this.loses+=1

        if this.parent:
            MonteCarloTreeSearchNode.backpropagate(this.parent, result)
        return
   
    @staticmethod
    cdef MonteCarloTreeSearchNode best_child(MonteCarloTreeSearchNode this, double c_param):
        cdef:
            MonteCarloTreeSearchNode best = None
            double best_score = -1000000.0
            double score, ratio
            double logownvisits = np.log(this._number_of_visits)
            object c

        for c in this.children:
            # original score
            # score = ((c.wins - c.loses) / c._number_of_visits) + c_param * np.sqrt((2 * logownvisits  / c._number_of_visits))
            ratio = (c.wins/(c._number_of_visits))
            # paper score
            score = ratio + np.sqrt((logownvisits/c._number_of_visits)*min(1/this.qnumber, ratio-(ratio**2)+ np.sqrt((2 * logownvisits  / c._number_of_visits))))
            if score > best_score:
                best_score = score
                best = c

        return best
    
    @staticmethod
    cdef MonteCarloTreeSearchNode tree_policy(MonteCarloTreeSearchNode this, double c_param):
        cdef:
            MonteCarloTreeSearchNode current_node = this

        while not Board.iswon(current_node.board, current_node.wturn, current_node.qnumber):
            
            if len( current_node._untried_actions) != 0:
                return MonteCarloTreeSearchNode.expand(current_node)
            else:
                current_node = MonteCarloTreeSearchNode.best_child(current_node, c_param)

        return current_node

    @staticmethod
    cdef long[:,::1] best_action(MonteCarloTreeSearchNode this, unsigned long simulation_no, double c_param):        
        cdef:
            MonteCarloTreeSearchNode value
            short reward
            unsigned long i

        for i in range(simulation_no):
            
            v = MonteCarloTreeSearchNode.tree_policy(this,c_param)
            reward = MonteCarloTreeSearchNode.rollout(v)
            MonteCarloTreeSearchNode.backpropagate(v, reward)
        
        return MonteCarloTreeSearchNode.best_child(this, c_param).board

cpdef alphabet2num(pos_raw):
    return int(pos_raw[1:]) - 1, ord(pos_raw[0]) - ord('a')


def main(times=100,inputfile= "3x3"):

    def temp(i,q, num):
        cdef Amazons field
        cdef int f = 0
        for _ in range(num):    
            field = Amazons("../configs/config"+"3x3"+".txt")
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
        p = multiprocessing.Process(target=temp,args=(str(i),q,balance)) 
        p.start()
        processes.append(p)
    for p in processes:
        p.join()

    results = [q.get() for j in processes]
    print(results)

    f = open("res.txt", "w")
    f.write(str(time.time()-stamp)+"\n"+"white wins: "+str(sum(results))+"\n"+str(times)+"\n\n")
    f.close()

    #print("white wins: ", white)
    #print("black wins: ", black)
    #3x3
    #white wins:  73    1
    #black wins:  27    3 10000
    #white wins:  91    3 10000
    #black wins:  9     1
    #59/ 100 MCTS

    