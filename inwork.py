import copy

import numpy as np

ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])



# fuer #moves heuristik


def get_moves(board, s):
    global ops, qmove, amoves
    boardx = np.pad(board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range

    i = 1
    moves = []
    while len(ops > 0):
        sused = (s + ops)
        calcmoves = boardx[tuple(zip(*sused))]
        print(calcmoves, s)
        ops = (ops[calcmoves == 0] / i).astype(int)
        for y in sused[calcmoves == 0]:
            moves.append(y)
        i += 1
        ops = ops * i
    print(moves)
    print(len(moves))
    maph = {}
    for qmove in moves:
        i = 1
        amoves = []
        ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
        boardx[tuple(qmove)] = boardx[tuple(s)]
        boardx[tuple(s)] = 0
        while len(ops > 0):
            sused = (qmove + ops)
            calcmoves = boardx[tuple(zip(*sused))]
            print(calcmoves)
            ops = (ops[calcmoves == 0] / i).astype(int)
            for y in sused[calcmoves == 0]:
                amoves.append(y)
            i += 1
            ops = ops * i
        print(boardx)
        boardx[tuple(s)] = boardx[tuple(qmove)]
        boardx[tuple(qmove)] = 0
        print(amoves)
        maph[(qmove[0], qmove[1])] = copy.copy(amoves)
        print(maph)
    return maph


if __name__ == '__main__':
    board = np.array(
        [[0, - 1, 0, - 1, 2, 0],
         [-1, - 1, - 1, - 1, - 1, - 1],
         [-1, - 1, - 1, 1, 0, - 1],
         [2, - 1, - 1, 0, 0, 0],
         [-1, - 1, 0, 0, 0, 0],
         [-1, 0, 0, 0, 0, 1]]
    )
    indx = np.where(board == 2)  # get amazon indicies
    amazons = np.array(list(np.array([a, b]) for (a, b) in zip(*indx))) + 1  # tuple list to listlist
    movs = []
    for s in amazons:
        maph = get_moves(board, s)

        for key in maph.keys():
            for arrow in maph[key]:
                movs.append((key, arrow))
    print(movs)

'''
Fragen:
    MCTS: ebenen-> rollout definition und strategy
    alphaBeta: turns: move+arrow ?
    idee für Region based -> distance berrechnen 
'''
