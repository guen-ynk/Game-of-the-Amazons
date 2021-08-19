#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False

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

cimport cython
from libc.stdlib cimport free 
from structures cimport _LinkedListStruct, _MovesStruct, add, push
from numpy cimport npy_bool
import numpy as np

cdef class Board:
     
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
    cdef npy_bool iswon(short[:, ::1] board ,short token, unsigned short qn, short [:,::1] ops)nogil:

        cdef:           
            Py_ssize_t x,leng,opsl
            _LinkedListStruct*_queenshead =  Board.get_queen_posn(board, token, qn)
            _LinkedListStruct*_ptr

       
        opsl = 8
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