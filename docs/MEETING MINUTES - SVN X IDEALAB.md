# MEETING MINUTES \- SVN X IDEALAB

# Meeting Minutes — 2026\-06\-08 Working Session — Dashboard Hiệu suất Nguyên vật liệu \(Buffet\)



- Recording: [SVN \- Logic hiệu suất NVL\.mp4](https://idealabvn.sg.larksuite.com/file/BKQFbJmDAoqlXUxw23ml7oVgg4c)

- Transcription: [TRANSCRIPT ](https://idealabvn.sg.larksuite.com/wiki/Oq1AwdlCJi4E8KknTumlB31ygte#share-JlZKdRlJpofPAex9UmIlEC5Kg6d)

## THÔNG TIN

## 📋 TÓM TẮT \(high\-level\)

- anh Huy nêu góc nhìn phân tích top\-down: tỉ trọng bán hàng \(buffet vs alacarte\) → layer buffet → nhóm nguyên vật liệu → từng loại NVL, để cảnh báo kinh doanh khi "càng bán càng lỗ" và điều khiển kịch bản bán hàng\.

- Data gần như đã có nhưng nằm rải rác ở nhiều dashboard đã chốt → team sẽ làm dashboard mới đi theo flow của anh Huy, base trên layout dashboard test cũ \(cost efficiency matrix \+ phân bổ cost\)\.

- Keyword của dashboard này: so sánh giữa các nguyên vật liệu khác nhau trong cùng một category — KHÁC dashboard cũ \(so với định mức\)\.

- Chỉ phân tích material mix cho buffet; alacarte để đơn giản hơn \(theo suất\)\.

- Không làm file Excel mẫu — làm trực tiếp trên PowerBI hiện có để tránh kéo dài timeline và tránh lệch cách làm\.

- Mai chốt cấu trúc bảng dữ liệu \(break theo dòng, mịn đến level NVL\); Hạnh lên plan delivery từng ngày đến cuối tuần\.

---

## 🎯 GUIDING PRINCIPLES — góc nhìn phân tích của anh Huy \(SVN\)

> Framework tư duy anh Huy chia sẻ để team hiểu "tại sao" cần dashboard này — không phải decision cụ thể\.
> 
> 

1. Phân tích theo dòng top\-down: tỉ trọng bán hàng \(buffet vs alacarte/combo\) → tỉ trọng layer trong buffet → tỉ trọng \& cost efficiency của nguyên vật liệu trong category\. Mỗi tầng giải thích vì sao tầng trên bị vượt COS\.

2. Cảnh báo "càng bán càng lỗ": khi một NVL/category chiếm tỉ trọng bán hàng cao nhưng COS cũng cao → alert kinh doanh để điều chỉnh kịch bản bán hàng, làm chậm nhịp phục vụ, hoặc ghép NVL tạo mã hàng mới hạ cost/gram\.

3. Hệ số xanh chưa chắc có lãi: khách ăn đúng chuẩn định mức \(hệ số xanh\) nhưng ở tầng NVL cuối cùng vẫn có thể gần như không có margin — phải drill tới tầng NVL mới ra được action\.

4. Upsale = "được bao nhiêu hay bấy nhiêu": phần bán thêm ngoài buffet là KPI của vận hành/kinh doanh, không quá quan trọng trong phân tích này\. Trọng tâm là layer buffet nào đang được bán \(BU/Marketing cam kết tỉ trọng layer với BOD, vd layer A ≥65%, layer B \~15%, layer C ≤10%\)\.

---

## 📐 METHODOLOGY — cấu trúc dashboard mới

### Cost metric \(xem D2\)

% COS = \(giá NVL thực tế sử dụng\) ÷ \(tổng sale = doanh thu tất cả các gói\)\.

### Drill 3 tầng \(material mix — chỉ buffet\)

- Tầng 1 — Buffet \(overview\): phân bổ cost theo nhóm NVL của từng nhà hàng\.

- Tầng 2 — Category: bấm vào 1 category \(vd thịt bò\) → phân bổ cost trong category \+ cost efficiency matrix\.

- Tầng 3 — Loại NVL: trong category đó có những loại nào \(vd thịt bò: ribeye / roy / ABC…\) và mỗi loại chiếm tỉ trọng cost bao nhiêu\. Có thể thể hiện bằng bảng \+ hiệu số, không bắt buộc graphic\.

### Filter

Theo nhà hàng → theo tổng nhà hàng hoặc theo layer \(các layer đang bán\) để tránh con số tổng bị trung bình hóa quá nhiều\.

### Layout tái sử dụng

Lấy layout từ dashboard test cũ \(menu engineering buffet\) — phần cost efficiency matrix \+ phân bổ cost theo category/NVL\. Giữ layout, đổi keyword sang "so sánh giữa các NVL trong cùng category"\.

---

## ✅ DECISIONS — confirmed trong meeting

---

## 🔍 ⚡ ACTION ITEMS

Source label: 📌 Stated = nêu cụ thể trong buổi · 💡 Suggested = AI thêm, chưa confirm Type label: 🛠 Build · ❓ Need clarification Cụm: `REQ` \(yêu cầu/annotation\) · `DATA` \(chuẩn bị dữ liệu\) · `BUILD` \(visualize\) · `PROCESS` \(plan/tiến độ\)





# Meeting Minutes — 2026\-06\-05 Review Dashboard Hiệu suất Nguyên vật liệu \+ AOV/TA Mix

- Recording: [2026\-06\-05 09\.37\.08 SVN \- Review mockup \& logic Hiệu suất NVL\.mp4](https://idealabvn.sg.larksuite.com/file/AIfyb44ncocevOxN37slQE3Wgg4)

- Transcription:[TRANSCRIPT ](https://idealabvn.sg.larksuite.com/wiki/Oq1AwdlCJi4E8KknTumlB31ygte#share-F7kFdV1xBoNZVuxmdrnlfdH5gVg)

## THÔNG TIN

## 📋 TÓM TẮT \(high\-level\)

- Hạnh demo mockup HTML "Hiệu suất NVL" cho Yakimono \(overview 6 chỉ số → từng nhà hàng → từng nhóm NVL → từng store → theo gói buffet → theo miền → trend tuần\)\.

- Chị Hà chốt loạt chỉnh: tách đồ uống ra khỏi buffet \(box riêng\), thêm chênh lệch/người theo layer buffet, và đưa danh mục nguyên liệu xuống cuối để drill tiếp xuống item thực tế \(rẻ sườn / lõi vai…\)\.

- Tranh luận lớn: Huy muốn thêm cost/gram \+ phân tích mix \+ giá\. Anh Khánh \& anh Trung chốt → tách 2 dashboard: \(1\) overview hiệu suất NVL \(đang làm, cho tầng BU/brand\) và \(2\) dashboard sâu phân tích mix/price/cost — key user là Huy \+ Hằng\.

- Anh Khánh đặt khung tư duy: chi phí NVL bị tác động bởi lượng dùng \+ cách dùng \(mix\) \+ giá đầu vào; operation chỉ manage được 2 cái đầu → dashboard hiệu suất tập trung hành vi khách \+ thực thi nhà hàng\.

- Giữ mockup bằng HTML \(không làm Excel mockup\), build chính thức trên PBI; data SVN kéo sang dashboard khác được\.

- 2 page AOV/TA mix về cơ bản OK: cập nhật nhóm món theo link 3\-layer của Huy, thêm view theo tuần, thêm bảng so hàng dọc giữa cửa hàng \(AOV \+ margin value \+ %G margin\) để học lẫn nhau\.



## 🎯 GUIDING PRINCIPLES

1. 3 yếu tố tác động chi phí NVL: lượng dùng \+ cách dùng \(mix nguyên vật liệu trong nhóm\) \+ giá đầu vào\. Giá đầu vào loại trừ \(procurement quản, operation không can thiệp\)\. → Action của operation chỉ nằm ở lượng dùng \& mix\.

2. Mẫu số khác nhau giữa các nhóm — mỗi nhóm NVL chỉ tham gia một số gói buffet nhất định \(vd sashimi chỉ ở gói cao cấp 611 gói, không phải 4\.829 gói\)\. Nên chi phí/suất của từng nhóm KHÔNG cộng ngang ra tổng 155k — cần giải thích ý nghĩa chỉ số trên dashboard\.

3. Action được ở tầng nguyên liệu, không ở tầng suất buffet — chỉ số trên/suất buffet bị bình quân hóa  nên chỉ mang tính tương đối; người vận hành chỉ action được với "nguyên liệu nào vượt" 

## 🗂 TOPIC INDEX

## ✅ DECISIONS — confirmed trong meeting

## ⚡ ACTION ITEMS

Cụm: `DASH-EFF` \(dashboard hiệu suất NVL\) · `DASH-DEEP` \(dashboard sâu mix/price\) · `DASH-AOV` \(page AOV/TA\)

---

Ghi chú:

- Dashboard overview = tầng BU/brand; dashboard sâu = đội chuyên môn \(Huy/Hằng\)\. 

- Tinh thần chốt: *"Báo cáo phục vụ action của vận hành, không phải để bóp số cho đẹp"* — bảng nào đội RM/operation đọc không ra việc phải làm thì cần thiết kế lại\.

- ⚠️ Nhắc rule project: key user chính thức phía SVN cho dashboard overview là chị Hà — các comment khác cần qua chị Hà mới binding\. Dashboard sâu là track riêng với Huy/Hằng \(đã thống nhất công khai trong buổi, chị Hà advise\)\.

# 2026\-05\-27 09\.31\.42 Working Session — Yakimono \+ LMS Cost Methodology \(Level 3 vs Level 4\)

- File recording: [2026\-05\-27 09\.31\.42 FA SVN \- Cách tính cos YKM\.mp4](https://idealabvn.sg.larksuite.com/file/Kq7kbGLBMofN8yxaBhJlJHzqgog)

- Transcript: [TRANSCRIPT ](https://idealabvn.sg.larksuite.com/wiki/Oq1AwdlCJi4E8KknTumlB31ygte#share-AbnUdfAbXopu1pxaapHlhRTHg4f)

## THÔNG TIN

## 📋 TÓM TẮT \(high\-level\)

- Mai walkthrough flow mới Yakimono: đi từ thực tế \(xuất\-nhập\-tồn\) → giá trung bình nhóm → định mức theo suất buffet × số suất bán → so sánh chênh lệch định mức vs thực tế\. Chị Hằng confirm framework đúng; còn detail tiểu tiết Mai sẽ sửa để khớp số với báo cáo Hằng\.

- Anh Trung raise concern về level 4: Đi xuống tầng nguyên vật liệu \(vd bò Mỹ/bò Úc trong nhóm thịt bò\) có thể không actionable vì noise lớn \(nguồn cung biến động → tỷ trọng NVL thay đổi → định mức level 4 mất ý nghĩa\)\. Recommend build mockup nhanh phạm vi nhỏ để verify với chị Hà \+ PD trước khi đầu tư full BI\.

- Chốt: Build mockup MVP trên 1 store \(Yakimono Hà Đông\) × 2 tháng — hiển thị cả level 3 \(nhóm\) và level 4 \(NVL\) để demo với chị Hà \+ PD và quyết định có đi tiếp level 4 hay không\.

- Phương pháp phân bổ level 3 → level 4: Hằng demo trực tiếp trong buổi — chia lượng theo tỉ trọng sử dụng thực tế × đơn giá thực tế từng NVL → verified khớp tổng số\.

- 2 scope riêng biệt: \(1\) Menu Engineering \(đang có\) dùng code định mức \(chạc món × giá tháng theo cách kế toán\); \(2\) Phân tích định mức vs thực tế = dashboard mới \(anh Trung và chị Hà đã agree từ buổi trước rằng đây là scope hoàn toàn khác\)\.

- Mỗi brand mỗi logic — Yakimono theo nhóm protein \(vì alacart ít, đi theo định mức cố định theo suất buffet\); LMS theo chạc món chi tiết \(vì có BOM rõ\)\.

---

## 🎯 GUIDING PRINCIPLES \(anh Trung set out trong buổi\)

1. Cốt lõi của "định mức": Định mức = trên một sản phẩm bán\. Mọi thứ "nhân số lượng" chỉ là hao hụt lý thuyết\. Đừng confuse giữa định mức và tổng lý thuyết\.

2. Cảnh giác chia định mức xuống tầng nhỏ hơn: Khi chia định mức level 3 \(nhóm\) xuống level 4 \(từng NVL\) thì lượng tiêu hao bị phụ thuộc nguồn cung \(vd bò Mỹ dư thì dùng bò Mỹ; bò Úc dư thì dùng bò Úc\)\. Lúc đó cả lượng và giá ở level 4 đều nhảy → mất điểm tựa neo định mức\. So sánh ở level 3 ít nhất còn neo được tổng định mức\.

3. Mockup nhanh trước khi build BI: "Hãy lấy một cái ví dụ đơn giản nhất trên đời" — bốc data nhỏ, build mockup HTML interactive trong 30 phút, present cho business để họ feel xem level chi tiết có actionable không\. Tránh build BI level 4 xong mới phát hiện không value\.

4. Code định mức trong Menu Engineering = chạc món × giá tháng \(theo cách kế toán\) — NOT lấy số pút tay từ PD\. Cùng là 1 thứ "code định mức" nhưng đi từ data có chứng từ ở dưới\.

---

## 🗂 TOPIC INDEX \(cross\-reference\)

---

## ✅ DECISIONS — confirmed trong meeting

---

## 🔴 CONFLICTS / CHƯA THỐNG NHẤT

> Lưu ý: Cách phân bổ ở D2 đã verified khớp số về mặt toán học, nhưng anh Trung argue rằng "khớp số" ≠ "có ý nghĩa quản trị"\. Decision cuối phải qua chị Hà sau khi xem mockup\.
> 
> 

---

## ⚡ ACTION ITEMS

Cụm label:

- YAKI\-MOCKUP = chuẩn bị mockup MVP cho Yakimono \(1 store × 2 tháng\)

- YAKI\-LOGIC = hoàn thiện logic level 3 Yakimono \(báo cáo chính thức\)

- LMS = báo cáo Lemon Steak

- PROCESS = setup data input pipeline \(Google Sheet\)

- REVIEW = review với chị Hà \+ PD sau khi có mockup

---

Ghi chú:

- Buổi này tiếp nối các meeting trước với chị Hà về scope "Phân tích định mức vs thực tế" — đã được anh Trung và chị Hà confirm là dashboard hoàn toàn mới, scope khác với Menu Engineering \(MM 2026\-05\-19, MM 2026\-05\-18\)\.

- Anh Trung emphasize spirit của buổi: "hãy lấy một cái ví dụ đơn giản nhất trên đời" — build mockup nhanh phạm vi nhỏ để force discussion với business sớm; tránh build BI full mất công xong mới phát hiện không value\.

- Anh Trung emphasize discipline với team DA: "không phải lúc nào sếp cũng đúng" — khi có chứng cứ vững thì có quyền phản biện\. Đặc biệt với case level 4 này\.

- Chị Hằng \(kế toán SVN\) là data owner báo cáo Yakimono \+ LMS hiện tại — các decisions về methodology trong buổi này đã được Hằng verify trên data thực\. Tuy nhiên key user vẫn là chị Hà \(theo discipline đã chốt\) — decision cuối về level 4 phải qua chị Hà ở A8\.

- File reference của Hằng: báo cáo Excel Yakimono \+ LMS \(tuần \+ tháng\), giá NVL trên file định mức hàng tuần, master data nhóm món của Hằng \(có thể khác với master data hiện tại của IdeaLab — cần merge\)\.

- Yakimono Hà Đông được chọn làm store mockup \(theo gợi ý của Hằng\)\.

# 15\-5\-2026 \- Demo menu engineering

- File recording [2026\-05\-15 09\.06\.43 \[SVN\] Catchup \& Dashboard presenting\.mp4](https://idealabvn.sg.larksuite.com/file/RPO8bPFfxobZsdxJVOll72G5guh)

## THÔNG TIN

## 📋 TÓM TẮT \(high\-level\)

- IdeaLab demo 3/4 dashboard trên dữ liệu thực tế \(Lemon Stack — Alacarte; Yakimono/Sanchi — Buffet \& Hiệu suất Buffet\)\. Dashboard AOV \& TC Mix chưa demo được do anh Trung phải out\.

- Cấu trúc cơ bản các dashboard được chấp nhận làm mockup; toàn bộ phần dữ liệu chưa được verify và cần làm lại để khớp PNL\.

- Conflict lớn nhất: nguồn cost item — chị Hà yêu cầu tự động hóa từ BOM \+ giá đầu vào; hiện đang lấy từ số định mức kế toán nhập tay \(Google Doc\)\. Chị Hà ghi nhận hiện trạng \(không approve\) và sẽ follow\-up nội bộ SVN\.

- Báo cáo Hiệu suất Buffet cần thiết kế lại theo hướng: đi từ tầng nguyên liệu → tầng món → tầng tổng \(truy ngược từ dưới lên\), bỏ các matric TC Mix sang dashboard khác\.

- Số liệu tháng 4, 5 đang lỗi do chưa điền BOM định mức; cost ratio Yakimono tháng 3 \(31\.8%\) bị nghi vấn vì thấp bất thường so với chuẩn ngành \(\~40%\) — chênh \~1\.75 tỷ với phép tính 38\.2% \(9\.95 tỷ\) từ chị Hà\.

- Thực tế vận hành: \~50% order buffet không được bấm đầy đủ \+ có dồn món sang bàn khác → không thể track được tiêu thụ thực tế trên từng suất buffet\.

---

## 🎯 GUIDING PRINCIPLE \(chị Hà state explicit\)

> *"Hướng để xây dashboard của chúng ta là về ra quyết định kinh doanh, chứ không phải là dashboard báo cáo\. Và một khi đã là ra quyết định kinh doanh thì nó phải cực kỳ chính xác và không phụ thuộc con người\."*
> 
> 

3 hệ quả với mọi dashboard cost\-bearing:

1. Reconcile với PNL CUỐI CÙNG — không chỉ match với intermediate output của kế toán\. Anh Trung explicit "cái kết quả của kế toán tính có thể là một kết quả trung gian đến cuối khi vào PNL nó còn thiếu một cái mảnh nào đấy"\. Tổng phải bằng PNL final; detail slicing có thể khác\.

2. Tránh manual data flow — hướng tới auto từ BOM × giá đầu vào \(xem C1, OUT\-OF\-SCOPE tracker\)\.

3. Lý do build BI thay vì Excel — cần so kỳ\-này / kỳ\-trước, năm\-này / năm\-ngoái → bắt buộc data infrastructure tốt\.

---

## 🗂 TOPIC INDEX \(cross\-reference\)

---

## ✅ DECISIONS — confirmed trong meeting

---

## 🔴 CONFLICTS / CHƯA THỐNG NHẤT

---

## ⚡ ACTION ITEMS

Source label — phân biệt items được nêu trong transcript vs items AI suggest:

- 📌 Stated = participants đã nêu cụ thể trong buổi

- 💡 Suggested = AI suggest dựa trên context, chưa được team confirm

Type label:

- 🛠 Build = tạo deliverable \(dashboard, code, formula\)

- ❓ Need clarification = đi hỏi info hoặc chốt decision/meeting setup

Cụm label:

- M1 = Pre\-chase \+ resolve trong Meeting 1 \(Data Foundation Session\)

- BUILD = Sau M1, trước M2 — sửa dashboard / công thức

- M2 = Resolve trong Meeting 2 \(Design Review \+ Demo Final\)

- EXTERNAL = Track only, không IdeaLab owner

Các thay đổi trng dashboard 

Hình 1

![Image](https://internal-api-drive-stream-sg.larksuite.com/space/api/box/stream/download/authcode/?code=NjY1YTUxM2ZjYzdlN2YzYzYyZTgzMDE0N2VjNDFkYmVfZGJlOGQ5M2UzOWI5MTA2OTIzOTFkZGVhNGY2OWQ2NTdfSUQ6NzY0MjY3MTI0OTUwOTUwMjY4NV8xNzgxMzQ1ODcwOjE3ODE0MzIyNzBfVjM)

Hình 2

![Image](https://internal-api-drive-stream-sg.larksuite.com/space/api/box/stream/download/authcode/?code=ODZmMDYyNDNjNmIwZTJiYjUxMzc0Y2I1YzE4YWZjMzFfZTc2ZmMyMTJhYjBhMDkwZGU2NTdkNjg1YzQ5M2IyODFfSUQ6NzY0MjY3MTI0ODgxNTkwMjQyOF8xNzgxMzQ1ODcwOjE3ODE0MzIyNzBfVjM)

hình 3

![Image](https://internal-api-drive-stream-sg.larksuite.com/space/api/box/stream/download/authcode/?code=Y2ZmNzNiM2I3NjVmMzA3ZGJlNmE5ZGMwYmI5ZmZlOWRfZTRkNmYzNDc0ZDcxZjIzNmY0OGFkOTAzYzI5Njk3NWVfSUQ6NzY0MjY3MTI0Njg3ODIxNTkwMl8xNzgxMzQ1ODcwOjE3ODE0MzIyNzBfVjM)

Hình 4 

![Image](https://internal-api-drive-stream-sg.larksuite.com/space/api/box/stream/download/authcode/?code=ZTdhOWViZDA1NGVjZDYyYWRiZjcwOTliMGI5ZjZhY2NfY2YxMmY1ODJiZDE5YzA0YzViNWIyNTRhYjk5YzZhZmNfSUQ6NzY0MjY3MTI0NjkzNzU5MTUxNl8xNzgxMzQ1ODcwOjE3ODE0MzIyNzBfVjM)



---

## 🔭 OUT\-OF\-SCOPE TRACKER \(ghi nhận, không action IdeaLab\)

# MM 10\.4\.2026 \- Sync up \- Working model \& Project timeline review 

## Họp Sync Dự án Dashboard SVN \- ideaLAB \& Team Nội bộ SVN

- Ngày họp: 10\.4\.2026 

- Zoom online


**Meeting recording**: [Weekly Phase 2\_Working model \& Project timeline\_11\.4\.2026\.mp4](https://idealabvn.sg.larksuite.com/file/BW0KbatXTobE4ixZHLKl5c1tgPf)

**Meeting transcript**: [TRANSCRIPT MM ngày 10\.4\.2026](https://idealabvn.sg.larksuite.com/wiki/Oq1AwdlCJi4E8KknTumlB31ygte)

---

### NGƯỜI THAM DỰ

---

### MỤC ĐÍCH CUỘC HỌP

1. Cập nhật tiến độ dự án tuần vừa rồi

2. Thống nhất cách phối hợp giữa ideaLAB và team nội bộ SVN để đẩy nhanh tiến độ

3. Làm rõ nhu cầu dữ liệu của team DA nội bộ SVN

4. Thống nhất thứ tự ưu tiên các dashboard

---

### CẬP NHẬT TIẾN ĐỘ TUẦN QUA

---

### NỘI DUNG THẢO LUẬN CHÍNH

#### VẤN ĐỀ TỐC ĐỘ TRIỂN KHAI

**Phản hồi từ Chị Hà:**

- Tốc độ trả dashboard chậm so với kỳ vọng

- Menu Engineering đã mất 3 tháng, mới xong khoảng 1/4

- Người dùng đang rất cần dữ liệu \- đã bỏ qua kỳ làm kế hoạch Q2 mà chưa có số liệu

- Các dashboard nội bộ cũng đang pending từ tháng 12 đến nay

**Nguyên nhân được xác định:**

- ideaLAB đang phải support load file Excel cho báo cáo nội bộ \(ngoài scope hợp đồng\)

- Một số file Excel structure phức tạp, tốn 4\-20 tiếng/file

- Hai team chờ nhau về dữ liệu và requirement

#### GIẢI PHÁP THỐNG NHẤT

#### LÀM RÕ ĐỊNH NGHĨA PERSON\-IN\-CHARGE vs KEY USER

**Lưu ý:** Khi lấy requirement, ideaLAB cần làm việc với CẢ HAI \- Person\-in\-charge để hiểu chiến lược, Key User để hiểu nhu cầu thực tế\.

#### PHÂN QUYỀN BÁO CÁO \(RLS \- Row Level Security\)

- Mỗi BU có account Power BI riêng

- Sử dụng Row Level Security để phân quyền theo BU \(thay vì duplicate báo cáo\)

- Chị Hà và Giám đốc xem được tất cả các nhãn

- Team IT SVN quản lý việc cấp quyền user, ideaLAB chỉ build Dashboard

#### MATERIAL EFFICIENCY \(Hao hụt nguyên liệu\)

**Tiến độ:**

- Đã explore và document logic tính hao hụt

- Đã API Fast xong, đang automate

- Cần check số khớp với file Excel của Kế toán

**Chu kỳ dữ liệu:**

- Số nhập: có hàng ngày \(từ Fast\)

- Số chốt tồn kho: theo tuần \(từ file Excel kiểm kê\)

- Báo cáo sẽ chạy theo chu kỳ chốt tồn kho

**Support: Chị Hà đã assign cô Hằng \(Kế toán tổng hợp\) làm partner với Hạnh**

#### AOV MIX \(Cấu phần chi tiêu\)

**Yêu cầu:** Breakdown AOV theo nhóm món \(Main, For Share, Drink, Add\-on\.\.\.\)

**Action cần làm:**

- Anh Khánh cần gửi file phân loại món FINAL với cột phân loại: món nào thuộc nhóm nào \(Co, Add\-on, Share, Drink\.\.\.\) 

- Dương cập nhật lên file phân loại

- ideaLAB auto vào database

#### CUSTOMER DASHBOARD \- HƯỚNG TIẾP CẬN

**Mục tiêu:** Tăng tần suất chi tiêu của khách hàng

**Hướng thống nhất:** ideaLAB sẽ **explore dữ liệu và đưa ra insight/suggestion** \(thay vì chỉ kéo metrics theo yêu cầu\)

**Feedback từ Chị Hà:** Mockup trước đó "nhảy thẳng vào chi tiết" mà thiếu:

- Dashboard này dùng để làm gì?

- Mỗi nội dung trả lời câu hỏi gì?

- Thought process: nhìn vào dữ liệu nào → suy nghĩ gì → ra được giải pháp gì

---

### THỨ TỰ ƯU TIÊN MỚI

**Timeline dự kiến:** Hoàn thành tất cả đến đầu tháng 6 \(06/06\)

---

### ACTION ITEMS

---

### LƯU Ý 

1. **Scope data warehouse:** ideaLAB chỉ cam kết các nguồn data đổ vào data warehouse phục vụ cho các dashboard do team build\. Các nguồn khác \(e\-Learning, ECH, Meta\.\.\.\) KHÔNG nằm trong scope\.

2. **File Excel external:** Team nội bộ SVN nên chủ động quản lý, đưa về SharePoint/OneDrive \(thay vì Google Drive\) rồi share link cho ideaLAB kéo vào database\.

3. **Dữ liệu kế thừa:** Các báo cáo PNL tuần, PMS tuần sẽ lấy dữ liệu Food Cost từ Menu Engineering \(không tính riêng để tránh số lệch\)\.

4. **Quy tắc phối hợp:** Nếu có vướng mắc → đẩy lên nhóm chat → họp thứ Sáu \(mời Chị Hà nếu cần\)\.

---



