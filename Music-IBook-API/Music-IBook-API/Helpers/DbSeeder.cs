using BCrypt.Net;
using Music_IBook_API.Models;

namespace Music_IBook_API.Helpers;

public static class DbSeeder
{
    public static async Task SeedAsync(MusicIBookDbContext db)
    {
        Console.WriteLine("🌱 Seeding database...");

        // --- 1. Tạo tài khoản ---
        AppUser? teacher = db.Users.FirstOrDefault(u => u.Email == "teacher@musicibook.com");
        if (teacher == null)
        {
            teacher = new AppUser
            {
                FullName = "Giáo viên Demo",
                Email = "teacher@musicibook.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
                Role = "Teacher"
            };
            var student = new AppUser
            {
                FullName = "Học sinh Demo",
                Email = "student@musicibook.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
                Role = "Student"
            };
            db.Users.AddRange(teacher, student);
            await db.SaveChangesAsync();
        }

        // --- 2. Tạo bài học mẫu 1: Luyện ngón ---
        if (!db.Lessons.Any(l => l.Title == "Bài tập luyện ngón số 1"))
        {
            var lesson1 = new MusicLesson
            {
                TeacherId = teacher.Id,
                Title = "Bài tập luyện ngón số 1",
                Composer = "Nhạc sĩ Demo",
                Clef = "treble",
                KeySignature = "C Major",
                TimeSignature = "4/4",
                IsPublished = true,
                AudioUrl = null
            };
            db.Lessons.Add(lesson1);
            await db.SaveChangesAsync();

            var noteData1 = new[]
            {
                (second: 1.5,  note: "C4", duration: "quarter", lyric: "Đồ",  chord: "C"),
                (second: 3.0,  note: "D4", duration: "quarter", lyric: "Rê",  chord: ""),
                (second: 4.5,  note: "E4", duration: "quarter", lyric: "Mi",  chord: ""),
                (second: 6.0,  note: "F4", duration: "quarter", lyric: "Pha", chord: "F"),
                (second: 7.5,  note: "G4", duration: "quarter", lyric: "Son", chord: "G"),
                (second: 9.0,  note: "A4", duration: "quarter", lyric: "La",  chord: ""),
                (second: 10.5, note: "B4", duration: "quarter", lyric: "Si",  chord: ""),
                (second: 12.0, note: "C5", duration: "half",    lyric: "Đô",  chord: "C"),
            };

            db.LessonNotes.AddRange(noteData1.Select(n => new LessonNote
            {
                LessonId = lesson1.Id, Second = n.second, Note = n.note, Duration = n.duration, Lyric = n.lyric, Chord = n.chord
            }));
            await db.SaveChangesAsync();
        }

        // --- 3. Tạo bài học mẫu 2: Twinkle Twinkle Little Star ---
        if (!db.Lessons.Any(l => l.Title == "Twinkle Twinkle Little Star"))
        {
            var lesson2 = new MusicLesson
            {
                TeacherId = teacher.Id,
                Title = "Twinkle Twinkle Little Star",
                Composer = "Jane Taylor",
                Clef = "treble",
                KeySignature = "C Major",
                TimeSignature = "4/4",
                IsPublished = true,
                AudioUrl = null
            };
            db.Lessons.Add(lesson2);
            await db.SaveChangesAsync();

            var noteData2 = new[]
            {
                (second: 1.0, note: "C4", duration: "quarter", lyric: "Twin", chord: "C"),
                (second: 2.0, note: "C4", duration: "quarter", lyric: "kle", chord: ""),
                (second: 3.0, note: "G4", duration: "quarter", lyric: "twin", chord: "G"),
                (second: 4.0, note: "G4", duration: "quarter", lyric: "kle", chord: ""),
                (second: 5.0, note: "A4", duration: "quarter", lyric: "lit", chord: "F"),
                (second: 6.0, note: "A4", duration: "quarter", lyric: "tle", chord: ""),
                (second: 7.0, note: "G4", duration: "half",    lyric: "star", chord: "C"),
                (second: 9.0, note: "F4", duration: "quarter", lyric: "How", chord: "F"),
                (second: 10.0, note: "F4", duration: "quarter", lyric: "I", chord: ""),
                (second: 11.0, note: "E4", duration: "quarter", lyric: "won", chord: "C"),
                (second: 12.0, note: "E4", duration: "quarter", lyric: "der", chord: ""),
                (second: 13.0, note: "D4", duration: "quarter", lyric: "what", chord: "G"),
                (second: 14.0, note: "D4", duration: "quarter", lyric: "you", chord: ""),
                (second: 15.0, note: "C4", duration: "half",    lyric: "are", chord: "C"),
            };

            db.LessonNotes.AddRange(noteData2.Select(n => new LessonNote
            {
                LessonId = lesson2.Id, Second = n.second, Note = n.note, Duration = n.duration, Lyric = n.lyric, Chord = n.chord
            }));
            await db.SaveChangesAsync();
        }

        // --- 4. Tạo bài học mẫu 3: Ode to Joy ---
        if (!db.Lessons.Any(l => l.Title == "Ode to Joy (Beethoven)"))
        {
            var lesson3 = new MusicLesson
            {
                TeacherId = teacher.Id,
                Title = "Ode to Joy (Beethoven)",
                Composer = "Ludwig van Beethoven",
                Clef = "treble",
                KeySignature = "C Major",
                TimeSignature = "4/4",
                IsPublished = true,
                AudioUrl = null
            };
            db.Lessons.Add(lesson3);
            await db.SaveChangesAsync();

            var noteData3 = new[]
            {
                (second: 1.0, note: "E4", duration: "quarter", lyric: "Ode", chord: "C"),
                (second: 2.0, note: "E4", duration: "quarter", lyric: "to", chord: ""),
                (second: 3.0, note: "F4", duration: "quarter", lyric: "joy", chord: ""),
                (second: 4.0, note: "G4", duration: "quarter", lyric: "is", chord: ""),
                (second: 5.0, note: "G4", duration: "quarter", lyric: "here", chord: "G"),
                (second: 6.0, note: "F4", duration: "quarter", lyric: "to", chord: ""),
                (second: 7.0, note: "E4", duration: "quarter", lyric: "stay", chord: ""),
                (second: 8.0, note: "D4", duration: "quarter", lyric: "and", chord: ""),
                (second: 9.0, note: "C4", duration: "quarter", lyric: "bri", chord: "C"),
                (second: 10.0, note: "C4", duration: "quarter", lyric: "ght", chord: ""),
                (second: 11.0, note: "D4", duration: "quarter", lyric: "our", chord: ""),
                (second: 12.0, note: "E4", duration: "quarter", lyric: "hearts", chord: ""),
                (second: 13.0, note: "E4", duration: "quarter", lyric: "to", chord: "G"),
                (second: 14.0, note: "D4", duration: "eighth", lyric: "day", chord: ""),
                (second: 15.0, note: "D4", duration: "half",   lyric: "", chord: ""),
            };

            db.LessonNotes.AddRange(noteData3.Select(n => new LessonNote
            {
                LessonId = lesson3.Id, Second = n.second, Note = n.note, Duration = n.duration, Lyric = n.lyric, Chord = n.chord
            }));
            await db.SaveChangesAsync();
        }

        Console.WriteLine($"✅ Seed xong! Teacher: teacher@musicibook.com | Student: student@musicibook.com | Mật khẩu: 123456");
    }
}
