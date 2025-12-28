#!/bin/bash
# ========= CONFIGURAÇÃO =========
stty -echo -icanon time 0 min 0
tput civis
trap "stty sane; tput cnorm; clear; exit" EXIT
clear

ROWS=$(tput lines)
COLS=$(tput cols)

ROAD_W=$((COLS / 3))
ROAD_L=$((COLS / 2 - ROAD_W / 2))
ROAD_R=$((COLS / 2 + ROAD_W / 2))

CAR_X=$((COLS / 2))
CAR_Y=$((ROWS - 6))

FRAME=0
DIST=0
SPEED=0.07
DIR="NONE"

HIGH_SCORE_FILE="$HOME/.bash_racing_highscore"
[ ! -f "$HIGH_SCORE_FILE" ] && echo "0" > "$HIGH_SCORE_FILE"
HIGH_SCORE=$(cat "$HIGH_SCORE_FILE")

# ========= OBSTÁCULOS =========
MAX_OBS=6
declare -A OBS_X OBS_Y OBS_TYPE

spawn_obstacle() {
  local id=$1
  OBS_Y[$id]=1
  OBS_X[$id]=$((RANDOM % (ROAD_R-ROAD_L-6) + ROAD_L + 3))
  OBS_TYPE[$id]=$((RANDOM % 3))
}

for i in $(seq 0 $((MAX_OBS-1))); do spawn_obstacle $i; done

# ========= CARROS INIMIGOS =========
MAX_ENEMY=2
declare -A ENEMY_X ENEMY_Y

spawn_enemy() {
  local id=$1
  ENEMY_Y[$id]=$((RANDOM % 5))
  ENEMY_X[$id]=$((RANDOM % (ROAD_R-ROAD_L-4) + ROAD_L + 2))
}

for i in $(seq 0 $((MAX_ENEMY-1))); do spawn_enemy $i; done

# ========= LOOP PRINCIPAL =========
while true; do
  # ---------- INPUT RESPONSIVO ----------
  read -rsn1 -t 0.01 key
  case "$key" in
    a) DIR="LEFT" ;;
    d) DIR="RIGHT" ;;
    "") DIR="NONE" ;;
    q) break ;;
  esac

  # Atualiza posição do carro
  case "$DIR" in
    LEFT) ((CAR_X--)) ;;
    RIGHT) ((CAR_X++)) ;;
  esac
  ((CAR_X<ROAD_L+3)) && CAR_X=$((ROAD_L+3))
  ((CAR_X>ROAD_R-3)) && CAR_X=$((ROAD_R-3))

  # ---------- ATUALIZA OBSTÁCULOS ----------
  for i in $(seq 0 $((MAX_OBS-1))); do
    ((OBS_Y[$i]++))
    if ((OBS_Y[$i] > ROWS)); then
      spawn_obstacle $i
    fi
  done

  # ---------- ATUALIZA CARROS INIMIGOS ----------
  for i in $(seq 0 $((MAX_ENEMY-1))); do
    ((ENEMY_Y[$i]++))
    if ((ENEMY_Y[$i] > ROWS)); then
      spawn_enemy $i
    fi
  done

  # ---------- CHECA COLISÃO ----------
  collision=0
  for i in $(seq 0 $((MAX_OBS-1))); do
    if (( OBS_Y[$i] >= CAR_Y && OBS_Y[$i] <= CAR_Y+2 )); then
      if (( OBS_X[$i] >= CAR_X-2 && OBS_X[$i] <= CAR_X+2 )); then
        collision=1
      fi
    fi
  done
  for i in $(seq 0 $((MAX_ENEMY-1))); do
    if (( ENEMY_Y[$i] >= CAR_Y && ENEMY_Y[$i] <= CAR_Y+2 )); then
      if (( ENEMY_X[$i] >= CAR_X-2 && ENEMY_X[$i] <= CAR_X+2 )); then
        collision=1
      fi
    fi
  done
  ((collision==1)) && break

  # ---------- RENDERIZAÇÃO ----------
  buffer=""
  for ((y=1;y<=ROWS;y++)); do
    line=""
    for ((x=1;x<=COLS;x++)); do
      # Carro jogador
      if ((y==CAR_Y && x==CAR_X)); then line+="\e[31m▲\e[0m"; continue; fi
      if ((y==CAR_Y+1 && x>=CAR_X-1 && x<=CAR_X+1)); then line+="\e[31m█\e[0m"; continue; fi
      if ((y==CAR_Y+2 && x==CAR_X)); then line+="\e[31m│\e[0m"; continue; fi

      # Obstáculos
      drew=0
      for i in $(seq 0 $((MAX_OBS-1))); do
        if ((y==OBS_Y[$i])); then
          case ${OBS_TYPE[$i]} in
            0) [[ $x -ge ${OBS_X[$i]} && $x -le ${OBS_X[$i]}+1 ]] && line+="\e[33m▲\e[0m" && drew=1 ;;
            1) [[ $x -ge ${OBS_X[$i]} && $x -le ${OBS_X[$i]}+3 ]] && line+="\e[93m█\e[0m" && drew=1 ;;
            2) [[ $x -ge ${OBS_X[$i]} && $x -le ${OBS_X[$i]}+2 ]] && line+="\e[34m◯\e[0m" && drew=1 ;;
          esac
        fi
      done
      ((drew==1)) && continue

      # Carros inimigos
      drew=0
      for i in $(seq 0 $((MAX_ENEMY-1))); do
        if ((y==ENEMY_Y[$i])); then
          [[ $x -ge ENEMY_X[$i] && $x -le ENEMY_X[$i]+1 ]] && line+="\e[35m█\e[0m" && drew=1
        fi
      done
      ((drew==1)) && continue

      # Estrada com curva simulada
      curve=$(( (FRAME/5) % 5 - 2 ))  # movimento lateral da pista
      rleft=$((ROAD_L+curve))
      rright=$((ROAD_R+curve))
      if ((x>=rleft && x<=rright)); then
        if (( (y+FRAME) % 6 == 0 && x==(COLS/2)+curve )); then line+="\e[97m|\e[0m"; else line+=" "; fi
      else
        line+="\e[42m \e[0m"
      fi
    done
    buffer+="$line"$'\n'
  done

  tput cup 0 0
  echo -ne "$buffer"

  # ---------- DISTÂNCIA E ACELERAÇÃO ----------
  ((DIST++))
  if (( DIST % 50 == 0 )); then
    SPEED=$(awk -v s="$SPEED" 'BEGIN{if(s>0.02) print s*0.95; else print s}')
  fi

  ((FRAME++))
  sleep $SPEED
done

# ========= FIM DO JOGO =========
clear
echo "💥 ACIDENTE!"
echo "🏁 Distância percorrida: $DIST"

# Atualiza highscore
if ((DIST > HIGH_SCORE)); then
  echo $DIST > "$HIGH_SCORE_FILE"
  echo "🏆 Novo recorde!"
else
  echo "Recorde: $HIGH_SCORE"
fi

tput cnorm
stty sane

