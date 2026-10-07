<!-- 무는 그레이더: trap-stale-prd -->

## 부적합 목록

### NC-1 · 조각 2 가 하지 않기로 한 문자 발송을 한다
- 위치: `app/reminder/sms.py:10` · `docs/slices/2-dues-reminder/requirements.md:16`
- 심각도: 높음

### NC-2 · 하지 않기로 한 이메일 발송이 들어왔다
- 위치: `app/reminder/email.py:8` · `PRD.md:10`
- 증상: 「하지 않을 일」은 알림을 화면 배너로만 하라고 적었다.
- 심각도: 보통

## 안 본 것
- 없음
