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
            for x in self.player:
                if self.board.iswon():
                    print("No Moves possible", x, "lost")
                    ongoing = False
                    break
                (s, d, a) = player(board=self.board) if not x else AI(board=self.board, mode=x)

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

    def evaluate(self):
        self.WTurn = not self.WTurn

    def loop(self):
        print(self.board)

    def __str__(self):
        return "{0}\n{1}".format(("   " + "  ".join([chr(ord("a") + y) for y in range(self.size)])), "\n".join(
            [(str(x + 1) + ("  " if x < 9 else " ")) + "  ".join(map(lambda x: CHARS[x], self.board[x])) for x in
             range(self.size - 1, -1, -1)]))


def alphabet2num(pos_raw) -> tuple:
    return int(pos_raw[1:]) - 1, ord(pos_raw[0]) - ord('a')


def player(board):
    while True:
        (s, d) = map(alphabet2num, input("amazonmove please: e.g. a8-a4: ").split("-"))
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


def AI(board: Board, mode):
    pass


if __name__ == '__main__':
    game = Amazons("config10x10.txt")
    # example situation
    game.board.board = np.array([
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, 1, 0, -1, -1, -1, -1, -1, -1, -1],
        [-1, 0, 0, -1, -1, -1, -1, -1, -1, -1],
        [-1, 0, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, 2, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, 1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, 2, -1, -1, -1],
        [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    ])
    print(game.board)
    game.game()
