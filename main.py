import copy as cp
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

    def moves_heuristic(self):
        indx = np.where(self.board == NWHITEQ) if self.WTurn else np.where(self.board == NBLACKQ)  # get amazon indicies
        amazons = np.array(list(np.array([a, b]) for (a, b) in zip(*indx))) + 1  # tuple list to listlist
        movs = []
        for amazon in amazons:
            maph = self.get_moves(amazon)
            for key in maph.keys():
                for arrow in maph[key]:
                    movs.append((amazon, key, arrow))
        return movs

    def evaluate(self):
        self.WTurn = not self.WTurn

    def perform_move(self, move):
        self.move(tuple(move[0] - 1),
                  tuple(np.array(move[1]) - 1))
        self.shoot(tuple(np.array(move[2]) - 1))
        self.evaluate()

    def del_move(self, move):
        self.move(tuple(np.array(move[1]) - 1),
                  tuple(move[0] - 1))
        self.board[tuple(np.array(move[2]) - 1)] = NEMPTY
        self.evaluate()

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
    def evaluate(board):
        return len(board.moves_heuristic())


class AI:
    INFINITE = 10000000

    @staticmethod
    def get_ai_move(board: Board):  # 1 white 2 black
        best_move = 0
        best_score = AI.INFINITE
        for move in board.get_possible_moves():
            board.perform_move(move)
            score = AI.alphabeta(board, 2 if np.count_nonzero(board==0) > 20 else 3, -AI.INFINITE, AI.INFINITE, True)  # set 2 and higer depending on movs length
            board.del_move(move)

            if score < best_score:
                best_score = score
                best_move = move

        # Checkmate.
        if best_move == 0:
            return 0  # bug am ende

        return best_move

    @staticmethod
    def alphabeta(board, depth, a, b, maximizing):
        if depth == 0 or board.iswon():
            return Heuristics.evaluate(board)

        if maximizing:
            best_score = -AI.INFINITE
            for move in board.get_possible_moves():
                board.perform_move(move)
                best_score = max(best_score, AI.alphabeta(board, depth - 1, a, b, False))
                board.del_move(move)

                a = max(a, best_score)
                if b <= a:
                    break
            return best_score
        else:
            best_score = AI.INFINITE
            for move in board.get_possible_moves():
                board.perform_move(move)
                best_score = min(best_score, AI.alphabeta(board, depth - 1, a, b, True))
                board.del_move(move)

                b = min(b, best_score)
                if b <= a:
                    break
            return best_score


def ai(board: Board, mode):
    tmp = AI.get_ai_move(cp.deepcopy(board))
    if tmp:
        board.perform_move(tmp)
    else:
        exit(1)
    return tmp


if __name__ == '__main__':
    game = Amazons("config6x6.txt")
    # example situation

    print(game.board)
    game.game()
