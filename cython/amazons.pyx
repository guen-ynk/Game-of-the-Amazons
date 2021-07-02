#!python
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=True
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
from libc.stdlib cimport malloc, free, rand, srand
import player
import numpy as np
cimport numpy as np
from libc.math cimport sqrt, log
import multiprocessing
from cython.parallel import prange
from libc.time cimport time,time_t

DTYPE = np.float64
ctypedef np.float64_t DTYPE_t

# coordinates list struct
ctypedef struct _LinkedListStruct:
    Py_ssize_t x,y, length
    _LinkedListStruct*next   

# move coordinates list struct
ctypedef struct _MovesStruct:
    # s: source; d: destination; a: arrow; length: length of list
    Py_ssize_t sx,sy,dx,dy,ax,ay,length
    _MovesStruct*next   

# MCTS Node struct
ctypedef struct _MCTS_Node:
    # turn of player
    np.npy_bool wturn 
    # amazons count per side, player token
    unsigned short qnumber, token
    DTYPE_t wins, loses, _number_of_visits
    
    _MCTS_Node* parent
    _MCTS_Node* children 
    _MCTS_Node* next
    _MovesStruct* move
    _MovesStruct*_untried_actions   

# MCTS Node struct
ctypedef struct _MCTS_Node_optimized:
    # turn of player
    np.npy_bool wturn 
    # amazons count per side, player token
    unsigned short qnumber, token
    DTYPE_t wins, loses, _number_of_visits
    
    _MCTS_Node_optimized* parent
    _MCTS_Node_optimized* children 
    _MCTS_Node_optimized* next
    _LinkedListStruct*s
    _LinkedListStruct*d
    _LinkedListStruct*_untried_actions   

cdef _MCTS_Node* newnode(_MovesStruct*move, np.npy_bool wturn, unsigned short qnumber, _MCTS_Node*parent)nogil:
    cdef _MCTS_Node*obj = <_MCTS_Node*> malloc(sizeof(_MCTS_Node))

    while not obj:
        free(obj)
        obj = <_MCTS_Node*> malloc(sizeof(_MCTS_Node))
    
    obj.token = 1 if wturn else 2
    obj.wturn = wturn
    obj.qnumber = qnumber
    obj.wins = 0.0
    obj.loses = 0.0
    obj._number_of_visits = 0.0
    obj.parent = parent
    obj.children = NULL
    obj.next = NULL
    obj.move = move
    obj._untried_actions = NULL
       
    return obj

cdef _MCTS_Node_optimized* newnodeo(_LinkedListStruct*s, _LinkedListStruct*d,np.npy_bool wturn, unsigned short qnumber, _MCTS_Node_optimized*parent, np.npy_bool arr)nogil:
    cdef _MCTS_Node_optimized*obj = <_MCTS_Node_optimized*> malloc(sizeof(_MCTS_Node_optimized))

    while not obj:
        free(obj)
        obj = <_MCTS_Node_optimized*> malloc(sizeof(_MCTS_Node_optimized))
    
    obj.token = 1 if wturn else 2
    obj.wturn = wturn
    obj.qnumber = qnumber
    obj.wins = 0.0
    obj.loses = 0.0
    obj._number_of_visits = 0.0
    obj.parent = parent
    obj.children = NULL
    obj.next = NULL
    obj.s = s

    if arr:
        obj.d = NULL
    else:
        obj.d = d
    obj._untried_actions = NULL
       
    return obj
   

cdef _LinkedListStruct* add(_LinkedListStruct* _head, Py_ssize_t x, Py_ssize_t y) nogil: 
        cdef _LinkedListStruct*obj = <_LinkedListStruct*> malloc(sizeof(_LinkedListStruct))
        while not obj:
            free(obj)
            obj = <_LinkedListStruct*> malloc(sizeof(_LinkedListStruct))
        obj.x = x
        obj.y = y
        obj.length = 0
        obj.next = NULL 

        if _head is NULL:
            _head = obj
            _head.length = 1
            return _head
        else:
            obj.next = _head
            obj.length = _head.length+1
            return obj

cdef _MovesStruct* push(_MovesStruct* _head, Py_ssize_t sx,Py_ssize_t sy,Py_ssize_t dx,Py_ssize_t dy,Py_ssize_t ax,Py_ssize_t ay )nogil: 
        cdef _MovesStruct*obj = <_MovesStruct*> malloc(sizeof(_MovesStruct))
        while not obj:
            free(obj)
            obj = <_MovesStruct*> malloc(sizeof(_MovesStruct))
        obj.sx = sx
        obj.sy = sy
        obj.dx = dx
        obj.dy = dy
        obj.ax = ax
        obj.ay = ay
        obj.length = 0
        obj.next = NULL 

        if _head is NULL:
            _head = obj
            _head.length = 1
            return _head
        else:
            obj.next = _head
            obj.length = _head.length+1
            return obj

