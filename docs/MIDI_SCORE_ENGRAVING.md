# Quy tắc dựng sheet music từ MIDI

Tài liệu này là đặc tả cho `ScoreEngravingService`. Mục tiêu là tạo bản nhạc
đọc được theo quy tắc khắc nhạc phổ thông, không đặt nốt trực tiếp lên canvas
theo một công thức riêng cho từng bài.

## Cấu trúc của một bản nhạc piano

- **Score**: toàn bộ tác phẩm, gồm tiêu đề, tác giả và tempo.
- **System**: một dòng nhạc. Mỗi system piano chứa hai khuông nối bằng brace.
- **Staff**: khuông năm dòng. Tay phải mặc định dùng khóa Sol, tay trái dùng
  khóa Fa.
- **Measure/bar**: ô nhịp, được giới hạn bởi barline. Độ dài phụ thuộc time
  signature, ví dụ 4/4 = 4 quarter beats, 6/8 = 3 quarter beats.
- **Voice**: một dòng tiết tấu độc lập trên cùng khuông. Mỗi voice phải đầy đủ
  tổng trường độ nốt và rest trong từng ô nhịp.
- **Chord**: nhiều cao độ cùng onset trong một voice. Những nốt cách nhau một
  bậc phải dịch notehead để không chồng lên nhau.

## Thành phần ký âm bắt buộc

- Clef, key signature, time signature và barline.
- Notehead rỗng/đặc, stem, flag và dot theo trường độ.
- Beam theo nhóm phách của meter; beam không đi qua barline.
- Rest cho khoảng trống của từng staff/voice; ô hoàn toàn trống dùng measure
  rest.
- Accidental có trạng thái trong từng ô nhịp: dấu chỉ hiện khi cao độ khác key
  signature hoặc khác accidental gần nhất của cùng tên nốt và quãng tám.
- Ledger line cho nốt nằm ngoài khuông.
- Tie khi một âm kéo qua barline. Tie nối cùng cao độ; slur là dấu diễn cảm và
  không được tự suy ra từ tie.
- Tuplet number cho các giá trị triplet được nhận diện.
- Measure number ở đầu system, tempo ở system đầu, lyric dưới khuông và chord
  symbol phía trên khi dữ liệu có sẵn.

## Thuật toán layout

1. Đọc tempo, meter map, key và note events từ tất cả MIDI tracks.
2. Quantize onset/duration theo lưới ký âm của từng measure.
3. Tách piano thành staff và voice, không đưa General MIDI percussion channel
   lên grand staff.
4. Tạo measure; tách nốt đi qua barline thành các fragment có tie.
5. Lấp khoảng trống của từng voice bằng rest.
6. Tính accidental theo trạng thái của từng measure và tạo beam group theo
   meter.
7. Tính minimum width của measure từ rhythmic slices, accidental columns,
   notehead collisions, lyric và chord text.
8. Đưa lần lượt measure vào system cho đến khi measure kế tiếp không còn đủ
   chỗ. Sau đó justify khoảng cách trong system. Trường độ dùng spacing ratio
   1.5: nốt dài có nhiều khoảng trống hơn nhưng không tỷ lệ tuyến tính hoàn
   toàn.
9. Auto-place các thành phần theo lớp: staff/barline, rest, ledger/accidental,
   notehead/stem, beam/tie, text và playhead.

## Những gì MIDI không lưu

MIDI lưu pitch, onset, note-off, velocity, channel và một số controller/meta
event. MIDI thông thường không lưu chắc chắn các thông tin sau:

- cách viết enharmonic gốc (C-sharp hay D-flat);
- slur, phrase, fingering, articulation và ornament;
- lyric, chord symbol và rehearsal mark;
- dynamic đã được người soạn chủ ý, crescendo/hairpin;
- clef change, cross-staff notation và cách chia voice của bản gốc;
- tie của bản gốc (chỉ có thời gian giữ âm);
- system/page break do người khắc nhạc chọn.

Engine chỉ suy luận phần có căn cứ từ dữ liệu MIDI. Nó không tự bịa các dấu
diễn cảm không có trong file. Vì vậy một file MIDI có thể được dựng thành bản
nhạc chuẩn và dễ đọc, nhưng không thể bảo đảm giống từng chi tiết với bản in
gốc nếu bản gốc không được cung cấp dưới dạng MusicXML hoặc một định dạng score.
