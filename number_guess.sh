#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate random number between 1 - 1000
SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))
#echo $SECRET_NUMBER

# Program logic
echo -e "\nEnter your username:"
read USERNAME

echo ""

# Get username
USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME'")

# if user doesn't exist
if [[ -z $USER_ID ]]
then
  # greet new user
  echo "Welcome, $USERNAME! It looks like this is your first time here."

  # insert new user
  INSERT_USER_ID=$($PSQL "INSERT INTO users(name) VALUES('$USERNAME')")

  # get user_id
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME'")
else
  # get user stats

  # <games_played> total number of games that user has played
  GAMES_PLAYED=$($PSQL "SELECT COUNT(game_id) FROM games INNER JOIN users USING (user_id) WHERE user_id = $USER_ID")

  # <best_game> being the fewest number of guesses it took that user to win the game
  BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games FULL JOIN users USING (user_id) WHERE user_id = $USER_ID")
  
  # greet user
  # *notes: Welcome back, <username>! You have played <games_played> games, and your best game took <best_game> guesses.
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Guess Game Start
echo -e "\nGuess the secret number between 1 and 1000:"

# init number_of_guesses counter
NUMBER_OF_GUESSES=0

# Game loop logic
while true
do
  # retry guess until win
  read GUESS_TRY

  # if input not a number
  if [[ ! $GUESS_TRY =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  else
    # if input guess is higher than secret number
    if [[ $GUESS_TRY > $SECRET_NUMBER ]]
    then
      echo "It's lower than that, guess again:"
      (( NUMBER_OF_GUESSES+=1 ))

    # if input guess is lower than secret number
    elif [[ $GUESS_TRY < $SECRET_NUMBER ]]
    then
      echo "It's higher than that, guess again:"
      (( NUMBER_OF_GUESSES+=1 ))

    else
    # if correct guess: Insert to database and output success message
      (( NUMBER_OF_GUESSES+=1 ))
      INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)")
      echo -e "\nYou guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!\n"
      break
    fi
  fi

done
