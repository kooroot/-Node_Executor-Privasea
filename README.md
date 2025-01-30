# Privasea Node Executor Setup

아래 순서대로 진행하면 Privasea Acceleration Node를 손쉽게 구동하고, 대시보드에서 지갑을 연동해 모니터링할 수 있다.

---

## 사전 준비
- docker, screen, wget
- **Arbitrum Sepolia Faucet**: 테스트 이더(ETH)
- **Privasea Faucet**: Privasea 테스트 토큰

---

## 1. 명령어 입력
### Linux
```
wget https://raw.githubusercontent.com/kooroot/Node_Executor-Privasea/refs/heads/main/privasea.sh
chmod 755 privasea.sh
./privasea.sh
```
- 명령어 실행 시 screen으로 전환되며, Enter를 입력하면 스크립트가 실행됩니다.

### MacOS
```
wget https://raw.githubusercontent.com/kooroot/Node_Executor-Privasea/refs/heads/main/privasea_mac.sh
chmod 755 privasea_mac.sh
./privasea_mac.sh
```

---

## 2. 비밀번호 설정 및 입력
- 노드를 처음 설정할 때, **총 2회** 비밀번호 입력:
  1. `Enter password for a new key:`  
  2. `Enter password again to verify:`
- 이후 대시보드에서 컨테이너 실행 시, **환경 변수**(KEYSTORE_PASSWORD)로 비밀번호를 한 번 더 입력(총 3번의 비밀번호 입력 단계).

---

## 3. 노드 주소 확인
- 스크립트를 실행한 후, `docker logs -f [컨테이너 ID]` 명령어를 실행해 나타나는 노드의 주소를 확인한다.
- ![image](https://github.com/user-attachments/assets/fb208d44-89b2-4ca7-a6c5-613fab325c69)
- 해당 주소는 웹 대시보드에서 지갑과 연동하기위해 사용된다.

---

## 4. 웹 대시보드의 지갑과 연동
- Privasea Acceleration Node가 실행된 뒤, [**웹 대시보드**](https://deepsea-beta.privasea.ai/privanetixNode)에서 방금 만든 노드 주소와 지갑을 연결한다.
- ![image](https://github.com/user-attachments/assets/72593ab0-4675-41cd-b394-402afd384d38)
- ![image](https://github.com/user-attachments/assets/6f295e9d-e6ba-48dc-b953-ece6c7917f20)

---

## 5. 모니터링
- **Docker 로그**:  
  ```bash
  docker logs -f [컨테이너 ID]
- 다음과 같은 화면이 나타나면 노드가 잘 구동되어 있는 것 입니다.
- ![image](https://github.com/user-attachments/assets/789e7396-a8ca-48fb-b340-b5f5a48d1062)
- 웹 대시보드에서 Online을 확인해주세요.
- ![image](https://github.com/user-attachments/assets/e843babe-f998-46cb-aa65-e94f210b6ff2)


