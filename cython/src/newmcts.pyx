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
from structures cimport _MCTS_Node, _MovesStruct, newnode, inlist, freelist, push, add, freemoves, readmoves, copyamazons
from board cimport Board

cimport numpy as np
import numpy as np
cdef _LinkedListStruct* get_nopath(short[:, ::1] boardx, _LinkedListStruct*s, short color) nogil:
    cdef:
        _LinkedListStruct*head = NULL
        Py_ssize_t lengthb
        Py_ssize_t y,xi,yi
    
    xi = s.x
    yi = s.y
    
    lengthb = boardx.shape[0]
    for y in range(xi-1,-1,-1):  
        if boardx[y,yi] == 0 or  boardx[y,yi] ==color:
            head= add(head, y, yi)
        else:
            break
            
    for y in range(xi+1,lengthb): 
        if boardx[y,yi]==0 or boardx[y,yi]== color:  
            head= add(head, y, yi)
        else:
            break
    
    for y in range(yi-1,-1,-1):  
        if boardx[xi,y]==0 or boardx[xi,y]==color :
            head= add(head, xi, y)
        else:
            break
            
    for y in range(yi+1,lengthb):  
        if boardx[xi,y]==0 or boardx[xi,y]==color:
            head= add(head, xi, y)
        else:
            break
    for y in range(1,lengthb):  
                s.x-= 1
                s.y-= 1
                if s.x>=0 and s.y>=0 and (boardx[s.x,s.y]==0 or boardx[s.x,s.y]==color):
                    head= add(head, s.x, s.y)
                else:
                    break
                
    s.x=xi
    s.y=yi
    for y in range(1,lengthb):  
                s.x-= 1
                s.y+= 1
                if s.x>=0 and s.y<lengthb and (boardx[s.x,s.y]==0 or boardx[s.x,s.y]==color):
                    head= add(head, s.x, s.y)
                else:
                    break
    s.x=xi
    s.y=yi
    for y in range(1,lengthb):  
                s.x+= 1
                s.y-= 1
                if s.y>=0 and s.x<lengthb and (boardx[s.x,s.y]==0 or boardx[s.x,s.y]==color):
                    head= add(head, s.x, s.y)
                else:
                    break
    s.x=xi
    s.y=yi             
    for y in range(1,lengthb):  
                s.x+= 1
                s.y+= 1
                if s.x<lengthb and s.y<lengthb and (boardx[s.x,s.y]==0 or boardx[s.x,s.y]==color):
                    head= add(head, s.x, s.y)
                else:
                    break
    s.x=xi
    s.y=yi
    return  head
cdef npy_bool prunning(_LinkedListStruct*amazon, short color, short[:,::1] board, short[:,::1] ops)nogil:
    cdef:
        _LinkedListStruct*_ptr = NULL
        _LinkedListStruct* _paths  = NULL
        _LinkedListStruct* _walker = NULL
        _LinkedListStruct* _set = NULL
        _LinkedListStruct* _ptrinner = NULL
        Py_ssize_t x,y,leng,opsl
        npy_bool flag = False

    
    opsl = 8
    leng = board.shape[0]
    # searches all directions for free fields
    for x in range(opsl):
        amazon.x+=ops[x,0]
        amazon.y+=ops[x,1]

        if 0 <= amazon.x < leng and 0 <= amazon.y < leng:
            if board[amazon.x, amazon.y] == 0:
                    flag = True
                    break
        amazon.x-=ops[x,0]
        amazon.y-=ops[x,1]
    # if noone found
    if not flag:
        free(amazon)
        return False

    while amazon is not NULL:
        # get path into all directions from amazon
        _paths = get_nopath(board, amazon, color)
        while _paths is not NULL:
            # enemy is in path -> also in territory -> not isolated at all -> return True
            if board[_paths.x, _paths.y] != 0:
            
                freelist(_set)
                freelist(amazon)
                freelist(_paths)
                
                return True
            # no duplicate fields e.g. no cyclic analysis of paths
            if not inlist(_set, _paths):
                x = _paths.x
                y = _paths.y 
                amazon = add(amazon, x, y)
                _set = add(_set, x, y)

            _walker = _paths
            _paths = _paths.next
            free(_walker)

        _ptr = amazon
        amazon = amazon.next
        free(_ptr)
    
    freelist(_set)

    return False

