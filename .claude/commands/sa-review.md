---
description: Review kiến trúc & chất lượng resource-planner theo checklist 8 điểm (SA mode)
argument-hint: "[full | web | db | deploy | docs | <mô tả change/PR>]"
---

Chạy **Technical Review (SA mode)** cho repo `resource-planner`.

Phạm vi cần review: **$ARGUMENTS**
(nếu trống → review `full`).

Hãy dùng **Agent tool với `subagent_type: tech-reviewer`** để thực hiện review
theo đúng 8 checkpoint và định dạng output PASS/WARN/FAIL của agent đó. Truyền
phạm vi ở trên cho agent. Đây là review **chỉ-đọc** — không sửa file, không
deploy. Sau khi nhận báo cáo, chuyển nguyên kết quả cho người dùng và nêu rõ
verdict go-live.
