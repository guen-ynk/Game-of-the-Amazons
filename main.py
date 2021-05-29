import copy as cp
import time

import numpy as np

# codes
NARROW = -1
NEMPTY = 0
NWHITEQ = 1
NBLACKQ = 2

CHARS: dict = {
    -1: '■',
    0: '.',
    1: 'W',
    2: 'B'
}

MODES = ["player", "AB", "MCTS"]


class Amazons:
    def __init__(self, config="config.txt"):
        info = open(config, "r")
        self.n = int(info.readline())
        white = info.readline().split(":")
        self.white_mode = int(white[0])
        self.white_init = list(map(alphabet2num, white[1].split()))
        black = info.readline().split(":")
        self.black_mode = int(black[0])
        self.black_init = list(map(alphabet2num, black[1].split()))
        self.player = [self.white_mode, self.black_mode]
        self.board = Board(self.n, self.white_init, self.black_init)

    def game(self):
        ongoing: bool = True
        while ongoing:
            for n, x in enumerate(self.player):
                if self.board.iswon():
                    print("No Moves possible", "black" if n else "white", "lost")
                    ongoing = False
                    break
                move = player(board=self.board) if not x else ai(board=self.board, mode=x)
                print(game.board, "\nMOVE: ", move, "\n")

    def __str__(self):
        return str(self.n) + " " + MODES[self.white_mode] + str(self.white_init) + " " + MODES[self.black_mode] + str(
            self.black_init) + "\n" + str(self.board)