cdef class Amazons:
    cdef: 
        unsigned short n,white_mode, black_mode
        list white_init, black_init
        public Board board
        public list player
        unsigned long MCTS
        int id

    def __init__(self, config="config.txt", A=1,B=1,MCTS=10000, j=1):
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
        self.id = j

    def game(self):
        cdef:
            short [:,::1] ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]],dtype=np.short)
            short token
            Py_ssize_t bsize = self.board.board.shape[0]
            short [:,:,::1] hboard = np.full((4,bsize,bsize), fill_value=999, dtype=np.short)  
            short [:,::1] copyboard = np.empty((bsize, bsize), dtype=np.short)
            _MCTS_Node*root = NULL
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
                    AI.get_ai_move(self.board.board_view, x, self.board.wturn, self.board.qnumber, ops, hboard, param)
                    self.board.wturn = not self.board.wturn
                else:
                    root = newnode(NULL,self.board.wturn, self.board.qnumber, parent=NULL)
                    root._untried_actions = Board.fast_moves(self.board.board_view, root.token, root.qnumber)
                    MonteCarloTreeSearchNode.best_action(root,self.MCTS, 0.1,ops,self.board.board_view, copyboard, self.id)
                    self.board.wturn = not self.board.wturn
                param-=1 
                

'''
    @Class: 
        Board 
    @constructor args: 
        size : board size n
        white_init :  transformed coordinates of white amazons vice versa for black

    @class variables:
        wturn       :   its whites turn
        size        :   board size n
        qnumber     :   count of amazons per side
        board       :   game board -> 0=free    1= white    2=black     -1=Arrow/burned
        board_view  :   Memview representation of board for perforance, see cython documentation 

'''
cdef class Board:
    cdef public:
        np.npy_bool wturn 
        unsigned short size, qnumber
        np.ndarray board
        short[:,::1] board_view
    '''
        @info:
            utilizes the GIL for numpy
    '''
    def __init__(self, size, white_init, black_init):
        self.wturn = True
        self.size = size
        self.board = np.zeros((size, size), dtype=np.short)  # fill size x size  with empty fields
        self.qnumber = len(white_init)
        self.board[tuple(zip(*white_init))] = 1  # fill in Amazons
        self.board[tuple(zip(*black_init))] = 2       
        self.board_view = self.board

    '''
        @args:
            board memview,  player color 1 or 2, #amazons 
        @return:
            list of the amazon coordinates of the respective color
        @info:
            100% C - no GIL !
    '''
    @staticmethod 
    cdef _LinkedListStruct* get_queen_posn(short[:, ::1] a,short color, unsigned short num) nogil:
        cdef:
            unsigned short ind = 0
            Py_ssize_t x,y,leng
            _LinkedListStruct* _head = NULL
        leng = a.shape[0]

        for x in range(leng):
            for y in range(leng):
                if a[x, y]==color:
                    _head = add(_head,x,y)
                    ind+=1
                    if ind==num:
                        return _head
                        
    '''
        @args:
            board memview,  coordinates of amazon
        @return:
            list of the amazon coordinates of the reachable fields
        @info:
            100% C - no GIL !
    '''
    @staticmethod
    cdef _LinkedListStruct* get_amazon_moves(short[:, ::1] boardx, _LinkedListStruct*s) nogil: # 100%  optimized
        cdef:
            _LinkedListStruct*head = NULL
            Py_ssize_t lengthb
            Py_ssize_t y,xi,yi
       
        xi = s.x
        yi = s.y
      
        lengthb = boardx.shape[0]
        for y in range(xi-1,-1,-1): # hardcode thanks to cython north 
            if boardx[y,yi]==0:
                head= add(head, y, yi)
            else:
                break
             
        for y in range(xi+1,lengthb): # hardcode thanks to cython south
            if boardx[y,yi]==0:
                head= add(head, y, yi)
            else:
                break
        
        for y in range(yi-1,-1,-1): # hardcode thanks to cython left
            if boardx[xi,y]==0:
                head= add(head, xi, y)
            else:
                break
             
        for y in range(yi+1,lengthb): # hardcode thanks to cython  right
            if boardx[xi,y]==0:
                head= add(head, xi, y)
            else:
                break
        for y in range(1,lengthb): # hardcode thanks to cython  south left
                    s.x-= 1
                    s.y-= 1
                    if s.x>=0 and s.y>=0 and boardx[s.x,s.y]==0:
                        head= add(head, s.x, s.y)
                    else:
                        break
                    
        s.x=xi
        s.y=yi
        for y in range(1,lengthb): # hardcode thanks to cython  south right
                    s.x-= 1
                    s.y+= 1
                    if s.x>=0 and s.y<lengthb and boardx[s.x,s.y]==0:
                        head= add(head, s.x, s.y)
                    else:
                        break
        s.x=xi
        s.y=yi
        for y in range(1,lengthb): # hardcode thanks to cython  north left
                    s.x+= 1
                    s.y-= 1
                    if s.y>=0 and s.x<lengthb and boardx[s.x,s.y]==0:
                        head= add(head, s.x, s.y)
                    else:
                        break
        s.x=xi
        s.y=yi             
        for y in range(1,lengthb): # hardcode thanks to cython  north right
                    s.x+= 1
                    s.y+= 1
                    if s.x<lengthb and s.y<lengthb and boardx[s.x,s.y]==0:
                        head= add(head, s.x, s.y)
                    else:
                        break
        s.x=xi
        s.y=yi
        return  head

    '''
        @args:
            board memview,  player color 1 or 2, #amazons 
        @return:
            list of the possible moves for the player of the respective color
        @info:
            100% C - no GIL !
    '''
    @staticmethod
    cdef _MovesStruct* fast_moves(short[:, ::1] board, unsigned short token, unsigned short qn) nogil:
        cdef:
            _MovesStruct*_top = NULL
            _LinkedListStruct*_queenshead =  Board.get_queen_posn(board, token, qn)
            Py_ssize_t s, lengthb,dx,dy,sx,sy
            unsigned short y
            _LinkedListStruct*_head = NULL
            _LinkedListStruct*ptr = NULL
             
       
        lengthb = board.shape[0]
     
        while _queenshead is not NULL:
           
            _head = Board.get_amazon_moves(board, _queenshead)
            while _head is not NULL:

                sx=_head.x
                sy=_head.y

                dx = sx
                dy = sy

                # move 
                board[_head.x,_head.y] = board[_queenshead.x,_queenshead.y ]
                board[_queenshead.x,_queenshead.y ] = 0
                for y in range(1,lengthb): # hardcode thanks to cython north 
                    sx-=1
                    if sx>=0 and board[sx,sy]==0:
                        _top = push(_top,_queenshead.x,_queenshead.y,dx,dy,sx,sy)
                    else:
                        break
                    
                sx=_head.x    
                for y in range(1,lengthb): # hardcode thanks to cython south
                    sx+= 1
                    if sx < lengthb and board[sx,sy]==0:
                        _top = push(_top,_queenshead.x,_queenshead.y,dx,dy,sx,sy)
                    else:
                        break

                sx=_head.x    
                for y in range(1,lengthb): # hardcode thanks to cython left
                    sy-= 1
                    if sy >= 0 and board[sx,sy]==0:
                        _top = push(_top,_queenshead.x,_queenshead.y,dx,dy,sx,sy)
                    else:
                        break

                sy=_head.y    
                for y in range(1,lengthb): # hardcode thanks to cython  right
                    sy+= 1
                    if sy < lengthb and board[sx,sy]==0:
                        _top = push(_top,_queenshead.x,_queenshead.y,dx,dy,sx,sy)
                    else:
                        break

                sy=_head.y    
                for y in range(1,lengthb): # hardcode thanks to cython  south left
                            sx-= 1
                            sy-= 1
                            if sx >= 0 and sy >= 0 and board[sx,sy]==0:
                                _top = push(_top,_queenshead.x,_queenshead.y,dx,dy,sx,sy)
                            else:
                                break
                sx=_head.x
                sy=_head.y           
                for y in range(1,lengthb): # hardcode thanks to cython  south right
                            sx-= 1
                            sy+= 1
                            if sx >= 0 and sy < lengthb and board[sx,sy]==0:
                                _top = push(_top,_queenshead.x,_queenshead.y,dx,dy,sx,sy)
                            else:
                                break
                sx=_head.x
                sy=_head.y
                for y in range(1,lengthb): # hardcode thanks to cython  north left
                            sx+= 1
                            sy-= 1
                            if sx<lengthb and sy >= 0 and board[sx,sy]==0:
                                _top = push(_top,_queenshead.x,_queenshead.y,dx,dy,sx,sy)
                            else:
                                break
                sx=_head.x
                sy=_head.y
                for y in range(1,lengthb): # hardcode thanks to cython  north right
                            sx+= 1
                            sy+= 1
                            if sx < lengthb and sy < lengthb and board[sx,sy]==0:
                                _top = push(_top,_queenshead.x,_queenshead.y,dx,dy,sx,sy)
                            else:
                                break

                # undo queen move
                board[_queenshead.x,_queenshead.y ] = board[_head.x,_head.y]
                board[_head.x,_head.y] = 0
                ptr = _head
                _head = _head.next
                free(ptr)
            ptr = _queenshead
            _queenshead = _queenshead.next
            free(ptr)
        
        return _top

    '''
        @args:
            board memview,  player color 1 or 2, #amazons, operations memview 
        @return:
            returns True if color has lost else False
        @info:
            100% C - no GIL !
    '''
    @staticmethod
    cdef np.npy_bool iswon(short[:, ::1] board ,short token, unsigned short qn, short [:,::1] ops)nogil:

        cdef:           
            Py_ssize_t x,leng,i,opsl
            _LinkedListStruct*_queenshead =  Board.get_queen_posn(board, token, qn)
            _LinkedListStruct*_ptr

       
        opsl = 8
        i=0
        leng = board.shape[0]
        while _queenshead is not NULL:
            for x in range(opsl):
                _queenshead.x+=ops[x,0]
                _queenshead.y+=ops[x,1]

                if 0 <= _queenshead.x < leng and 0 <= _queenshead.y < leng:
                    if board[_queenshead.x, _queenshead.y] == 0:
                        while _queenshead is not NULL:
                            _ptr = _queenshead
                            _queenshead = _queenshead.next
                            free(_ptr)
                        return False
                _queenshead.x-=ops[x,0]
                _queenshead.y-=ops[x,1]
            i+=1
            _ptr = _queenshead
            _queenshead = _queenshead.next
            free(_ptr)

        return True
    '''
        @info:
            requires the gil !
    '''
    def __str__(self):
        return "{0}\n{1}".format(("   " + "  ".join([chr(ord("a") + y) for y in range(self.size)])), "\n".join(
            [(str(x + 1) + ("  " if x < 9 else " ")) + "  ".join(map(lambda x: ['■','·','♛','♕'][x+1], self.board[x])) for x in
             range(self.size - 1, -1, -1)]))
             

