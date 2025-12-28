#!/bin/bash

# Config terminal
tput civis
stty -echo
trap "tput cnorm; stty echo; clear; exit" EXIT

WIDTH=50
HEIGHT=20
SPEED=0.1

# Direção
dir=RIGHT

# Cobrinha
snake_x=(10 9 8)
snake_y=(10 10 10)

# Comida
food_x=$((RANDOM % (WIDTH-2) + 2))
food_y=$((RANDOM % (HEIGHT-2) + 2))

draw_border() {
  for ((x=1;x<=WIDTH;x++)); do
    tput cup 1 $x; echo "#"
    tput cup $HEIGHT $x; echo "#"
  done
  for ((y=1;y<=HEIGHT;y++)); do
    tput cup $y 1; echo "#"
    tput cup $y $WIDTH; echo "#"
  done
}

place_food() {
  food_x=$((RANDOM % (WIDTH-2) + 2))
  food_y=$((RANDOM % (HEIGHT-2) + 2))
  tput cup $food_y $food_x
  echo "@"
}

clear
draw_border
place_food

while true; do
  # Entrada
  read -rsn1 -t $SPEED key
  case "$key" in
    w) [[ $dir != DOWN ]] && dir=UP ;;
    s) [[ $dir != UP ]] && dir=DOWN ;;
    a) [[ $dir != RIGHT ]] && dir=LEFT ;;
    d) [[ $dir != LEFT ]] && dir=RIGHT ;;
  esac

  # Nova cabeça
  hx=${snake_x[0]}
  hy=${snake_y[0]}

  case $dir in
    UP)    ((hy--)) ;;
    DOWN)  ((hy++)) ;;
    LEFT)  ((hx--)) ;;
    RIGHT) ((hx++)) ;;
  esac

  # Colisão com parede
  if ((hx<=1 || hx>=WIDTH || hy<=1 || hy>=HEIGHT)); then
    break
  fi

  # Apaga cauda
  tx=${snake_x[-1]}
  ty=${snake_y[-1]}
  tput cup $ty $tx
  echo " "

  # Move corpo
  snake_x=("$hx" "${snake_x[@]}")
  snake_y=("$hy" "${snake_y[@]}")
  snake_x=("${snake_x[@]:0:${#snake_x[@]}-1}")
  snake_y=("${snake_y[@]:0:${#snake_y[@]}-1}")

  # Desenha cabeça
  tput cup $hy $hx
  echo "O"

  # Comeu comida
  if ((hx==food_x && hy==food_y)); then
    snake_x+=("$tx")
    snake_y+=("$ty")
    place_food
  fi
done

tput cnorm
stty echo
tput cup $((HEIGHT+2)) 1
echo "🐍 Game Over"