cdef _LinkedListStruct* filteramazons(_LinkedListStruct*amazon, short color, short[:,::1] board, short[:,::1] ops)nogil:
    cdef:
        _LinkedListStruct*future=NULL
        _LinkedListStruct*temp=NULL
        _LinkedListStruct*betterfuture = NULL  
        Py_ssize_t x,y
    future = amazon

     # if not isolated, add into return List of Amazons
    while future is not NULL:
        x = future.x
        y = future.y
        temp = NULL
        temp = add(temp, x, y) 
       
        if prunning(temp, color, board, ops):
            betterfuture = add(betterfuture, x, y)

        future = future.next
        
    if betterfuture is not NULL:
        freelist(amazon)
        return betterfuture

    else:
        return amazon

cdef _LinkedListStruct* get_queen_posn(short[:, ::1] a,short color, unsigned short num) nogil:
    cdef:
        unsigned short ind = 0
        Py_ssize_t x,y,leng
        _LinkedListStruct* _head = NULL
        _LinkedListStruct* _betterfuture = NULL
    leng = a.shape[0]

    for x in range(leng):
        for y in range(leng):
            if a[x, y]==color:
                _head = add(_head,x,y)
                ind+=1
                if ind==num:
                    return _head

cdef _MovesStruct* get_amazon_moves(short[:, ::1] boardx, _LinkedListStruct*amazons, npy_bool flag) nogil:  
    cdef:
        _MovesStruct*head = NULL
        _MovesStruct*lighthead = NULL
        _MovesStruct*container = NULL
        _MovesStruct*pointer = NULL
        Py_ssize_t lengthb
        Py_ssize_t y,xi,yi,xx,yy
    
    lengthb = boardx.shape[0]
    while amazons is not NULL:
        
        xi = amazons.x
        yi = amazons.y

        xx = amazons.x
        yy = amazons.y
        
    
        for y in range(xi-1,-1,-1): 
            if boardx[y,yi]==0:
                container= push(container, xx, yy,y, yi, xx, yy)
            else:
                break
            
        for y in range(xi+1,lengthb): 
            if boardx[y,yi]==0:
                container= push(container, xx, yy, y, yi, xx, yy)
            else:
                break
        
        for y in range(yi-1,-1,-1): 
            if boardx[xi,y]==0:
                container= push(container,xx, yy, xi, y, xx, yy)
            else:
                break
            
        for y in range(yi+1,lengthb): 
            if boardx[xi,y]==0:
                container= push(container, xx, yy, xi, y, xx, yy)
            else:
                break

        for y in range(1,lengthb): 
                    amazons.x-= 1
                    amazons.y-= 1
                    if amazons.x>=0 and amazons.y>=0 and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
                    
        amazons.x=xi
        amazons.y=yi
        for y in range(1,lengthb): 
                    amazons.x-= 1
                    amazons.y+= 1
                    if amazons.x>=0 and amazons.y<lengthb and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
        amazons.x=xi
        amazons.y=yi
        for y in range(1,lengthb):
                    amazons.x+= 1
                    amazons.y-= 1
                    if amazons.y>=0 and amazons.x<lengthb and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
        amazons.x=xi
        amazons.y=yi             
        for y in range(1,lengthb): 
                    amazons.x+= 1
                    amazons.y+= 1
                    if amazons.x<lengthb and amazons.y<lengthb and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
        
        #----------------------------------- container has A moves for ith iteration
      
        if container is not NULL:           # Falls was drin ist
            if container.length <=2:         # Und dies mehr als 2 elems sind  
                pointer = container         # iterate druch container  1-2-3-Lighthead    
                while pointer.next is not NULL:
                    pointer = pointer.next
                pointer.next = lighthead    # hinten anfügen
                lighthead = container       # maincontainer übverschreiben ( head ) 
                container = NULL            # container wieder NULL für nächste Iteration
            
            else:                           # 1 oder 2 elems drin sind dasselbe mit dem low container
                pointer = container
                while pointer.next is not NULL:
                    pointer = pointer.next
                pointer.next = head
                head = container
                container = NULL

        _tmp = amazons
        amazons = amazons.next
        free(_tmp)

    if flag:
        freemoves(head)
        return lighthead

    if lighthead is NULL:
        return head
    else:
        freemoves(head)
        return lighthead
        