'''
    @class:
        Heuristics
    @info:
        provides functions for the calculation of heuristic values
        whole class 100% C - no GIL
'''
cdef class Heuristics:
    
    '''
        @args:
            board memview, source coordinates, depth also number of moves required so far, heuristic board
        @info:
            function for Territorial evaluation
        @return:
            nothing, but updates the heuristic values in hboard if a field can be reached in less moves than noted
    '''
    @staticmethod
    cdef _LinkedListStruct* getMovesInRadius(short[:,::1] boardx, _LinkedListStruct* ptr ,unsigned short depth, short[:,::1] boardh) nogil:
        cdef:
            Py_ssize_t lengthb,y, xi,yi
            _LinkedListStruct*_head = NULL
        lengthb = boardx.shape[0]
        xi = ptr.x
        yi = ptr.y
   
        for y in range(xi-1,-1,-1): # hardcode thanks to cython north 
            if boardx[y,yi]==0 :
                        if boardh[y,yi]>depth:
                            boardh[y,yi]=depth
                            _head= add(_head, y, yi)
            else:
                break
        for y in range(xi+1,lengthb): # hardcode thanks to cython south
            if boardx[y,yi]==0 :
                        if boardh[y,yi]>depth:
                            boardh[y,yi]=depth
                            _head= add(_head, y, yi)
            else:
                break
        for y in range(yi-1,-1,-1): # hardcode thanks to cython left
            if boardx[xi,y]==0 :
                        if boardh[xi,y]>depth:
                            boardh[xi,y]=depth
                            _head= add(_head, xi, y)
            else:
                break

        for y in range(yi+1,lengthb): # hardcode thanks to cython  right
            if boardx[xi,y]==0 :
                        if boardh[xi,y]>depth:
                            boardh[xi,y]=depth
                            _head= add(_head, xi, y)
            else:
                break
       
        for y in range(1,lengthb): # hardcode thanks to cython  south left
                    ptr.x-= 1
                    ptr.y-= 1
                    if ptr.x>=0 and ptr.y>=0 and boardx[ptr.x,ptr.y]==0:
                        if boardh[ptr.x,ptr.y]>depth:
                            boardh[ptr.x,ptr.y]=depth
                            _head= add(_head, ptr.x, ptr.y)
                    else:
                        break
                    
        ptr.x=xi
        ptr.y=yi
        for y in range(1,lengthb): # hardcode thanks to cython  south right
                    ptr.x-= 1
                    ptr.y+= 1
                    if ptr.x>=0 and ptr.y<lengthb and boardx[ptr.x,ptr.y]==0:
                        if boardh[ptr.x,ptr.y]>depth:
                            boardh[ptr.x,ptr.y]=depth
                            _head= add(_head, ptr.x, ptr.y)
                    else:
                        break
        ptr.x=xi
        ptr.y=yi
        for y in range(1,lengthb): # hardcode thanks to cython  north left
                    ptr.x+= 1
                    ptr.y-= 1
                    if ptr.y>=0 and ptr.x<lengthb and boardx[ptr.x,ptr.y]==0:
                        if boardh[ptr.x,ptr.y]>depth:
                            boardh[ptr.x,ptr.y]=depth
                            _head= add(_head, ptr.x, ptr.y)
                    else:
                        break
        ptr.x=xi
        ptr.y=yi             
        for y in range(1,lengthb): # hardcode thanks to cython  north right
                    ptr.x+= 1
                    ptr.y+= 1
                    if ptr.x<lengthb and ptr.y<lengthb and boardx[ptr.x,ptr.y]==0:
                        if boardh[ptr.x,ptr.y]>depth:
                            boardh[ptr.x,ptr.y]=depth
                            _head= add(_head, ptr.x, ptr.y)
                    else:
                        break
        ptr.x=xi
        ptr.y=yi
        
        return _head
    '''
        @args:
            board memview, source coordinates, depth also number of moves required so far, heuristic board
        @info:
            function for Territorial evaluation
        @return:
            nothing, but updates the heuristic values in hboard if a field can be reached in less moves than noted
    '''
    @staticmethod
    cdef _LinkedListStruct* kgetMovesInRadius(short[:,::1] boardx, _LinkedListStruct* ptr ,unsigned short depth, short[:,::1] boardh) nogil:
        cdef:
            Py_ssize_t lengthb,y, xi,yi
            _LinkedListStruct*_head = NULL
        lengthb = boardx.shape[0]
        xi = ptr.x
        yi = ptr.y
        y = xi-1
        if y>=0 and boardx[y,yi]==0 :
            if boardh[y,yi]>depth:
                boardh[y,yi]=depth
                _head=add(_head, y, yi)
        y=xi+1
        if y<lengthb and boardx[y,yi]==0 :
            if boardh[y,yi]>depth:
                boardh[y,yi]=depth
                _head= add(_head, y, yi)
        y=yi-1
        if y>=0 and  boardx[xi,y]==0 :
            if boardh[xi,y]>depth:
                boardh[xi,y]=depth
                _head= add(_head, xi, y)
        y=yi+1
        if y<lengthb and boardx[xi,y]==0 :
            if boardh[xi,y]>depth:
                boardh[xi,y]=depth
                _head= add(_head, xi, y)
         
        ptr.x-= 1
        ptr.y-= 1
        if ptr.x>=0 and ptr.y>=0 and boardx[ptr.x,ptr.y]==0:
            if boardh[ptr.x,ptr.y]>depth:
                boardh[ptr.x,ptr.y]=depth
                _head= add(_head, ptr.x, ptr.y)
        ptr.y=yi+1
        if ptr.x>=0 and ptr.y<lengthb and boardx[ptr.x,ptr.y]==0:
            if boardh[ptr.x,ptr.y]>depth:
                boardh[ptr.x,ptr.y]=depth
                _head= add(_head, ptr.x, ptr.y)
                
        ptr.x=xi+1
        ptr.y=yi-1
        if ptr.y>=0 and ptr.x<lengthb and boardx[ptr.x,ptr.y]==0:
            if boardh[ptr.x,ptr.y]>depth:
                boardh[ptr.x,ptr.y]=depth
                _head= add(_head, ptr.x, ptr.y)
                    
        ptr.y=yi+1           
        if ptr.x<lengthb and ptr.y<lengthb and boardx[ptr.x,ptr.y]==0:
            if boardh[ptr.x,ptr.y]>depth:
                boardh[ptr.x,ptr.y]=depth
                _head= add(_head, ptr.x, ptr.y)
        ptr.x=xi
        ptr.y=yi
        
        return _head
    '''
        @args:
            board memview, amazon coordinates, heuristic board
        @info:
            function for Territorial evaluation
        @return:
            nothing, but updates the heuristic values in hboard if a field can be reached in less moves than noted
            utilizing BFS 
    '''
    @staticmethod
    cdef void amazonBFS(short [:,::1] board, _LinkedListStruct*s, short[:,::1] hboard) nogil:
        cdef:
            Py_ssize_t x,length,dl
            _LinkedListStruct* _head = NULL         # BFS HEAD
            _LinkedListStruct* _ebenehead = NULL    # BFS TEMPORARY NEW
            _LinkedListStruct* _ptr = NULL             
            _LinkedListStruct* _tail = NULL
            
        length = board.shape[0]
        dl = length*length
       

        _head = add(_head, s.x,s.y) 
    
        for x in range(1, dl):
            _ptr = NULL         
            _ebenehead = NULL
          
            while _head is not NULL: 

                _ptr = Heuristics.getMovesInRadius(board, _head, x, hboard)

                if _ptr is not NULL:
                    if _ebenehead is NULL:
                        _ebenehead = _ptr 
                    else:
                        _tail = _ebenehead
                        # anfügen der nächstes BFS iteration
                        while _tail.next is not NULL:
                            _tail = _tail.next
                        _tail.next = _ptr

                _ptr = _head
                _head = _head.next 
                free(_ptr) 
            _head = _ebenehead 
            if _head is NULL:
                break
        return
    '''
        @args:
            board memview, amazon coordinates, heuristic board
        @info:
            function for Territorial evaluation
        @return:
            nothing, but updates the heuristic values in hboard if a field can be reached in less moves than noted
            utilizing BFS 
    '''
    @staticmethod
    cdef void kingBFS(short [:,::1] board, _LinkedListStruct*s, short[:,::1] hboard) nogil:
        cdef:
            Py_ssize_t x,length,dl
            _LinkedListStruct* _head = NULL         # BFS HEAD
            _LinkedListStruct* _ebenehead = NULL    # BFS TEMPORARY NEW
            _LinkedListStruct* _ptr = NULL             
            _LinkedListStruct* _tail = NULL
            
        length = board.shape[0]
        dl = length*length
       

        _head = add(_head, s.x,s.y) 
    
        for x in range(1, dl):
            _ptr = NULL         
            _ebenehead = NULL
          
            while _head is not NULL: 

                _ptr = Heuristics.kgetMovesInRadius(board, _head, x, hboard)

                if _ptr is not NULL:
                    if _ebenehead is NULL:
                        _ebenehead = _ptr 
                    else:
                        _tail = _ebenehead
                        # anfügen der nächstes BFS iteration
                        while _tail.next is not NULL:
                            _tail = _tail.next
                        _tail.next = _ptr

                _ptr = _head
                _head = _head.next 
                free(_ptr) 
            _head = _ebenehead 
            if _head is NULL:
                break
        return
   

    '''
        @args:
            board memview, color of player maximizing, #of amazons per side, heuristic board white, heuristic board black
        @info:
            function for Territorial evaluation
        @return:
            the heuristic value for the maximizing player 
    '''
    @staticmethod
    cdef DTYPE_t territorial_eval_heurisic(short[:,::1]board,short token,unsigned short qn, short[:,:,::1] hboard)nogil:
        cdef:
            Py_ssize_t i,j,d
            unsigned short pl = 1
            DTYPE_t ret = 0.0        
            _LinkedListStruct* _queenshead =  Board.get_queen_posn(board, pl, qn)
            _LinkedListStruct*_ptr = NULL
        d = 1
        for i in range(board.shape[0]):
            for j in range(board.shape[0]):
                hboard[0,i,j] = 999 # quenns white
                hboard[1,i,j] = 999 # quuens black
      
        while _queenshead is not NULL:
            Heuristics.amazonBFS(board, _queenshead, hboard[0])
            _ptr = _queenshead
            _queenshead = _queenshead.next
            free(_ptr)
        
        pl = 2
        _queenshead =  Board.get_queen_posn(board, pl, qn)

        while _queenshead is not NULL:
            Heuristics.amazonBFS(board, _queenshead, hboard[1])
            _ptr = _queenshead
            _queenshead = _queenshead.next
            free(_ptr)

        for i in range(board.shape[0]):
            for j in range(board.shape[0]):
                    if board[i,j] != 0:
                        continue
                    if token ==1:
                        if hboard[i,j,0] == hboard[i,j,1]:  
                            if hboard[i,j,0] != 999:
                                ret += 0.2
                        else: 
                            if hboard[i,j,0] < hboard[i,j,1]:
                                    ret += 1.0
                            else:
                                    ret -= 1.0
                    else:
                        if hboard[i,j,0] == hboard[i,j,1]:  
                            if hboard[i,j,1] != 999:
                                    ret += 0.2
                        else: 
                            if hboard[i,j,1] < hboard[i,j,0]:
                                    ret += 1.0
                            else:
                                    ret -= 1.0
        return ret
    '''
        @args:
            board memview, color of player maximizing, #of amazons per side, heuristic board white, heuristic board black
        @info:
            function for Territorial evaluation
        @return:
            the heuristic value for the maximizing player 
    '''
    @staticmethod
    cdef DTYPE_t territorial_eval_heurisick(short[:,::1]board,short token,unsigned short qn, short[:,:,::1] hboard, unsigned int param)nogil:
        param = max(1,param)
        cdef:
            Py_ssize_t i,j,d
            unsigned short pl = 1
            DTYPE_t ret = 0.0      
            DTYPE_t retk = 0.0  
            DTYPE_t c1 = 0.0
            DTYPE_t c2 = 0.0
            DTYPE_t p = (board.shape[0]**2) /  param
            DTYPE_t w1,w2,w3,w4
            _LinkedListStruct* _queenshead =  Board.get_queen_posn(board, pl, qn)
            _LinkedListStruct*_ptr = NULL
        w1 = .7*p
        w2 = .3*p
        w3 = .3*(1-p)
        w4 = .7*(1-p)
                
        d = 1
        for i in range(board.shape[0]):
            for j in range(board.shape[0]):
                    hboard[0,i,j] = 999 # quenns white
                    hboard[1,i,j] = 999 # quuens black
                    hboard[2,i,j] = 999 # kings white
                    hboard[3,i,j] = 999 # kings black
        
        while _queenshead is not NULL:
                Heuristics.amazonBFS(board, _queenshead, hboard[0])
                Heuristics.kingBFS(board, _queenshead, hboard[2])

                _ptr = _queenshead
                _queenshead = _queenshead.next
                free(_ptr)
    
        pl = 2
        _queenshead =  Board.get_queen_posn(board, pl, qn)

        while _queenshead is not NULL:
                Heuristics.amazonBFS(board, _queenshead, hboard[1])
                Heuristics.kingBFS(board, _queenshead, hboard[3])
                _ptr = _queenshead
                _queenshead = _queenshead.next
                free(_ptr)
        
        for i in range(board.shape[0]):
                for j in range(board.shape[0]):
                        if board[i,j] != 0:
                            continue
                        if token ==1:
                            if hboard[0,i,j] == hboard[1,i,j]:  
                                if hboard[0,i,j] != 999:
                                    ret += 0.2
                            else: 
                                if hboard[0,i,j] < hboard[1,i,j]:
                                        ret += 1.0
                                else:
                                        ret -= 1.0
                            if hboard[2,i,j] == hboard[3,i,j]:  
                                if hboard[2,i,j] != 999:
                                    retk += 0.2
                            else: 
                                if hboard[2,i,j] < hboard[3,i,j]:
                                        retk += 1.0
                                else:
                                        retk -= 1.0
                            c1 +=  (2.0**-hboard[0,i,j])-(2.0**-hboard[1,i,j])
                            c2 += min(1,max(-1, (hboard[3,i,j]-hboard[2,i,j])/6))
        
                        else:
                            if hboard[0,i,j] == hboard[1,i,j]:  
                                if hboard[1,i,j] != 999:
                                        ret += 0.2
                            else: 
                                if hboard[1,i,j] < hboard[0,i,j]:
                                        ret += 1.0
                                else:
                                        ret -= 1.0
                            if hboard[2,i,j] == hboard[3,i,j]:  
                                if hboard[3,i,j] != 999:
                                        retk += 0.2
                            else: 
                                if hboard[3,i,j] < hboard[2,i,j]:
                                        retk += 1.0
                                else:
                                        retk -= 1.0
                            c1 += (2.0**-hboard[1,i,j])-(2.0**-hboard[0,i,j])
                            c2 += min(1,max(-1, (hboard[2,i,j]-hboard[3,i,j])/6))
        ret = (w1*ret)+(w2*c1)+(w3*retk)+(w4*c2)
        return ret

        #ret = (ret+(retk*p))
    
   
    '''
        @args:
            board memview, color of player 1 or 2, # of amazons per side
        @info:
            function for mobility evaluation
        @return:
            the number of possible moves of player 1 or 2
    '''
    @staticmethod
    cdef DTYPE_t move_count( short[:, ::1] board, unsigned short token, unsigned short qn) nogil:
        cdef:
            Py_ssize_t xi,yi
            Py_ssize_t s, lengthb
            DTYPE_t ret = 0.0
            unsigned short y
            _LinkedListStruct*_head = NULL
            _LinkedListStruct*ptr = NULL
            _LinkedListStruct*_queenshead =  Board.get_queen_posn(board, token, qn)

             
        lengthb = board.shape[0]
     
        while _queenshead is not NULL:
            _head = Board.get_amazon_moves(board, _queenshead)
            while _head is not NULL:
     
                xi=_head.x
                yi=_head.y

                # move 
                board[_head.x,_head.y] = board[_queenshead.x ,_queenshead.y]
                board[_queenshead.x ,_queenshead.y] = 0
                for y in range(1,lengthb): # hardcode thanks to cython north 
                    xi-=1
                    if xi>=0 and board[xi,yi]==0:
                        ret+=1.0
                    else:
                        break
                    
                xi=_head.x    
                for y in range(1,lengthb): # hardcode thanks to cython south
                    xi+= 1
                    if xi < lengthb and board[xi,yi]==0:
                        ret+=1.0
                    else:
                        break

                xi=_head.x    
                for y in range(1,lengthb): # hardcode thanks to cython left
                    yi-= 1
                    if yi >= 0 and board[xi,yi]==0:
                        ret+=1.0
                    else:
                        break

                yi=_head.y    
                for y in range(1,lengthb): # hardcode thanks to cython  right
                    yi+= 1
                    if yi < lengthb and board[xi,yi]==0:
                        ret+=1.0
                    else:
                        break

                yi=_head.y    
                for y in range(1,lengthb): # hardcode thanks to cython  south left
                            xi-= 1
                            yi-= 1
                            if xi >= 0 and yi >= 0 and board[xi,yi]==0:
                                ret+=1.0
                            else:
                                break
                xi=_head.x
                yi=_head.y           
                for y in range(1,lengthb): # hardcode thanks to cython  south right
                            xi-= 1
                            yi+= 1
                            if xi >= 0 and yi < lengthb and board[xi,yi]==0:
                                ret+=1.0
                            else:
                                break
                xi=_head.x
                yi=_head.y
                for y in range(1,lengthb): # hardcode thanks to cython  north left
                            xi+= 1
                            yi-= 1
                            if xi<lengthb and yi >= 0 and board[xi,yi]==0:
                                ret+=1.0
                            else:
                                break
                xi=_head.x
                yi=_head.y
                for y in range(1,lengthb): # hardcode thanks to cython  north right
                            xi+= 1
                            yi+= 1
                            if xi < lengthb and yi < lengthb and board[xi,yi]==0:
                                ret+=1.0
                            else:
                                break

                # undo queen move
                board[_queenshead.x ,_queenshead.y] = board[_head.x,_head.y]
                board[_head.x,_head.y] = 0
                ptr = _head
                _head = _head.next
                free(ptr)
            ptr = _queenshead
            _queenshead = _queenshead.next
            free(ptr)
        return ret