class Board:
    def __init__(self, size, white_init, black_init, wturn: bool = True):
        self.WTurn = wturn  # init White is first
        self.size = size
        self.indx = np.arange(size)
        self.board = np.zeros((size, size), dtype=int)  # fill size x size  with empty fields
        self.board[tuple(zip(*white_init))] = NWHITEQ  # fill in Amazons
        self.board[tuple(zip(*black_init))] = NBLACKQ
        self.ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
        self.wboard, self.bboard = None, None
        self.tables = [{}, {}]

    def try_move(self, input_tup: tuple):

        (s, d) = input_tup

        if d[0] not in range(self.size) or d[1] not in range(self.size):
            print("ERR outofbounds")
            return False

        if (self.WTurn and self.board[s] != NWHITEQ) or (not self.WTurn and self.board[s] != NBLACKQ):
            print("Err TURN")
            return False

        (h, v) = (s[0] - d[0], s[1] - d[1])

        if (h and v and abs(h / v) != 1) or (not h and not v):
            print("ERR DIR", h, v)
            return False

        op = (0 if not h else (-int(h / abs(h))), 0 if not v else (-int(v / abs(v))))

        # own approach on is_free check, excluding any loops -> could be used to generate random moves later on
        les = s[0] if not op[0] else self.indx[
                                     max(0, min(s[0] + op[0], d[0]))
                                     :min(self.size, max(s[0], d[0] + op[0]))][
                                     ::op[0]]

        res = s[1] if not op[1] else self.indx[
                                     max(0, min(s[1] + op[1], d[1]))
                                     :min(self.size, max(s[1], d[1] + op[1]))][
                                     ::op[1]]

        if np.any(self.board[(les, res)]):
            print("ERR NOT FREE")
            return False

        return True

    def iswon(self):
        indx = np.where(self.board == NWHITEQ) if self.WTurn else np.where(self.board == NBLACKQ)  # get amazon indicies

        amazons = np.array(list(np.array([a, b]) for (a, b) in zip(*indx))) + 1  # tuple list to listlist
        moves = list(map(lambda x: x + self.ops, amazons))  # calculate moves
        xx = np.pad(self.board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
        calcmoves = np.array(list(map(lambda x: xx[tuple(zip(*x))], moves)))  # get values of fields
        return not 0 in calcmoves  # check if free

    def move(self, s, d):
        self.board[d] = self.board[s]
        self.board[s] = NEMPTY

    def shoot(self, d):
        self.board[d] = NARROW

    def get_moves_q(self, s):
        boardx = np.pad(self.board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
        ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])

        i = 1
        while len(ops) > 0:
            sused = (s + ops)
            calcmoves = boardx[tuple(zip(*sused))]
            ops = (ops[calcmoves == 0] / i).astype(int)
            for y in sused[calcmoves == 0]:
                yield y
            i += 1
            ops = ops * i

    def get_possible_moves(self):
        indx = np.where(self.board == NWHITEQ) if self.WTurn else np.where(self.board == NBLACKQ)  # get amazon indicies
        amazons = np.array(list(np.array([a, b]) for (a, b) in zip(*indx))) + 1  # tuple list to listlist
        boardx = np.pad(self.board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
        for s in amazons:
            for qmove in self.get_moves_q(s):
                i = 1
                ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
                boardx[tuple(qmove)] = boardx[tuple(s)]
                boardx[tuple(s)] = NEMPTY
                while len(ops > 0):
                    sused = (qmove + ops)
                    calcmoves = boardx[tuple(zip(*sused))]
                    ops = (ops[calcmoves == 0] / i).astype(int)
                    for y in sused[calcmoves == 0]:
                        yield s, qmove, y
                    i += 1
                    ops = ops * i
                boardx[tuple(s)] = boardx[tuple(qmove)]
                boardx[tuple(qmove)] = NEMPTY

    def evaluate(self):
        self.WTurn = not self.WTurn

    def perform_move(self, move):
        white = True if self.board[tuple(np.array(move[0]) - 1)] == NWHITEQ else False
        self.board[tuple(np.array(move[1]) - 1)] = NWHITEQ if white else NBLACKQ
        self.board[tuple(np.array(move[0]) - 1)] = NEMPTY
        self.board[tuple(np.array(move[2]) - 1)] = NARROW
        self.WTurn = not white

    def del_move(self, move):
        white = True if self.board[tuple(np.array(move[1]) - 1)] == NWHITEQ else False
        self.board[tuple(np.array(move[2]) - 1)] = NEMPTY
        self.board[tuple(np.array(move[1]) - 1)] = NEMPTY
        self.board[tuple(np.array(move[0]) - 1)] = NWHITEQ if white else NBLACKQ
        self.WTurn = not white

    def __str__(self):
        return "{0}\n{1}".format(("   " + "  ".join([chr(ord("a") + y) for y in range(self.size)])), "\n".join(
            [(str(x + 1) + ("  " if x < 9 else " ")) + "  ".join(map(lambda x: CHARS[x], self.board[x])) for x in
             range(self.size - 1, -1, -1)]))


def alphabet2num(pos_raw) -> tuple:
    return int(pos_raw[1:]) - 1, ord(pos_raw[0]) - ord('a')


def player(board):
    while True:
        (s, d) = map(alphabet2num,
                     input(("white" if board.WTurn else "black") + " amazonmove please: e.g. a8-a4: ").split("-"))
        if board.try_move((s, d)):
            board.move(s, d)
            break
        else:
            print("invalid move or input")

    print(board)

    while True:
        a = alphabet2num(input("arrow coords please: e.g. a5: "))
        if board.try_move((d, a)):
            board.shoot(a)
            break
        else:
            print("invalid arrow pos or input")

    print(board)
    board.evaluate()

    return s, d, a


class Heuristics:
    @staticmethod
    def getMovesInRadius(board, check, s, depth, color):
        ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
        boardx = np.pad(board.board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
        boardh = board.wboard if color else board.bboard
        i = 1
        while len(ops > 0):
            one_step_each_dir = (s + ops)  # go 1 step in each direction
            fields = boardx[tuple(zip(*one_step_each_dir))]  # get the value of those fields
            ops = (ops[fields == 0] / i).astype(int)  # only keep the free directions, normalize ops and keep the type
            for y in one_step_each_dir[fields == 0]:
                if not check[tuple(y - 1)]:
                    boardh[tuple(y - 1)] = min(
                        boardh[tuple(y - 1)],
                        depth
                    )
                    check[tuple(y - 1)] = 1
                    yield y
            i += 1
            ops = ops * i  # jump to nth step

    @staticmethod
    def amazonBFS(board, s, color):
        moves = [s]
        checkboard = np.zeros_like(board.board)
        for x in range(1, board.size * board.size):
            movesnn = []
            for m in moves:
                for r in Heuristics.getMovesInRadius(board, checkboard, m, x, color):
                    movesnn.append(r)
            moves = movesnn
            if not moves:
                break

    @staticmethod
    def territorial_eval_heurisic(board: Board):

        board.wboard = np.full_like(board.board, fill_value=999)
        board.bboard = np.full_like(board.board, fill_value=999)
        for x in [True, False]:
            indx = np.where(board.board == 1) if x else np.where(board.board == 2)  # get amazon indicies
            amazons = np.array(list(np.array([a, b]) for (a, b) in zip(*indx))) + 1  # tuple list to listlist
            for a in amazons:
                Heuristics.amazonBFS(board, a, x)
        for i in range(board.size):
            for j in range(board.size):
                if board.WTurn:
                    if board.wboard[i][j] == 999 and board.bboard[i][j] == 999:
                        board.wboard[i][j] = 0
                    elif board.wboard[i][j] == board.bboard[i][j]:
                        board.wboard[i][j] = 1 / 5
                    elif board.wboard[i][j] > board.bboard[i][j]:
                        board.wboard[i][j] = 1
                    else:
                        board.wboard[i][j] = -1
                    return np.sum(board.wboard)
                else:
                    if board.wboard[i][j] == 999 and board.bboard[i][j] == 999:
                        board.bboard[i][j] = 0
                    elif board.wboard[i][j] == board.bboard[i][j]:
                        board.bboard[i][j] = 1 / 5
                    elif board.wboard[i][j] > board.bboard[i][j]:
                        board.bboard[i][j] = -1
                    else:
                        board.bboard[i][j] = 1
                    return np.sum(board.bboard)

    @staticmethod
    def get_moves_q(board, s):
        boardx = np.pad(board.board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
        ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])

        i = 1
        while len(ops) > 0:

            sused = (s + ops)
            calcmoves = boardx[tuple(zip(*sused))]
            ops = (ops[calcmoves == 0] / i).astype(int)
            for y in sused[calcmoves == 0]:
                yield y
            i += 1
            ops = ops * i


    @staticmethod
    def get_moves(board: Board, s):
        boardx = np.pad(board.board, 1, "constant", constant_values=-1)  # pad -1 around board for moves beyond range
        count = 0
        for qmove in Heuristics.get_moves_q(board, s):
            i = 1
            ops = np.array([[-1, 0], [1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [1, -1], [1, 1]])
            boardx[tuple(qmove)] = boardx[tuple(s)]
            boardx[tuple(s)] = NEMPTY
            while len(ops) > 0:
                sused = (qmove + ops)
                calcmoves = boardx[tuple(zip(*sused))]
                ops = (ops[calcmoves == 0] / i).astype(int)
                count += len(sused[calcmoves == 0])
                i += 1
                ops = ops * i
            boardx[tuple(s)] = boardx[tuple(qmove)]
            boardx[tuple(qmove)] = NEMPTY

        return count

    @staticmethod
    def moves_heuristic(board) -> int:
        indx = np.where(board.board == NWHITEQ) if board.WTurn else np.where(
            board.board == NBLACKQ)  # get amazon indicies
        amazons = np.array(list(np.array([a, b]) for (a, b) in zip(*indx))) + 1  # tuple list to listlist
        i = 0
        for amazon in amazons:
            i += Heuristics.get_moves(board, amazon)

        return i

    @staticmethod
    def evaluate(board: Board, mode):
        if mode == 1:
            return Heuristics.moves_heuristic(board)
        if mode == 2:
            x = Heuristics.territorial_eval_heurisic(board)
            return x


class AI:
    INFINITE = 10000000

    @staticmethod
    def get_ai_move(board: Board, mode):  # 1 white 2 black
        best_move = 0
        best_score = AI.INFINITE
        stamp = time.time()

        for move in board.get_possible_moves():

            board.perform_move(move)
            state = len(np.where(board.board == 0)[0])
            if state > 15:
                depth = 2
            else:
                depth = 2
            score = AI.alphabeta(board, depth, -AI.INFINITE, AI.INFINITE,
                                 True, mode)
            board.del_move(move)
            print(time.time() - stamp)
            stamp = time.time()
            if score < best_score:
                best_score = score
                best_move = move

        # Checkmate.
        if best_move == 0:
            return 0  # bug am ende

        return best_move

    @staticmethod
    def alphabeta(board: Board, depth, a, b, maximizing, mode):
        if depth == 0 or board.iswon():
            ha = hash(board.board.tobytes())
            if ha in board.tables[mode - 1].keys():
                return board.tables[mode - 1][ha]
            else:
                heu = Heuristics.evaluate(board, mode)
                board.tables[mode - 1][hash(board.board.tobytes())] = heu
                board.tables[mode - 1][hash(np.fliplr(board.board).tobytes())] = heu
                board.tables[mode - 1][hash(np.flipud(board.board).tobytes())] = heu

            return heu

        if maximizing:
            best_score = -AI.INFINITE
            for move in board.get_possible_moves():
                board.perform_move(move)
                best_score = max(best_score, AI.alphabeta(board, depth - 1, a, b, False, mode))

                board.del_move(move)

                a = max(a, best_score)
                if b <= a:
                    break
            return best_score
        else:
            best_score = AI.INFINITE

            for move in board.get_possible_moves():
                board.perform_move(move)
                best_score = min(best_score, AI.alphabeta(board, depth - 1, a, b, True, mode))
                board.del_move(move)

                b = min(b, best_score)
                if b <= a:
                    break
            return best_score


def ai(board: Board, mode):
    tmp = AI.get_ai_move(cp.deepcopy(board), mode)
    if tmp:
        board.perform_move(tmp)
    return tmp


if __name__ == '__main__':
    game = Amazons("config6x6.txt")
    # example situation
    print(game.board)
    game.game()
