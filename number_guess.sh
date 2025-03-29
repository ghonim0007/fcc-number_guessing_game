#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"


SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
GUESS_COUNT=0


echo "Enter your username:"
read USERNAME


USER_DATA=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_DATA ]]; then

  echo "Welcome, $USERNAME! It looks like this is your first time here."


  INSERT_USER=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)")
  

  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else

  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_DATA"

  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# بدء اللعبة
echo "Guess the secret number between 1 and 1000:"
while true; do
  read GUESS


  if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((GUESS_COUNT++))

  if [[ $GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
    

    UPDATE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id = $USER_ID")


    INSERT_GAME=$($PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $GUESS_COUNT)")


    if [[ -z $BEST_GAME || $GUESS_COUNT -lt $BEST_GAME ]]; then
      UPDATE_BEST_GAME=$($PSQL "UPDATE users SET best_game = $GUESS_COUNT WHERE user_id = $USER_ID")
    fi

    break
  fi
done
