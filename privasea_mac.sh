#!/usr/bin/env zsh
set -e

if [[ "$1" != "child-run" ]]; then
  ################################################################
  # (부모) 스크립트: screen 세션을 백그라운드로 만들고 자동 접속
  ################################################################
  SCREEN_NAME="privasea_setup_session"

  echo "현재 screen 세션이 아닙니다. 새로운 screen 세션($SCREEN_NAME)에서 스크립트를 실행합니다."
  # screen 백그라운드로 띄움
  screen -dmS "$SCREEN_NAME" zsh -c "$0 child-run"

  # 1초 기다린 뒤 자동 접속
  sleep 1
  echo "screen -r $SCREEN_NAME 로 진입합니다..."
  screen -r "$SCREEN_NAME"
  exit 0
fi

################################################################
# (자식) 스크립트: 여기부터 실제 Privasea 설치/실행 로직
################################################################

echo "============================================="
echo "[screen 내부] Privasea Node Setup (MacOS) 시작"
echo "============================================="
echo ""

################################################
# 1. Homebrew 및 필수 패키지 설치
################################################
if ! command -v brew &>/dev/null; then
  echo "[ERROR] Homebrew가 설치되어 있지 않습니다."
  echo "        먼저 아래 명령어로 Homebrew 설치를 진행해주세요:"
  echo "        /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  exit 1
fi

echo "=== [1] Homebrew 업데이트 및 필수 패키지 설치 ==="
brew update
brew install screen wget curl

################################################
# 2. Docker 설치 확인 (Docker Desktop 권장)
################################################
if ! command -v docker &>/dev/null; then
  echo "Docker가 설치되어 있지 않습니다. Docker Desktop을 설치합니다..."
  brew install --cask docker

  echo "[INFO] Docker Desktop 첫 설치 시, 수동 실행이 필요합니다."
  echo "[INFO] Docker Desktop을 실행하고, 데몬이 구동된 뒤 다시 시도하세요."
  # 여기서 exit해도 무방, 계속 진행해도 Docker 동작 안 할 수 있음
  # exit 1
else
  echo "Docker가 이미 설치되어 있습니다. 건너뜁니다."
fi

echo ""
echo "Docker 버전 확인:"
docker --version || echo "[WARN] Docker 데몬이 실행 중이 아닐 수 있습니다. Docker Desktop을 열어주세요."
echo ""

################################################
# 3. privasea/acceleration-node-beta 이미지 Pull
################################################
IMAGE_NAME="privasea/acceleration-node-beta:latest"
if ! docker images | grep -q "privasea/acceleration-node-beta"; then
  echo "이미지 [$IMAGE_NAME]이 없으므로 Pull 진행..."
  docker pull "$IMAGE_NAME"
else
  echo "이미지 [$IMAGE_NAME]이 이미 존재합니다. 건너뜁니다."
fi

################################################
# 4. /privasea/config 디렉토리 준비
################################################
if [ ! -d "/privasea/config" ]; then
  echo "/privasea/config 디렉토리가 없어서 생성합니다."
  sudo mkdir -p /privasea/config
  sudo chmod 700 /privasea/config
else
  echo "/privasea/config 디렉토리가 이미 존재합니다."
fi

################################################
# 5. Keystore 생성 확인
################################################
if [ ! -f "/privasea/config/wallet_keystore" ]; then
  echo "wallet_keystore 파일이 없으므로 새 지갑을 생성합니다."
  echo "이 과정에서 비밀번호를 직접 입력해야 합니다."
  docker run -it -v "/privasea/config:/app/config" "$IMAGE_NAME" ./node-calc new_keystore

  echo "생성된 keystore 파일명을 wallet_keystore로 변경합니다."
  cd /privasea/config
  UTC_FILE=$(ls | grep '^UTC--' | head -n 1 || true)
  if [ -n "$UTC_FILE" ]; then
    mv "$UTC_FILE" wallet_keystore
    echo "이름 변경 완료 -> wallet_keystore"
  else
    echo "UTC-- 형식의 keystore 파일을 찾지 못했습니다. 직접 확인해주세요."
  fi
  cd ~
else
  echo "이미 /privasea/config/wallet_keystore 파일이 존재합니다. 건너뜁니다."
fi

################################################
# 6. 노드 실행 확인
################################################
RUNNING_CONTAINER=$(docker ps -q --filter "ancestor=$IMAGE_NAME")
if [ -n "$RUNNING_CONTAINER" ]; then
  echo "이미 [$IMAGE_NAME] 컨테이너가 실행 중입니다."
  echo "컨테이너 ID: $RUNNING_CONTAINER"
else
  echo ""
  echo "노드를 백그라운드에서 실행합니다."
  read -sp "설정한 KEYSTORE_PASSWORD를 입력해주세요: " KEYSTORE_PASSWORD
  echo

  docker run -d \
    -v "/privasea/config:/app/config" \
    -e KEYSTORE_PASSWORD="$KEYSTORE_PASSWORD" \
    "$IMAGE_NAME"

  RUNNING_CONTAINER=$(docker ps -q --filter "ancestor=$IMAGE_NAME")
  echo "컨테이너 실행 완료, ID: $RUNNING_CONTAINER"
fi

echo ""
echo "============================================="
echo " Privasea Node 설정이 완료되었습니다 (MacOS)."
echo "============================================="
echo "컨테이너 로그:"
echo "  docker logs -f $RUNNING_CONTAINER"
echo ""
echo "노드를 종료하려면:"
echo "  docker stop $RUNNING_CONTAINER"
echo ""
echo "이제 screen 세션이 유지됩니다. 필요한 작업을 마친 뒤, exit 로 세션을 닫을 수 있습니다."
echo "세션을 detach하려면 Ctrl + A, D"
echo ""

# 스크립트가 끝나도 screen이 바로 종료되지 않도록
exec zsh