cdef _MovesStruct* get_amazon_moveslib2rule(short[:, ::1] boardx, _LinkedListStruct*amazons, unsigned short qnumber) nogil:  
    cdef:
        _MovesStruct*head = NULL
        _MovesStruct*lighthead = NULL
        _MovesStruct*container = NULL
        _MovesStruct*pointer = NULL
        _MovesStruct*_ptr = NULL
        _MovesStruct*_ptr2 = NULL
        _MovesStruct*betterfuture = NULL
        _MovesStruct*restrain = NULL
        _MovesStruct*secondlayerrestrain = NULL
        _LinkedListStruct*eamazons = NULL
        unsigned short token = 2 if 1==boardx[amazons.x,amazons.y] else 1
        unsigned short tokenown = 1 if token == 2 else 2
        Py_ssize_t lengthb
        Py_ssize_t y,xi,yi,xx,yy
    
    lengthb = boardx.shape[0]
    eamazons = Board.get_queen_posn(boardx, token, qnumber)
    restrain = get_amazon_moves(boardx, eamazons, True) #  hole feindliche amazonen
    secondlayerrestrain = Board.fast_moves(boardx, tokenown, qnumber)
    pointer = restrain
    while pointer is not NULL:

        _ptr = secondlayerrestrain
        while _ptr is not NULL:
                                
            if _ptr.ax == pointer.dx and _ptr.ay == pointer.dy:
                 
                betterfuture = push(betterfuture, _ptr.sx,_ptr.sy,_ptr.dx,_ptr.dy,_ptr.sx,_ptr.sy)

            _ptr = _ptr.next

        pointer = pointer.next

    pointer = NULL
    while amazons is not NULL:
       
        xi = amazons.x
        yi = amazons.y

        xx = amazons.x
        yy = amazons.y
        
    
        for y in range(xi-1,-1,-1): 
            if boardx[y,yi]==0:
                container= push(container, xx, yy,y, yi, xx, yy)
            else:
                break
            
        for y in range(xi+1,lengthb): 
            if boardx[y,yi]==0:
                container= push(container, xx, yy, y, yi, xx, yy)
            else:
                break
        
        for y in range(yi-1,-1,-1): 
            if boardx[xi,y]==0:
                container= push(container,xx, yy, xi, y, xx, yy)
            else:
                break
            
        for y in range(yi+1,lengthb): 
            if boardx[xi,y]==0:
                container= push(container, xx, yy, xi, y, xx, yy)
            else:
                break

        for y in range(1,lengthb): 
                    amazons.x-= 1
                    amazons.y-= 1
                    if amazons.x>=0 and amazons.y>=0 and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
                    
        amazons.x=xi
        amazons.y=yi
        for y in range(1,lengthb): 
                    amazons.x-= 1
                    amazons.y+= 1
                    if amazons.x>=0 and amazons.y<lengthb and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
        amazons.x=xi
        amazons.y=yi
        for y in range(1,lengthb):
                    amazons.x+= 1
                    amazons.y-= 1
                    if amazons.y>=0 and amazons.x<lengthb and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
        amazons.x=xi
        amazons.y=yi             
        for y in range(1,lengthb): 
                    amazons.x+= 1
                    amazons.y+= 1
                    if amazons.x<lengthb and amazons.y<lengthb and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
        
        #----------------------------------- container has A moves for ith iteration
        if container is not NULL:           # Falls was drin ist

            if container.length <=2:         # Und dies mehr als 2 elems sind  
                pointer = container         # iterate druch container  1-2-3-Lighthead    
                while pointer.next is not NULL:
                    pointer = pointer.next
                pointer.next = lighthead    # hinten anfügen
                lighthead = container       # maincontainer übverschreiben ( head ) 
                container = NULL            # container wieder NULL für nächste Iteration
            
            else:                           # 1 oder 2 elems drin sind dasselbe mit dem low container
                
                #-------------------------------------
                pointer = NULL
                pointer = restrain
                while pointer is not NULL:

                    _ptr = container

                    while _ptr is not NULL:
                        if _ptr.dx == pointer.dx and _ptr.dy == pointer.dy:

                            betterfuture = push(betterfuture, xx,yy,_ptr.dx,_ptr.dy,xx,yy)

                        _ptr = _ptr.next
                        
                    pointer = pointer.next

                #-------------------------------------
                if betterfuture is NULL:
                    pointer = container
                    while pointer.next is not NULL:
                        pointer = pointer.next
                    pointer.next = head
                    head = container
                    container = NULL
                else:
                    freemoves(container)
                    container = NULL
        
        _tmp = amazons
        amazons = amazons.next
        free(_tmp)
    
    freemoves(restrain)
    freemoves(secondlayerrestrain)
    if betterfuture is not NULL:
        if lighthead is NULL:
            lighthead = betterfuture
        else:
            pointer = lighthead
            while pointer.next is not NULL:
                pointer = pointer.next
            pointer.next = betterfuture    # hinten anfügen
  
    if lighthead is NULL:
        return head
    else:
        freemoves(head)
        return lighthead


