#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False
# @Guen Yanik, 2021
cimport cython
from libc.stdlib cimport free 
from structures cimport _LinkedListStruct, add
from board cimport Board

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

            _ptr = getMovesInRadius(board, _head, x, hboard)

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

            _ptr = kgetMovesInRadius(board, _head, x, hboard)

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
        amazonBFS(board, _queenshead, hboard[0])
        _ptr = _queenshead
        _queenshead = _queenshead.next
        free(_ptr)
    
    pl = 2
    _queenshead =  Board.get_queen_posn(board, pl, qn)

    while _queenshead is not NULL:
        amazonBFS(board, _queenshead, hboard[1])
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

cdef DTYPE_t territorial_eval_heurisick(short[:,::1]board,short token,unsigned short qn, short[:,:,::1] hboard, unsigned int param)nogil:
    # param = max(1,param)
    cdef:
        Py_ssize_t i,j,d
        unsigned short pl = 1
        DTYPE_t ret = 0.0      
        DTYPE_t retk = 0.0  
        DTYPE_t c1 = 0.0
        DTYPE_t c2 = 0.0
        DTYPE_t p = param/ (board.shape[0]**2) 
        DTYPE_t rp = 1-p
        DTYPE_t w1,w2,w3,w4
        _LinkedListStruct* _queenshead =  Board.get_queen_posn(board, pl, qn)
        _LinkedListStruct*_ptr = NULL
    w1 = .7*rp
    w2 = .3*rp
    w3 = .7*p
    w4 = .3*p
                
    d = 1
    for i in range(board.shape[0]):
        for j in range(board.shape[0]):
                hboard[0,i,j] = 999 # quenns white
                hboard[1,i,j] = 999 # quuens black
                hboard[2,i,j] = 999 # kings white
                hboard[3,i,j] = 999 # kings black
    
    while _queenshead is not NULL:
            amazonBFS(board, _queenshead, hboard[0])
            kingBFS(board, _queenshead, hboard[2])

            _ptr = _queenshead
            _queenshead = _queenshead.next
            free(_ptr)

    pl = 2
    _queenshead =  Board.get_queen_posn(board, pl, qn)

    while _queenshead is not NULL:
            amazonBFS(board, _queenshead, hboard[1])
            kingBFS(board, _queenshead, hboard[3])
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
    
    ret = (w1*ret)+(w2*c1*2)+(w3*retk)+(w4*c2)
    return ret

    #ret = (ret+(retk*p))



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