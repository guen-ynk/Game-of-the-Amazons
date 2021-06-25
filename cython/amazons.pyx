#!python
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=True
#cython: nonecheck=False
#cython: initializedcheck=False

cimport cython
from libc.stdlib cimport malloc, free, rand, srand
import numpy as np
cimport numpy as np
from libc.math cimport sqrt, log
import multiprocessing
from cython.parallel import prange
from libc.time cimport time,time_t

DTYPE = np.float64
ctypedef np.float64_t DTYPE_t

cdef DTYPE_t calculateUCB(DTYPE_t winsown, DTYPE_t countown, DTYPE_t winschild, DTYPE_t countchild ) nogil:
        cdef:
            DTYPE_t ratio_kid = winschild/countchild
            DTYPE_t visits_log = log(countown)
            DTYPE_t wurzel = sqrt((visits_log/countchild) * min(0.25, ratio_kid-(ratio_kid*ratio_kid), sqrt(2*visits_log/countchild)) )
        return (ratio_kid + wurzel)

ctypedef struct _LinkedListStruct:
    Py_ssize_t x,y
    _LinkedListStruct*next   


ctypedef struct _MovesStruct:
    Py_ssize_t sx,sy,dx,dy,ax,ay,length
    _MovesStruct*next   


ctypedef struct _MCTS_Node:
    np.npy_bool wturn 
    unsigned short qnumber, token
    DTYPE_t wins, loses, _number_of_visits

    _MCTS_Node* parent
    _MCTS_Node* children # first
    _MCTS_Node* next
    _MovesStruct* move
    _MovesStruct*_untried_actions    

cdef _MCTS_Node* newnode(_MovesStruct*move, np.npy_bool wturn, unsigned short qnumber, _MCTS_Node*parent)nogil:
    cdef _MCTS_Node*obj = <_MCTS_Node*> malloc(sizeof(_MCTS_Node))
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
   

cdef _LinkedListStruct* add(_LinkedListStruct* _head, Py_ssize_t x, Py_ssize_t y) nogil: 
        cdef _LinkedListStruct*obj = <_LinkedListStruct*> malloc(sizeof(_LinkedListStruct))
        
        obj.x = x
        obj.y = y
        obj.next = NULL 

        if _head is NULL:
            _head = obj
            return _head
        else:
            # head-> head.next-> head.next.next -> NULL
            # obj -> head-> head.next-> head.next.next -> NULL
            obj.next = _head
            return obj

cdef _MovesStruct* push(_MovesStruct* _head, Py_ssize_t sx,Py_ssize_t sy,Py_ssize_t dx,Py_ssize_t dy,Py_ssize_t ax,Py_ssize_t ay )nogil: 
        cdef _MovesStruct*obj = <_MovesStruct*> malloc(sizeof(_MovesStruct))
       
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
        int MCTS, id

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
            short [:,::1] wboard = np.full((bsize,bsize), fill_value=999, dtype=np.short)  
            short [:,::1] bboard = np.full((bsize,bsize), fill_value=999, dtype=np.short)
            short [:,::1] copyboard = np.empty((bsize, bsize), dtype=np.short)
            _MCTS_Node*root = NULL
       # Heuristics.territorial_eval_heurisic(self.board.board_view,token, self.board.qnumber,checkboard, wboard,bboard)
        while True:
            for n, x in enumerate(self.player):
                token = 1 if self.board.wturn else 2
                if Board.iswon(self.board.board_view, token, self.board.qnumber, ops):
                    print(self.board)
                    return not self.board.wturn
                #if not x:
                 #   player.player(self.board) 
                #el
                if x==1 or x==2:
                    AI.get_ai_move(self.board.board_view, x, self.board.wturn, self.board.qnumber, ops, wboard, bboard)
                    self.board.wturn = not self.board.wturn
                else:
                    root = newnode(NULL,self.board.wturn, self.board.qnumber, parent=NULL)
                    root._untried_actions = Board.fast_moves(self.board.board_view, root.token, root.qnumber)
                    MonteCarloTreeSearchNode.best_action(root,self.MCTS, 0.1,ops,self.board.board_view, copyboard, self.id)
                    self.board.wturn = not self.board.wturn
               # print(self.board)
               # return 1
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

    def __str__(self):
        return "{0}\n{1}".format(("   " + "  ".join([chr(ord("a") + y) for y in range(self.size)])), "\n".join(
            [(str(x + 1) + ("  " if x < 9 else " ")) + "  ".join(map(lambda x: ['■','.','W','B'][x+1], self.board[x])) for x in
             range(self.size - 1, -1, -1)]))

