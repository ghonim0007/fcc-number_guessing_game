#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# توليد رقم عشوائي بين 1 و 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
GUESS_COUNT=0

# طلب اسم المستخدم
echo "Enter your username:"
read USERNAME

# التحقق مما إذا كان المستخدم موجودًا في قاعدة البيانات
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # المستخدم جديد، إدخاله في قاعدة البيانات
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, 1000)"
else
  # المستخدم موجود مسبقًا، عرض بياناته
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# بدء اللعبة
echo "Guess the secret number between 1 and 1000:"
while true; do
  read GUESS

  # التحقق من أن الإدخال عدد صحيح
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

    # تحديث عدد الألعاب وتحسين أفضل محاولة
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
    $PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id = $USER_ID"

    # تحديث أفضل عدد محاولات إذا كان أقل من المسجل مسبقًا
    BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE user_id=$USER_ID")
    if [[ $GUESS_COUNT -lt $BEST_GAME ]]; then
      $PSQL "UPDATE users SET best_game=$GUESS_COUNT WHERE user_id=$USER_ID"
    fi

    break
  fi
done