cdef _MovesStruct* get_arrow_moves(short[:, ::1] boardx, _LinkedListStruct*amazons, _LinkedListStruct*eamazons) nogil: # 100%  optimized
    cdef:
        _MovesStruct*restrain = NULL
        _MovesStruct*container = NULL
        _MovesStruct*betterfuture = NULL
        _MovesStruct*pointer = NULL
        _MovesStruct*_ptr = NULL
        Py_ssize_t lengthb
        Py_ssize_t y,xi,yi,xx,yy
    
    lengthb = boardx.shape[0]
    xx = 99
    yy = 99
    while amazons is not NULL:
        
        xi = amazons.x
        yi = amazons.y
        
    
        for y in range(xi-1,-1,-1): 
            if boardx[y,yi]==0:
                container= push(container, xx, yy,y, yi, xx, yy)
            else:
                break
            
        for y in range(xi+1,lengthb): 
            if boardx[y,yi]==0:
                container= push(container, xx, yy, y, yi, xx, yy)
            else:
                break
        
        for y in range(yi-1,-1,-1): 
            if boardx[xi,y]==0:
                container= push(container,xx, yy, xi, y, xx, yy)
            else:
                break
            
        for y in range(yi+1,lengthb): 
            if boardx[xi,y]==0:
                container= push(container, xx, yy, xi, y, xx, yy)
            else:
                break

        for y in range(1,lengthb): 
                    amazons.x-= 1
                    amazons.y-= 1
                    if amazons.x>=0 and amazons.y>=0 and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
                    
        amazons.x=xi
        amazons.y=yi
        for y in range(1,lengthb): 
                    amazons.x-= 1
                    amazons.y+= 1
                    if amazons.x>=0 and amazons.y<lengthb and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
        amazons.x=xi
        amazons.y=yi
        for y in range(1,lengthb):
                    amazons.x+= 1
                    amazons.y-= 1
                    if amazons.y>=0 and amazons.x<lengthb and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
        amazons.x=xi
        amazons.y=yi             
        for y in range(1,lengthb): 
                    amazons.x+= 1
                    amazons.y+= 1
                    if amazons.x<lengthb and amazons.y<lengthb and boardx[amazons.x,amazons.y]==0:
                        container= push(container, xx, yy,amazons.x, amazons.y, xx, yy)
                    else:
                        break
        _tmp = amazons
        amazons = amazons.next
        free(_tmp)
    restrain = get_amazon_moves(boardx, eamazons, True)

    pointer = restrain
    while pointer is not NULL:
        _ptr = container
        while _ptr is not NULL:
            if _ptr.dx == pointer.dx and _ptr.dy == pointer.dy:
                betterfuture = push(betterfuture, xx,yy,_ptr.dx,_ptr.dy,xx,yy)
            _ptr = _ptr.next
        pointer = pointer.next

    freemoves(restrain)
    if betterfuture is NULL:
        return container
    else:
        freemoves(container)
        return betterfuture

