import numpy as np

size = 10
board = np.array([
    [0, 0, -1, 2, -1, 0, 0, 0, 0, 0],
    [0, 0, 1, -1, -1, 0, 0, 0, 0, 0],
    [0, 0, -1, -1, 2, -1, -1, -1, -1, 0],
    [0, -1, -1, 0, -1, 0, 1, 0, -1, 0],
    [-1, 0, 0, 0, 0, -1, 0, 0, 0, 0],
    [0, -1, -1, 0, 0, -1, -1, -1, 0, 0],
    [0, 0, 0, 1, 0, 0, 0, -1, 0, 0],
    [0, -1, 0, 0, 0, 0, 0, 1, 0, -1],
    [0, 0, 0, 2, 0, 0, 2, 0, 0, 0],
    [-1, 0, 0, 0, 0, 0, 0, -1, 0, 0]
])
wboard = np.full_like(board, fill_value=999)
bboard = np.full_like(board, fill_value=999)


def getMovesInRadius(board, check, s, depth=1, color=True) -> list:
    ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])

    boardx = np.pad(board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
    realboard = wboard if color else bboard

    i = 1
    moves = []

    while len(ops > 0):
        one_step_each_dir = (s + ops)  # go 1 step in each direction
        fields = boardx[tuple(zip(*one_step_each_dir))]  # get the value of those fields
        ops = (ops[fields == 0] / i).astype(int)  # only keep the free directions, normalize ops and keep the type

        for y in one_step_each_dir[fields == 0]:
            if not check[tuple(y - 1)]:
                realboard[tuple(y - 1)] = min(
                    realboard[tuple(y - 1)],
                    depth
                )
                check[tuple(y - 1)] = 1
                moves.append(y)

        i += 1
        ops = ops * i  # jump to nth step

    return moves


def amazonBFS(board, s, color=True):
    moves = [s]
    checkboard = np.zeros_like(board)
    for x in range(1, size * size):
        movesnn = []
        for m in moves:
            movesn = getMovesInRadius(board, checkboard, m, x, color)
            for r in movesn:
                movesnn.append(r)
        moves = movesnn
        if not moves:
            break


def territorial_eval_heurisic():
    for x in [True, False]:
        indx = np.where(board == 1) if x else np.where(board == 2)  # get amazon indicies
        amazons = np.array(list(np.array([a, b]) for (a, b) in zip(*indx))) + 1  # tuple list to listlist
        for a in amazons:
            amazonBFS(board, a, x)
    print(wboard)
    print(bboard)
    print(wboard - bboard)


if __name__ == '__main__':
    territorial_eval_heurisic()


def get_moves_q(self, s):
    boardx = np.pad(self.board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
    ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])

    i = 1
    moves = []
    while len(ops > 0):
        sused = (s + ops)
        calcmoves = boardx[tuple(zip(*sused))]
        ops = (ops[calcmoves == 0] / i).astype(int)
        for y in sused[calcmoves == 0]:
            yield y
        i += 1
        ops = ops * i


def get_moves(self, s):
    boardx = np.pad(self.board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range

    maph = {}
    for qmove in self.get_moves_q(s):
        i = 1
        amoves = []
        ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
        boardx[tuple(qmove)] = boardx[tuple(s)]
        boardx[tuple(s)] = NEMPTY
        while len(ops > 0):
            sused = (qmove + ops)
            calcmoves = boardx[tuple(zip(*sused))]
            ops = (ops[calcmoves == 0] / i).astype(int)
            for y in sused[calcmoves == 0]:
                amoves.append(y)
            i += 1
            ops = ops * i
        boardx[tuple(s)] = boardx[tuple(qmove)]
        boardx[tuple(qmove)] = NEMPTY

        maph[(qmove[0], qmove[1])] = cp.copy(amoves)
    return maph
