## 체크 항목

| # | 항목 | 판정 | 근거 위치 |
|---|---|---|---|
| 1 | 기준 문서 | 적합 | `docs/master-plan.md:7` — 의도 문서는 `INTENT.md` |
| 6 | 하지 않을 일 | 부적합 | `docs/slices/2-dues-reminder/requirements.md:16` · `app/reminder/sms.py:10` — NC-1 |
| 7 | 성공 기준 | 적합 | `docs/slices/2-dues-reminder/requirements.md:11` |

## 부적합 목록

### NC-1 · 조각 2 가 하지 않기로 한 문자 발송을 한다
- 위치: `app/reminder/sms.py:10` · `app/reminder/run.py:10` · `docs/slices/2-dues-reminder/requirements.md:16`
- 증상: 조각 2 「회비 알림」의 「하지 않을 일」 1 은 문자(SMS) 발송을 막는데, `send_sms` 가 미납자마다 문자를 보낸다.
- 설계 ① 은 바뀌는 것을 「이메일 알림 · 미납자 CSV」로만 적었고 문자는 없다(`docs/slices/2-dues-reminder/design.md:4`).
- 어느 쪽을 고칠지는 정하지 않는다 — 문자를 빼거나, 범위를 바꾸려면 요구사항을 먼저 고친다.
- 심각도: 높음

## 관찰

### OB-1 · 착공 때의 문서가 남아 있다
- `PRD.md` 는 의도 문서가 아니다 — 마스터플랜의 의도 줄은 `INTENT.md` 를 가리킨다. 그 「하지 않을 일」로는 판정하지 않았다.

## 안 본 것
- 조각 1 의 「하지 않을 일」(내보내기)은 조각 1 의 구현에만 걸린다 — 조각 2 의 미납자 목록 파일은 조각 2 의 성공 기준이다.
- 문자 API 토큰의 보관 — `audit-secrets` 담당.