cdef _MCTS_Node * expand(_MCTS_Node * this, short[:,::1] board, short[:,::1] ops)nogil:
    cdef _MovesStruct* action = this._untried_actions
    cdef _MCTS_Node * child_node = NULL
    cdef _LinkedListStruct*amazon = NULL
    cdef _LinkedListStruct*eamazons = NULL
    this._untried_actions = this._untried_actions.next
    
    if action.sx == 99:
        
        board[action.dx, action.dy] = -1
        child_node = newnode(action, this.wturn,this.qnumber, this)##ERRR
        amazon = Board.get_queen_posn(board, child_node.token, this.qnumber)
        
        #amazon = filteramazons(amazon, child_node.backtoken, board, ops)
        
        child_node._untried_actions = get_amazon_moveslib2rule(board, amazon, this.qnumber)
        
        if this.children is NULL:
            this.children = child_node
            this.children.num = 1
        else:
            child_node.next = this.children
            this.children = child_node 
            this.children.num = this.children.next.num + 1
        
        return child_node 
    else:
        
        board[action.dx, action.dy] = this.token
        board[action.sx, action.sy] = 0 
        child_node = newnode(action, not this.wturn,this.qnumber, this)##ERRR
        amazon = add(amazon, action.dx, action.dy)
        amazon.next = NULL
        eamazons = Board.get_queen_posn(board, this.token, this.qnumber)
        child_node._untried_actions = get_arrow_moves(board, amazon, eamazons)

        if this.children is NULL:
            this.children = child_node
            this.children.num = 1
        else:
            child_node.next = this.children
            this.children = child_node 
            this.children.num = this.children.next.num + 1


        return child_node 


cdef short rollout(_MCTS_Node * this, short[:,::1] ops, short[:,::1] board, short[:,::1] copyb, int id, npy_bool wturn)nogil:
    cdef:
        _MovesStruct*possible_moves= NULL
        _MovesStruct*ptr = NULL
        _MovesStruct*action = NULL
        _LinkedListStruct*amazon = NULL
        time_t ts = time(NULL)
        npy_bool current_wturn = this.wturn
        short token = this.token
        Py_ssize_t ind,jnd
        Py_ssize_t length = board.shape[0]
        _LinkedListStruct*eamazons = NULL


    for ind in range(length):
        for jnd in range(length):
            copyb[ind,jnd] = board[ind,jnd]
    
    if this.move is not NULL and this.move.sx != 99: #arrow first 
        
        amazon = add(amazon, this.move.dx, this.move.dy)

        eamazons = Board.get_queen_posn(board, this.token, this.qnumber)
        possible_moves = get_arrow_moves(copyb, amazon, eamazons) 
    
        srand(ts)
        ind = ((rand()+id)%possible_moves.length)+1
        ptr = possible_moves
        while ptr is not NULL:
            
            if ptr.length == ind:
                action = ptr
            ptr = ptr.next
           
        
        copyb[action.dx,action.dy] = -1
        freemoves(possible_moves)
        current_wturn = not current_wturn
        token = 1 if current_wturn else 2
    
    while not Board.iswon(copyb, token, this.qnumber, ops) :
        amazon = NULL
        amazon = Board.get_queen_posn(copyb, token, this.qnumber)
        #amazon = filteramazons(amazon, 2 if token==1 else 1, copyb, ops)

        possible_moves = NULL
        possible_moves = get_amazon_moveslib2rule(copyb, amazon, this.qnumber)
        
        srand(ts)
        ind = ((rand()+id)%possible_moves.length)+1

        ptr = possible_moves
        while ptr is not NULL:
            
            if ptr.length == ind:
                action = ptr
            ptr = ptr.next
            

        copyb[action.dx,action.dy] = token
        copyb[action.sx,action.sy] = 0
        amazon = NULL
        amazon = add(amazon, action.dx, action.dy)
        amazon.next = NULL
        freemoves(possible_moves)

        eamazons = Board.get_queen_posn(board, this.token, this.qnumber)
        possible_moves = get_arrow_moves(copyb, amazon, eamazons)
    
        srand(ts)
        ind = ((rand()+id)%possible_moves.length)+1
        
        ptr = possible_moves
        while ptr is not NULL:
            
            if ptr.length == ind:
                action = ptr
            ptr = ptr.next
            
    
        copyb[action.dx,action.dy] = -1
        current_wturn = not current_wturn
        token = 1 if current_wturn else 2
        freemoves(possible_moves)
        
    return -1 if current_wturn == wturn else 1



