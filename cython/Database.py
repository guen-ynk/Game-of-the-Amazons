import sqlite3



def main():
    #Connecting to sqlite
    conn = sqlite3.connect('results.db')
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
        
        A = 1
        B = 5
        timess = 5
        win = 1

        sql_update_query = """Update RESULTS set GAMES = GAMES+1, WINS = WINS +"""+ str(win) +""" where TIMER= """+ str(timess)+ """ AND A_METHOD= """+str(A)+""" AND B_METHOD="""+str(B) 

        cursor.execute(sql_update_query)
        sqliteConnection.commit()
        
        cursor.close()

    except sqlite3.Error as error:
        print("Failed to update sqlite table", error)
    finally:
        if sqliteConnection:
            sqliteConnection.close()
            print("The SQLite connection is closed")

#updateSqliteTable()
main()