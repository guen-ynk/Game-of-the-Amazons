import sqlite3



def main():
    #Connecting to sqlite
    conn = sqlite3.connect('results.db',isolation_level=None)
    # Set journal mode to WAL.
    conn.execute('pragma journal_mode=wal')
    cursor = conn.cursor()

 
    

    #Doping RESULTS table if already exists.
    cursor.execute("DROP TABLE IF EXISTS RESULTS")
    sql = '''CREATE TABLE RESULTS(
    A_METHOD INT,
    B_METHOD INT,
    MCTS_SIMS INT,
    TIMER INT,
    WINS INT,
    GAMES INT
    )'''
    cursor.execute(sql)

    #Populating the table
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 1, 999999, 1, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 1, 999999, 1, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 4, 999999, 1, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 4, 999999, 1, 0, 0)''')

    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 1, 999999, 5, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 1, 999999, 5, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 4, 999999, 5, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 4, 999999, 5, 0, 0)''')

    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 1, 999999, 10, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 1, 999999, 10, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 4, 999999, 10, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 4, 999999, 10, 0, 0)''')

    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 1, 999999, 20, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 1, 999999, 20, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 4, 999999, 20, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 4, 999999, 20, 0, 0)''')

    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 1, 999999, 30, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 1, 999999, 30, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 4, 999999, 30, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 4, 999999, 30, 0, 0)''')

    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (1, 3, 999999, 1, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (1, 5, 999999, 1, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (4, 3, 999999, 1, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (4, 5, 999999, 1, 0, 0)''')

    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (1, 3, 999999, 5, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (1, 5, 999999, 5, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (4, 3, 999999, 5, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (4, 5, 999999, 5, 0, 0)''')
    
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (1, 3, 999999, 10, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (1, 5, 999999, 10, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (4, 3, 999999, 10, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (4, 5, 999999, 10, 0, 0)''')

    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (1, 3, 999999, 20, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (1, 5, 999999, 20, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (4, 3, 999999, 20, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (4, 5, 999999, 20, 0, 0)''')

    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (1, 3, 999999, 30, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (1, 5, 999999, 30, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (4, 3, 999999, 30, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (4, 5, 999999, 30, 0, 0)''')

    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 5, 999999, 1, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 3, 999999, 1, 0, 0)''')
   
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 5, 999999, 5, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 3, 999999, 5, 0, 0)''')

    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 5, 999999, 10, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 3, 999999, 10, 0, 0)''')
    
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 5, 999999, 20, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 3, 999999, 20, 0, 0)''')
    
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (3, 5, 999999, 30, 0, 0)''')
    cursor.execute('''INSERT INTO RESULTS(A_METHOD, B_METHOD, MCTS_SIMS, TIMER, WINS, GAMES) 
    VALUES (5, 3, 999999, 30, 0, 0)''')
      
    conn.commit()
    conn.close()

def updateSqliteTable():
    try:
        sqliteConnection = sqlite3.connect('results.db')
        cursor = sqliteConnection.cursor()
        info = open("../Data/stableres.txt", "r")

        for ga in info.readlines():

            game = ga.split()
            win = game[0].split(':')[1]
            timer = game[4].split(':')[1]
            A = game[1].split(':')[1]
            B = game[2].split(':')[1]
        

            sql_update_query = """Update RESULTS set GAMES = GAMES+1, WINS = WINS +"""+ win + """ where TIMER= """+ timer + """ AND A_METHOD= """+ A +""" AND B_METHOD="""+B 

            cursor.execute(sql_update_query)
            sqliteConnection.commit()
        
        cursor.close()

    except sqlite3.Error as error:
        print("Failed to update sqlite table", error)
    finally:
        if sqliteConnection:
            sqliteConnection.close()
            print("The SQLite connection is closed")


main() # comment if table already exists and data is to add only
updateSqliteTable() # update: feed stableres.txt results into database
