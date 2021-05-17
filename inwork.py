import numpy as np
import copy
size = 10
board = np.zeros((size, size), dtype=int)
ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])

s = np.array([2, 2]) + 1
board[(1, 1)] = -1
board[(2, 2)] = 1
board[(3, 3)] = 2

print(board)

# fuer #moves heuristik


def get_moves(board, s):
    global ops, qmove, amoves
    boardx = np.pad(board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range

    i = 1
    moves = []
    while len(ops > 0):
        sused = (s + ops)
        calcmoves = boardx[tuple(zip(*sused))]
        ops = (ops[calcmoves == 0] / i).astype(int)
        for y in sused[calcmoves == 0]:
            moves.append(y)
        i += 1
        ops = ops * i

    print(len(moves))
    maph = {}
    for qmove in moves:
        i = 1
        amoves = []
        ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])

        while len(ops > 0):
            sused = (qmove + ops)
            calcmoves = boardx[tuple(zip(*sused))]
            ops = (ops[calcmoves == 0] / i).astype(int)
            for y in sused[calcmoves == 0]:
                amoves.append(y)
            i += 1
            ops = ops * i

        maph[(qmove[0], qmove[1])] = copy.copy(amoves)
    movecount = 0
    for k in maph.keys():
        tboard = copy.copy(board)
        print(k, maph[k], len(maph[k]))
        movecount+=len(maph[k])
        # fuer visualisierung später
        tmp = np.array(maph[k])-1
        tboard[tuple(zip(*tmp))] = 9
        print(tboard)
    print(movecount)
get_moves(board, s)
'''
Fragen:
    MCTS: ebenen-> rollout definition und strategy
    alphaBeta: turns: move+arrow ?
    idee für Region based -> distance berrechnen 
'''
