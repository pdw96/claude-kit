<!-- 무는 그레이더: real-nc-found -->
<!-- 같은 checkout.py 이지만 딴 문제로 NC 를 붙이고 진짜 결함을 놓친 기록. 파일 이름만 보면 통과한다. -->

## 부적합 목록

### NC-1 · checkout.py 의 상태 문자열이 박혀 있다
- 위치: `app/checkout.py:9`
- 증상: `"pending"` · `"paid"` 가 열거형이 아니라 문자열이다.
- 심각도: 낮음

## 안 본 것
- 없음
