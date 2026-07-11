USE MusicIBook;
GO

DECLARE @TeacherId BIGINT;
SELECT TOP 1 @TeacherId = Id FROM Users WHERE Role = 'Teacher';

IF @TeacherId IS NULL
BEGIN
    INSERT INTO Users (FullName, Email, PasswordHash, Role, CreatedAtUtc) 
    VALUES ('Seeded Teacher', 'teacher@seed.com', '123', 'Teacher', GETUTCDATE());
    SET @TeacherId = SCOPE_IDENTITY();
END

DECLARE @LessonId1 BIGINT;
INSERT INTO Lessons (TeacherId, Title, Composer, Clef, KeySignature, TimeSignature, TheoryTitle, TheoryContent, PracticeGuide, CreatedAtUtc, IsPublished)
VALUES (@TeacherId, 'Jingle Bells', 'James Lord Pierpont', 'treble', 'G Major', '4/4', 'Nhịp 4/4', 'Học nhịp 4/4', 'Tập tay phải trước', GETUTCDATE(), 1);
SET @LessonId1 = SCOPE_IDENTITY();

INSERT INTO LessonNotes (LessonId, Second, Note, Duration, Lyric, Chord) VALUES
(@LessonId1, 0, 'E4', 'quarter', 'Jin', 'G'),
(@LessonId1, 1, 'E4', 'quarter', 'gle', ''),
(@LessonId1, 2, 'E4', 'half', 'bells', ''),
(@LessonId1, 4, 'E4', 'quarter', 'Jin', ''),
(@LessonId1, 5, 'E4', 'quarter', 'gle', ''),
(@LessonId1, 6, 'E4', 'half', 'bells', ''),
(@LessonId1, 8, 'E4', 'quarter', 'Jin', ''),
(@LessonId1, 9, 'G4', 'quarter', 'gle', ''),
(@LessonId1, 10, 'C4', 'quarter', 'all', ''),
(@LessonId1, 11, 'D4', 'quarter', 'the', ''),
(@LessonId1, 12, 'E4', 'half', 'way', 'C');

DECLARE @LessonId2 BIGINT;
INSERT INTO Lessons (TeacherId, Title, Composer, Clef, KeySignature, TimeSignature, TheoryTitle, TheoryContent, PracticeGuide, CreatedAtUtc, IsPublished)
VALUES (@TeacherId, 'Ode to Joy', 'Beethoven', 'treble', 'G Major', '4/4', 'Nốt C4 đến G4', '', '', GETUTCDATE(), 1);
SET @LessonId2 = SCOPE_IDENTITY();

INSERT INTO LessonNotes (LessonId, Second, Note, Duration, Lyric, Chord) VALUES
(@LessonId2, 0, 'E4', 'quarter', 'Ode', 'G'),
(@LessonId2, 1, 'E4', 'quarter', 'to', ''),
(@LessonId2, 2, 'F4', 'quarter', 'joy', ''),
(@LessonId2, 3, 'G4', 'quarter', '', ''),
(@LessonId2, 4, 'G4', 'quarter', '', ''),
(@LessonId2, 5, 'F4', 'quarter', '', ''),
(@LessonId2, 6, 'E4', 'quarter', '', ''),
(@LessonId2, 7, 'D4', 'quarter', '', ''),
(@LessonId2, 8, 'C4', 'quarter', '', 'C'),
(@LessonId2, 9, 'C4', 'quarter', '', ''),
(@LessonId2, 10, 'D4', 'quarter', '', ''),
(@LessonId2, 11, 'E4', 'quarter', '', ''),
(@LessonId2, 12, 'E4', 'quarter', '', ''),
(@LessonId2, 13, 'D4', 'eighth', '', 'D'),
(@LessonId2, 13.5, 'D4', 'half', '', '');
GO