cdef void backpropagate(_MCTS_Node * this, short result, short[:,::1] board, npy_bool wturn)nogil:
    
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
   
    if this.parent is not NULL:
        if this.move.sx == 99:
            board[this.move.dx, this.move.dy] = 0
        else:
            board[this.move.dx, this.move.dy] = 0
            board[this.move.sx, this.move.sy] = this.backtoken
        backpropagate(this.parent, result, board, wturn)
   
    return


 
cdef DTYPE_t calculateUCB(DTYPE_t winsown, DTYPE_t countown, DTYPE_t winschild, DTYPE_t countchild ) nogil:
    cdef:
        DTYPE_t ratio_kid = winschild/countchild # eval
        DTYPE_t visits_log = log(countown)
        DTYPE_t vrtl = 0.25 # C
        DTYPE_t wurzel = sqrt((visits_log/countchild) * min(vrtl,(ratio_kid-(ratio_kid*ratio_kid))+sqrt(2*visits_log/countchild)) )
        #DTYPE_t wurzel = vrtl*sqrt(visits_log/countchild)
    return (ratio_kid + wurzel)




cdef _MCTS_Node * best_child(_MCTS_Node * this, DTYPE_t c_param)nogil:
    cdef:
        _MCTS_Node * best = this.children
        DTYPE_t best_score = -1000.0
        DTYPE_t score
        DTYPE_t wins = this.wins
        DTYPE_t _number_of_visits = this._number_of_visits
        DTYPE_t cw,cn
        _MCTS_Node * c = this.children
    

    while c is not NULL:
        
        cw = c.wins
        cn = c._number_of_visits
        score = calculateUCB(wins, _number_of_visits, cw, cn)
        
        if score > best_score:
                best_score = score
                best = c

        c = c.next

    return best



cdef _MCTS_Node * tree_policy(_MCTS_Node * this, DTYPE_t c_param, short[:,::1] ops, short[:,::1] board)nogil:
    cdef:
        _MCTS_Node * current_node = this

    while True:
    
        if current_node._untried_actions is not NULL:

            return expand(current_node, board, ops)
        else:
            
            current_node = best_child(current_node, c_param)
            
            if current_node.move.sx == 99:
                board[current_node.move.dx, current_node.move.dy] = -1
            else:
                board[current_node.move.dx, current_node.move.dy] = current_node.backtoken
                board[current_node.move.sx, current_node.move.sy] = 0 
                
    
        if  current_node.move.sx == 99 and Board.iswon(board, current_node.token, current_node.qnumber, ops):
            return current_node





cdef void best_action_op(_MCTS_Node  * this, unsigned long  simulation_no, DTYPE_t c_param, short[:,::1]ops, short[:,::1] board, short[:,::1] copyb, int id, time_t ressources)nogil:        
    cdef:
        short reward
        unsigned long i
        _MCTS_Node *v = NULL
        _MovesStruct* best = NULL
        time_t timestamp
    

    if Board.iswon(board, this.backtoken, this.qnumber, ops):
        board[this._untried_actions.dx, this._untried_actions.dy] = this.token
        board[this._untried_actions.sx, this._untried_actions.sy] = -1
        return
    
    for i in range(simulation_no):
        
        timestamp = time(NULL)
        v = tree_policy(this, c_param, ops, board)
        
        reward = rollout(v, ops, board, copyb, id, this.wturn)
         
        backpropagate(v, reward, board, this.wturn)
       
        ressources -= (time(NULL) - timestamp)
        if ressources <= 0:
            break

    #debugt(this, 0)
    
    v = best_child(this, c_param)
    best =  v.move
    board[best.dx, best.dy] = this.token
    board[best.sx, best.sy] = 0 
    
    v = best_child(v, c_param)
    best =  v.move
    board[best.dx, best.dy] = -1
    
    freetree(this)
    return



cdef void freetree(_MCTS_Node *root)nogil:
    cdef _MCTS_Node *children = root.children
    cdef _MCTS_Node *child = NULL
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


cdef void debugt(_MCTS_Node *root, short depth)nogil:
    cdef _MCTS_Node *children = root.children
    cdef _MCTS_Node *child = NULL
    with gil:
        if children is NULL:
            print(depth, 0)
        else:
            print(depth, children.num)
    while children is not NULL:
        
        child = children
        children = children.next
        debugt(child, depth+1)