cdef class Heuristics:
    
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
    
    @staticmethod
    cdef void amazonBFS(short [:,::1] board, _LinkedListStruct*s, short[:,::1] hboard) nogil:
        cdef:
            Py_ssize_t x,xx, length,dl
            _LinkedListStruct* _head = NULL         # BFS HEAD
            _LinkedListStruct* _ebenehead = NULL    # BFS TEMPORARY NEW
            _LinkedListStruct* _ptr = NULL             
            _LinkedListStruct* _tail = NULL
            _LinkedListStruct* _tmp = NULL
            
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
   

    
    @staticmethod
    cdef DTYPE_t territorial_eval_heurisic(short[:,::1]board,short token,unsigned short qn, short[:,::1] wboard, short[:,::1] bboard)nogil:
        cdef:
            Py_ssize_t i,j, d
            unsigned short pl = 1

            DTYPE_t ret = 0.0        
            _LinkedListStruct* _queenshead =  Board.get_queen_posn(board, pl, qn)
            _LinkedListStruct*_ptr = NULL
        d = 1
        for i in range(board.shape[0]):
            for j in range(board.shape[0]):
                bboard[i,j] = 999
                wboard[i,j] = 999
      
        while _queenshead is not NULL:
            Heuristics.amazonBFS(board, _queenshead, wboard)
            _ptr = _queenshead
            _queenshead = _queenshead.next
            free(_ptr)
        
        pl = 2
        _queenshead =  Board.get_queen_posn(board, pl, qn)

        while _queenshead is not NULL:
            Heuristics.amazonBFS(board, _queenshead, bboard)
            _ptr = _queenshead
            _queenshead = _queenshead.next
            free(_ptr)
       

        for i in range(board.shape[0]):
            for j in range(board.shape[0]):
                    if board[i,j] != 0:
                        continue
                    if wboard[i,j] == bboard[i,j]: 
                        if token==1: 
                            if wboard[i,j] != 999:
                                ret += 0.2
                        else: 
                            if bboard[i,j] != 999:
                                ret += 0.2
                    else: 
                        if token == 1:
                            if wboard[i,j] < bboard[i,j]:
                                ret += 1.0
                            else:
                                ret -= 1.0
                        else:
                            if wboard[i,j] > bboard[i,j]:
                                ret += 1.0
                            else:
                                ret -= 1.0
              
        return ret
   
    
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

