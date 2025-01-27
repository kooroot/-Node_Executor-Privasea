#!/usr/bin/env bash
set -e

# 0. 현재 screen 내부인지 확인
if [ -z "$STY" ]; then
  SCREEN_NAME="privasea_setup_session"
  echo "현재 screen 세션이 아닙니다. 새로운 screen 세션($SCREEN_NAME)에서 스크립트를 실행합니다."
  read -rp "Enter 키를 누르면 screen으로 진입 (취소: Ctrl + C)" dummy
  screen -S "$SCREEN_NAME" bash -c "$0"
  # 사용자가 screen을 detach하거나 session을 종료하면 여기로 돌아와서 스크립트가 종료됨
  exit 0
fi

echo "============================================="
echo "[화면: $STY] Privasea Node Setup 시작"
echo "============================================="
echo ""

################################################
# 1. Docker 설치 확인
################################################
if ! command -v docker &> /dev/null
then
  echo "Docker가 설치되어 있지 않습니다. 설치 진행..."
  sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update
  sudo apt-get install -y docker-ce
  sudo systemctl start docker
  sudo systemctl enable docker
else
  echo "Docker가 이미 설치되어 있습니다. 건너뜁니다."
fi

echo ""
echo "Docker 버전:"
docker --version
echo ""

################################################
# 2. Privasea 이미지 Pull 여부
################################################
IMAGE_NAME="privasea/acceleration-node-beta:latest"
if ! docker images | grep -q "privasea/acceleration-node-beta"
then
  echo "이미지 [$IMAGE_NAME]이 없으므로 Pull 진행..."
  docker pull "$IMAGE_NAME"
else
  echo "이미지 [$IMAGE_NAME]이 이미 존재합니다. 건너뜁니다."
fi

################################################
# 3. /privasea/config 디렉토리 준비
################################################
if [ ! -d "/privasea/config" ]; then
  echo "/privasea/config 디렉토리가 없어서 생성합니다."
  sudo mkdir -p /privasea/config
  sudo chmod 700 /privasea/config
else
  echo "/privasea/config 디렉토리가 이미 존재합니다."
fi

################################################
# 4. Keystore 존재 확인 후 생성
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
# 5. 노드 실행 확인
################################################
RUNNING_CONTAINER=$(docker ps -q --filter "ancestor=$IMAGE_NAME")
if [ -n "$RUNNING_CONTAINER" ]; then
  echo "이미 [$IMAGE_NAME] 컨테이너가 실행 중입니다."
  echo "컨테이너 ID: $RUNNING_CONTAINER"
else
  echo ""
  echo "노드를 백그라운드에서 실행합니다."
  # 사용자에게 비밀번호를 물어보고, 환경 변수로 전달하는 방식
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
echo " Privasea Node 설정이 완료되었습니다. "
echo "============================================="
echo "컨테이너 로그:"
echo "  docker logs -f $RUNNING_CONTAINER"
echo ""
echo "노드를 종료하려면:"
echo "  docker stop $RUNNING_CONTAINER"
echo ""
echo "이 screen 세션은 스크립트가 끝나도 종료되지 않습니다."
echo "필요한 작업을 더 해본 뒤 Ctrl + A + D 로 빠져나가세요."
echo ""

# 스크립트 종료 후에도 screen이 죽지 않도록
exec bash
