#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False

from libc.time cimport time_t, time
from libc.math cimport sqrt, log
from libc.stdlib cimport free, rand, srand
from numpy cimport npy_bool
from structures cimport _MCTS_Node, _MovesStruct, newnode
from board cimport Board


'''
    @class:
        AI ( Monte Carlo Tree Search)
    @info:
        provides functions for choosing the next move, utilizing MCTS
        whole class 100% C - no GIL
'''
 
    
'''
    @args:
        calling MCTS node, board memview
    @info:
        function for MCTS
    @return:
        the next unexpanded child of the calling MCTS node
'''
cdef _MCTS_Node* expand(_MCTS_Node* this, short[:,::1] board)nogil:
    cdef _MovesStruct* action = this._untried_actions

    this._untried_actions = this._untried_actions.next
    board[action.dx, action.dy] = this.token
    board[action.sx, action.sy] =  0 
    board[action.ax, action.ay] = -1


    cdef _MCTS_Node* child_node = newnode(action, not this.wturn,this.qnumber, this)##ERRR
    child_node._untried_actions = Board.fast_moves(board, child_node.token, child_node.qnumber)

    if this.children is NULL:
        this.children = child_node
    else:
        child_node.next = this.children
        this.children = child_node 

    return child_node 

'''
    @args:
        calling MCTS node, operations memview, board memview, copyboard memview, iteration+threadid for better seeding
    @info:
        function for MCTS
    @return:
        1 if the calling node wins the Rollout else -1
'''
cdef short rollout(_MCTS_Node* this, short[:,::1] ops, short[:,::1] board, short[:,::1] copyb, int id, npy_bool wturn)nogil:
    cdef:
        _MovesStruct*possible_moves= NULL
        _MovesStruct*ptr = NULL
        _MovesStruct*action = NULL
        time_t ts = time(NULL)
        npy_bool current_wturn = this.wturn
        short token = this.token
        Py_ssize_t ind,jnd
        Py_ssize_t length = board.shape[0]

    for ind in range(length):
        for jnd in range(length):
            copyb[ind,jnd] = board[ind,jnd]
    
    while not Board.iswon(copyb,token, this.qnumber, ops):
        possible_moves = Board.fast_moves(copyb, token, this.qnumber)#own function
        srand(ts)
        ind = ((rand()+id)%possible_moves.length)+1
        while possible_moves is not NULL:
            
            if possible_moves.length == ind:
                action = possible_moves
                possible_moves = possible_moves.next
            else:
                ptr = possible_moves
                possible_moves = possible_moves.next
                free(ptr)

        copyb[action.dx,action.dy] = token
        copyb[action.sx,action.sy] = 0 
        copyb[action.ax,action.ay] = -1

        current_wturn = not current_wturn
        token = 1 if current_wturn else 2
        free(action)
    return -1 if current_wturn == wturn else 1

'''
    @args:
        calling MCTS node, result of the rollout ,board memview
    @info:
        function for MCTS
    @return:
        nothing, but traverses back to the root, updating the nodes and reversing the moves (board) for space effiency
'''
cdef void backpropagate(_MCTS_Node* this, short result, short[:,::1] board, npy_bool wturn)nogil:
    
    this._number_of_visits +=1.0
    if this.wturn == wturn:
        if result == 1:
            this.loses+=1.0
        else:
            this.wins+=1.0
    else:
        if result == 1:
            this.wins+=1.0
        else:
            this.loses+=1.0
            
    if this.move is not NULL:
        board[this.move.ax,this.move.ay] = 0
        board[this.move.dx,this.move.dy] = 0
        board[this.move.sx,this.move.sy] = this.backtoken
    if this.parent is not NULL:
        backpropagate(this.parent, result, board, wturn)##CHECK
    return

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
cdef DTYPE_t calculateUCB(DTYPE_t winsown, DTYPE_t countown, DTYPE_t winschild, DTYPE_t countchild ) nogil:
    cdef:
        DTYPE_t ratio_kid = winschild/countchild
        DTYPE_t visits_log = log(countown)
        DTYPE_t vrtl = 0.25
        DTYPE_t wurzel = sqrt((visits_log/countchild) * min(vrtl,ratio_kid-(ratio_kid*ratio_kid), sqrt(2*visits_log/countchild)) )
    return (ratio_kid + wurzel)

