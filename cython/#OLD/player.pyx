#!python
#cython: language_level=3

import amazons
import numpy as np
cimport numpy as np
cimport cython

# For this File cython optimization is irrelevant !

# player method, for human player
cpdef player(board : amazons.Board):

    while True:
        (s, d) = map(alphabet2num,
                     input(("white" if board.wturn else "black") + " amazonmove please: e.g. a8-a4: ").split("-"))
        if try_move(board,(s, d)):
            board.board[d] = board.board[s]
            board.board[s] = 0
            break
        else:
            print("invalid move or input")

    print(board)

    while True:
        a = alphabet2num(input("arrow coords please: e.g. a5: "))
        if try_move(board,(d, a)):
            board.board[a] = -1
            break
        else:
            print("invalid arrow pos or input")

    board.wturn = not board.wturn 
    print(s,d,a)
    return

# only relevant for human player, check if way is free or not
cpdef try_move(board : amazons.Board, input_tup: tuple):

        (s, d) = input_tup

        if d[0] not in range(board.board.shape[0]) or d[1] not in range(board.board.shape[0]):
            print("ERR outofbounds")
            return False

        if (board.wturn and board.board[s] != 1) or (not board.wturn and board.board[s] != 2):
            print("Err TURN")
            return False

        (h, v) = (s[0] - d[0], s[1] - d[1])

        if (h and v and abs(h / v) != 1) or (not h and not v):
            print("ERR DIR", h, v)
            return False

        op = (0 if not h else (-int(h / abs(h))), 0 if not v else (-int(v / abs(v))))
        indx = np.arange(board.board.shape[0])
        # own approach on is_free check, excluding any loops -> could be used to generate random moves later on
        les = s[0] if not op[0] else indx[
                                     max(0, min(s[0] + op[0], d[0]))
                                     :min(board.size, max(s[0], d[0] + op[0]))][
                                     ::op[0]]

        res = s[1] if not op[1] else indx[
                                     max(0, min(s[1] + op[1], d[1]))
                                     :min(board.size, max(s[1], d[1] + op[1]))][
                                     ::op[1]]

        if np.any(board.board[(les, res)]):
            print("ERR NOT FREE")
            return False

        return True

# inputstring to format
cpdef alphabet2num(pos_raw):
    return int(pos_raw[1:]) - 1, ord(pos_raw[0]) - ord('a')