'''
    @class:
        AI ( Alpha Beta prunning)
    @info:
        provides functions for choosing the next move, utilizing alphabeta and heuristics
        whole class 100% C - no GIL
'''
cdef class AI:

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
    @staticmethod
    cdef void get_ai_move(short[:, ::1] board, int mode, np.npy_bool wturn, unsigned short qnumber, short[:,::1] ops,short[:,:,::1] hb, unsigned int param) nogil:  
        cdef:
            DTYPE_t best_score = -1000000.0
            DTYPE_t rbest_score = 1000000.0
            DTYPE_t score = 0.0

            unsigned short token = 1 if wturn else 2

            _MovesStruct*_ptr = NULL
            _MovesStruct*_head = Board.fast_moves(board, token, qnumber)
            _MovesStruct*best_move = NULL
            unsigned short depth = 2 if _head.length > 50 else 8

        while _head is not NULL:
            
            # move
            board[_head.dx,_head.dy] = token
            board[_head.sx,_head.sy] = 0
            board[_head.ax,_head.ay] = -1

            score = AI.alphabeta(board,not wturn, qnumber, 2, best_score, rbest_score, False, mode, ops, hb, wturn, param-1)
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
    @staticmethod
    cdef DTYPE_t alphabeta(short[:, ::1] board,np.npy_bool wturn, unsigned short qn, unsigned short depth, DTYPE_t a, DTYPE_t b, np.npy_bool maximizing, int mode, short[:,::1] ops,short[:,:,::1] hb, np.npy_bool callerwturn, unsigned int param)nogil:
        cdef:
            DTYPE_t heuval1,heuval2
            short token = 1 if wturn else 2

        if depth == 0 or Board.iswon(board,token, qn, ops):
            if mode == 1:
                heuval1 = Heuristics.move_count(board, 1, qn)
                heuval2 = Heuristics.move_count(board, 2, qn)
                
                if callerwturn:
                    return heuval1-heuval2
                else:
                    return heuval2-heuval1

            elif mode == 2:
                if callerwturn:
                    return Heuristics.territorial_eval_heurisic(board, 1, qn,hb)
                else:
                    return Heuristics.territorial_eval_heurisic(board, 2, qn,hb)
            else:
                if callerwturn:
                    return Heuristics.territorial_eval_heurisick(board, 1, qn,hb, param)
                else:
                    return Heuristics.territorial_eval_heurisick(board, 2, qn,hb, param)
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

                score = AI.alphabeta(board, not wturn, qn, depth - 1, a, b, False, mode,ops,hb, callerwturn, param-1)
                
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

                score = AI.alphabeta(board,not wturn, qn, depth - 1, a, b, True, mode,ops,hb, callerwturn, param-1)
                
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