'''
    @args:
        calling MCTS node as parent, param ( not important for this UCB1 score but can be used for future versions including an exploration bonus)
    @info:
        function for MCTS
    @return:
        the best child node
'''
cdef _MCTS_Node* best_child(_MCTS_Node* this, DTYPE_t c_param)nogil:
    cdef:
        _MCTS_Node* best = NULL
        DTYPE_t best_score = -1000.0
        DTYPE_t score
        DTYPE_t wins = this.wins
        DTYPE_t _number_of_visits = this._number_of_visits
        DTYPE_t cw,cn
        _MCTS_Node* c = this.children
    while c is not NULL:
        # original score
        #score = ((c.wins - c.loses) / c._number_of_visits) + c_param * sqrt((2 * logownvisits  / c._number_of_visits))
        cw = c.wins
        cn = c._number_of_visits
        # paper score
        score = calculateUCB(wins, _number_of_visits, cw, cn)
        
        if score > best_score:
            best_score = score
            best = c

        c = c.next

    return best

'''
    @args:
        calling MCTS node, param ( not important also see best_child()), operations memview, board memview
    @info:
        function for MCTS
    @return:
        the next node for the rollout 
'''
cdef _MCTS_Node* tree_policy(_MCTS_Node* this, DTYPE_t c_param, short[:,::1] ops, short[:,::1] board)nogil:
    cdef:
        _MCTS_Node* current_node = this

    while not Board.iswon(board, current_node.token, current_node.qnumber, ops):#hier

        if current_node._untried_actions is not NULL:
        
            return expand(current_node, board)
        else:
    
            current_node = best_child(current_node, c_param)
        
            board[current_node.move.dx, current_node.move.dy] = current_node.backtoken
            board[current_node.move.sx, current_node.move.sy] = 0 
            board[current_node.move.ax, current_node.move.ay] = -1

    return current_node

'''
    @args:
        calling MCTS node, how many games per turn, param ( not important also see best_child()), operations memview, board memview, boardcopy memview
    @info:
        function for MCTS - ENTRANCE
    @return:
        nothing but performs the best move according to the MCTS on the original board
'''
cdef void best_action(_MCTS_Node * this, unsigned long  simulation_no, DTYPE_t c_param, short[:,::1]ops, short[:,::1] board, short[:,::1] copyb, int id, time_t ressources)nogil:        
    cdef:
        short reward
        unsigned long i
        _MCTS_Node*v = NULL
        time_t timestamp
        
        _MovesStruct* best = NULL
    for i in range(simulation_no):
        timestamp = time(NULL)

        v = tree_policy(this,c_param, ops, board)
        
        reward = rollout(v, ops, board, copyb, id,this.wturn)
        
        backpropagate(v, reward, board, this.wturn) 

        backpropagate(v, reward, board, this.wturn)
        ressources -= (time(NULL) - timestamp)
        if ressources <= 0:
            break  

    v = best_child(this, c_param)
    
    best =  v.move
    board[best.dx, best.dy] = this.token
    board[best.sx, best.sy] = 0 
    board[best.ax, best.ay] = -1
    freetree(this)
    return

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
cdef void freetree(_MCTS_Node*root)nogil:
    cdef _MCTS_Node*children = root.children
    cdef _MCTS_Node*child = NULL
    cdef _MovesStruct*move = NULL
    cdef _MovesStruct*tmp = NULL
    while children is not NULL:
        child = children
        children = children.next
        freetree(child)
        
    move = root._untried_actions
    while move is not NULL:
        tmp = move
        move = move.next
        free(tmp)
    if root.move is not NULL:
        free(root.move)
    free(root)