cdef class AI:
   
    @staticmethod
    cdef void get_ai_move(short[:, ::1] board, int mode, np.npy_bool owturn, unsigned short qnumber, short[:,::1] ops,short[:,::1] wb,short[:,::1] bb) nogil:  
        cdef:
            DTYPE_t best_score = -1000000.0
            unsigned short token = 1 if owturn else 2

            _MovesStruct*_ptr = NULL
            _MovesStruct*_head = Board.fast_moves(board, token, qnumber)
            DTYPE_t score
            _MovesStruct*best_move = NULL
            np.npy_bool wturn = owturn
            Py_ssize_t i
            unsigned short depth = 2 if _head.length > 12 else 4
        
        while _head is not NULL:
            
            # move
            board[_head.dx,_head.dy] = token
            board[_head.sx,_head.sy] = 0
            board[_head.ax,_head.ay] = -1

            score = AI.alphabeta(board,not wturn, qnumber, 2, best_score, 1000000.0, False, mode, ops,wb,bb)
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
    
   
    @staticmethod
    cdef DTYPE_t alphabeta(short[:, ::1] board,np.npy_bool wturn, unsigned short qn, unsigned short depth, DTYPE_t a, DTYPE_t b, np.npy_bool maximizing, int mode, short[:,::1] ops,short[:,::1] wb,short[:,::1] bb)nogil:
        cdef:
            DTYPE_t heuval1,heuval2
            short token = 1 if wturn else 2
            short fremdtoken = 2 if wturn else 1

        if depth == 0 or Board.iswon(board,token, qn, ops):
            if mode == 1:
                heuval1 = Heuristics.move_count(board, token, qn)
                heuval2 = Heuristics.move_count(board, fremdtoken, qn)
                return heuval1-heuval2

            else:
                return Heuristics.territorial_eval_heurisic(board, token, qn,wb,bb)

        cdef:
            DTYPE_t best_score
            _MovesStruct*_ptr = NULL
            _MovesStruct*_head = Board.fast_moves(board, token, qn)
            Py_ssize_t i


        if maximizing:
            best_score = -1000000.0
            while _head is not NULL:

                # do move
                board[_head.dx,_head.dy] = token
                board[_head.sx,_head.sy] = 0
                board[_head.ax,_head.ay] = -1

                best_score = max(best_score, AI.alphabeta(board, not wturn, qn, depth - 1, a, b, False, mode,ops,wb,bb))
                
                # undo 
                board[_head.ax,_head.ay] = 0
                board[_head.dx,_head.dy] = 0
                board[_head.sx,_head.sy] = token

                a = max(a, best_score)
                if b <= best_score:
                    break
                _ptr = _head
                _head = _head.next
                free(_ptr)
        else:
            best_score = 1000000.0

            while _head is not NULL:

                # move
                board[_head.dx,_head.dy] = token
                board[_head.sx,_head.sy] = 0
                board[_head.ax,_head.ay] = -1

                best_score = min(best_score, AI.alphabeta(board,not wturn, qn, depth - 1, a, b, True, mode,ops,wb,bb))
                
                # undo 
                board[_head.ax,_head.ay] = 0
                board[_head.dx,_head.dy] = 0
                board[_head.sx,_head.sy] = token

                b = min(b, best_score)
                if best_score <= a:
                    break
                _ptr = _head
                _head = _head.next
                free(_ptr)
                
        while _head is not NULL:
            _ptr = _head
            _head = _head.next
            free(_ptr)
        return best_score

cdef class MonteCarloTreeSearchNode():
   
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

        #board[action.ax,action.ay] = 0
        #board[action.dx,action.dy] = 0
        #board[action.sx,action.sy] = this.token 
        return child_node 

    @staticmethod
    cdef short rollout(_MCTS_Node* this, short[:,::1] ops, short[:,::1] board, short[:,::1] copyb, int id)nogil:
        cdef:
            _MovesStruct*possible_moves= NULL
            _MovesStruct*ptr = NULL
            _MovesStruct*action = NULL
            int ts = time(NULL)
            short res 
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
            score = calculateUCB(wins, _number_of_visits, cw, cn)
            
            if score > best_score:
                best_score = score
                best = c

            c = c.next

        return best
    
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

    @staticmethod
    cdef void best_action(_MCTS_Node * this, unsigned short simulation_no, DTYPE_t c_param, short[:,::1]ops, short[:,::1] board, short[:,::1] copyb, int id)nogil:        
        cdef:
            short reward
            unsigned short i
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
    @staticmethod
    cdef void freetree(_MCTS_Node*root)nogil:
        cdef _MCTS_Node*children = root.children
        cdef _MovesStruct*move = NULL
        cdef _MovesStruct*tmp = NULL
        while children is not NULL:
            MonteCarloTreeSearchNode.freetree(children)
            children = children.next
        move = root._untried_actions
        while move is not NULL:
            tmp = move
            move = move.next
            free(tmp)
        if root.move is not NULL:
            free(root.move)
        free(root)


cpdef alphabet2num(pos_raw):
    return int(pos_raw[1:]) - 1, ord(pos_raw[0]) - ord('a')

def main(i,q, times,inputfile,A,B,MCTS):
    cdef int j = i
    cdef Amazons field
    cdef int f = 0
    for _ in range(times):    
        field = Amazons("../configs/config"+inputfile+".txt",A,B,MCTS,j)
        f += int(field.game())
    q.put(f)