'''
    @class:
        AI ( Monte Carlo Tree Search)
    @info:
        provides functions for choosing the next move, utilizing MCTS
        whole class 100% C - no GIL
'''
cdef class MonteCarloTreeSearchNode():
    
    '''
        @args:
            calling MCTS node, board memview
        @info:
            function for MCTS
        @return:
            the next unexpanded child of the calling MCTS node
    '''
    @staticmethod
    cdef _MCTS_Node* expand(_MCTS_Node* this, short[:,::1] board)nogil:
        cdef _MovesStruct* action = this._untried_actions

        this._untried_actions = this._untried_actions.next
        board[action.dx, action.dy] = this.token
        board[action.sx, action.sy] = 0 
        board[action.ax, action.ay] = -1


        cdef _MCTS_Node* child_node = newnode(action, this.wturn,this.qnumber, parent=this)##ERRR
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
    @staticmethod
    cdef short rollout(_MCTS_Node* this, short[:,::1] ops, short[:,::1] board, short[:,::1] copyb, int id)nogil:
        cdef:
            _MovesStruct*possible_moves= NULL
            _MovesStruct*ptr = NULL
            _MovesStruct*action = NULL
            int ts = time(NULL)
            np.npy_bool current_wturn = this.wturn
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
        return -1 if current_wturn == this.wturn else 1

    '''
        @args:
            calling MCTS node, result of the rollout ,board memview
        @info:
            function for MCTS
        @return:
            nothing, but traverses back to the root, updating the nodes and reversing the moves (board) for space effiency
    '''
    @staticmethod
    cdef void backpropagate(_MCTS_Node* this, short result, short[:,::1] board)nogil:
        
        this._number_of_visits +=1.0
        if result == 1:
            this.wins+=1.0
        else:
            this.loses+=1.0
        if this.move is not NULL:
            board[this.move.ax,this.move.ay] = 0
            board[this.move.dx,this.move.dy] = 0
            board[this.move.sx,this.move.sy] = this.token
        if this.parent is not NULL:
            MonteCarloTreeSearchNode.backpropagate(this.parent, result, board)
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
    @staticmethod 
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
    @staticmethod
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
            #score = ((c.wins - c.loses) / c._number_of_visits) + c_param * np.sqrt((2 * logownvisits  / c._number_of_visits))
            cw = c.wins
            cn = c._number_of_visits
            # paper score
            score = MonteCarloTreeSearchNode.calculateUCB(wins, _number_of_visits, cw, cn)
            
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
    @staticmethod
    cdef _MCTS_Node* tree_policy(_MCTS_Node* this, DTYPE_t c_param, short[:,::1] ops, short[:,::1] board)nogil:
        cdef:
            _MCTS_Node* current_node = this

        while not Board.iswon(board, current_node.token, current_node.qnumber, ops):#hier

            if current_node._untried_actions is not NULL:
                return MonteCarloTreeSearchNode.expand(current_node, board)
            else:
                current_node = MonteCarloTreeSearchNode.best_child(current_node, c_param)
                board[current_node.move.dx, current_node.move.dy] = current_node.token
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
    @staticmethod
    cdef void best_action(_MCTS_Node * this, unsigned long  simulation_no, DTYPE_t c_param, short[:,::1]ops, short[:,::1] board, short[:,::1] copyb, int id)nogil:        
        cdef:
            short reward
            unsigned long i
            _MCTS_Node*v = NULL
            _MovesStruct* best = NULL
        for i in range(simulation_no):
            v = MonteCarloTreeSearchNode.tree_policy(this,c_param, ops, board)
            reward = MonteCarloTreeSearchNode.rollout(v, ops, board, copyb, id)
            MonteCarloTreeSearchNode.backpropagate(v, reward, board)   
        v = MonteCarloTreeSearchNode.best_child(this, c_param)
        best =  v.move
        board[best.dx, best.dy] = this.token
        board[best.sx, best.sy] = 0 
        board[best.ax, best.ay] = -1
        MonteCarloTreeSearchNode.freetree(this)
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
    @staticmethod
    cdef void freetree(_MCTS_Node*root)nogil:
        cdef _MCTS_Node*children = root.children
        cdef _MCTS_Node*child = NULL
        cdef _MovesStruct*move = NULL
        cdef _MovesStruct*tmp = NULL
        while children is not NULL:
            child = children
            children = children.next
            MonteCarloTreeSearchNode.freetree(child)
            
        move = root._untried_actions
        while move is not NULL:
            tmp = move
            move = move.next
            free(tmp)
        if root.move is not NULL:
            free(root.move)
        free(root)

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
def main(i,q, times,inputfile,A,B,MCTS):
    cdef int j = i
    cdef Amazons field
    cdef int f = 0
    cdef int k 
    for k in range(times):    
        field = Amazons("../configs/config"+inputfile+".txt",A,B,MCTS,j+k)
        f += int(field.game())
    q.put(f)

def simulate(times=3,inputfile="3x3",A=1,B=2,MCTS=10000):
    import time
    cdef Amazons field
    stamp = time.time()
    for _ in range(times):    
        field = Amazons("../configs/config"+inputfile+".txt",A,B,MCTS,0)
        print( field.game(), time.time()-stamp)
