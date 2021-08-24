#!python
#cython: binding=True
#cython: language_level=3
#cython: boundscheck=False
#cython: wraparound=False
#cython: cdivision=False
#cython: nonecheck=False
#cython: initializedcheck=False
 
from libc.stdlib cimport malloc, free
from numpy cimport npy_bool

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
            _head.next = NULL
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

cdef _MCTS_Node* newnode(_MovesStruct*move, npy_bool wturn, unsigned short qnumber, _MCTS_Node*parent)nogil:
    cdef _MCTS_Node*obj = <_MCTS_Node*> malloc(sizeof(_MCTS_Node))

    while not obj:
        free(obj)
        obj = <_MCTS_Node*> malloc(sizeof(_MCTS_Node))
    
    obj.token = 1 if wturn else 2
    obj.backtoken = 2 if wturn else 1
    obj.wturn = wturn
    obj.backwturn = not wturn
    obj.qnumber = qnumber
    obj.wins = 0.0
    obj.loses = 0.0
    obj._number_of_visits = 0.0
    obj.parent = parent
    obj.children = NULL
    obj.next = NULL
    obj.num = 0
    obj.move = move
    obj._untried_actions = NULL
       
    return obj

cdef  npy_bool inlist(_LinkedListStruct*_head, _LinkedListStruct* _elem)nogil:
        cdef _LinkedListStruct*_ptr = NULL
        _ptr = _head
  
        while _ptr is not NULL:
            if _ptr.x == _elem.x and _ptr.y == _elem.y:
                return True
            _ptr = _ptr.next
        return False

cdef void* freelist(_LinkedListStruct*_head)nogil:
        cdef _LinkedListStruct*_ptr = NULL
 
        while _head is not NULL:
            _ptr = _head.next
            free(_head)
            _head = _ptr

cdef void* freemoves(_MovesStruct*_head)nogil:
        cdef _MovesStruct*_ptr = NULL
 
        while _head is not NULL:
            _ptr = _head.next
            free(_head)
            _head = _ptr
            
cdef void* readlist(_LinkedListStruct*_head)nogil:
        cdef _LinkedListStruct*_ptr = NULL
        _ptr = _head
        with gil:
            print("--------------")
        while _ptr is not NULL:
            with gil:
                print(_ptr.x, _ptr.y)
            _ptr = _ptr.next

cdef void* readmoves(_MovesStruct* _head)nogil:
        cdef _MovesStruct*_ptr = NULL
        _ptr = _head
        with gil:
            print("--------------")
        while _ptr is not NULL:
            with gil:
                print(_ptr.sx, _ptr.sy,_ptr.dx, _ptr.dy,_ptr.ax, _ptr.ay,_ptr.length)
 
            _ptr = _ptr.next

cdef _LinkedListStruct* copyamazons(_LinkedListStruct* _head)nogil:
        cdef _LinkedListStruct*_ptr = NULL
        cdef _LinkedListStruct*ret = NULL
        _ptr = _head
         
        while _ptr is not NULL:
            ret = add(ret, _ptr.x, _ptr.y)
            _ptr = _ptr.next
        
        return ret