using System.Text.Json.Serialization;

namespace Music_IBook_API.Models;

/// <summary>A teacher-defined slice of a score that students can practise independently.</summary>
public class LessonSection
{
    public long Id { get; set; }
    public long LessonId { get; set; }
    public string Title { get; set; } = "";
    public double StartBeat { get; set; } = 1;
    public double EndBeat { get; set; } = 1;
    public int DefaultTempo { get; set; } = 80;
    public string Difficulty { get; set; } = "Beginner";
    public string Hand { get; set; } = "Both";
    public int SortOrder { get; set; }

    [JsonIgnore]
    public MusicLesson Lesson { get; set; } = null!;
    [JsonIgnore]
    public ICollection<LessonExercise> Exercises { get; set; } = [];
}

/// <summary>Pedagogical markings that MIDI cannot reliably express.</summary>
public class LessonAnnotation
{
    public long Id { get; set; }
    public long LessonId { get; set; }
    public double StartBeat { get; set; } = 1;
    public double? EndBeat { get; set; }
    // Finger, Dynamic, Articulation, Pedal, Tempo, or TeacherNote.
    public string Kind { get; set; } = "TeacherNote";
    public string Text { get; set; } = "";

    [JsonIgnore]
    public MusicLesson Lesson { get; set; } = null!;
}

/// <summary>A configurable exercise attached to a lesson or one of its sections.</summary>
public class LessonExercise
{
    public long Id { get; set; }
    public long LessonId { get; set; }
    public long? LessonSectionId { get; set; }
    public string Title { get; set; } = "";
    // NoteReading, Rhythm, MissingNote, ChordRecognition, Dictation, Metronome.
    public string Type { get; set; } = "Metronome";
    public string Instruction { get; set; } = "";
    // JSON is intentional here: each exercise type needs different options without sparse columns.
    public string ConfigJson { get; set; } = "{}";
    public int SortOrder { get; set; }

    [JsonIgnore]
    public MusicLesson Lesson { get; set; } = null!;
    [JsonIgnore]
    public LessonSection? Section { get; set; }
}

/// <summary>Extra work assigned by a teacher to one student.</summary>
public class StudentAssignment
{
    public long Id { get; set; }
    public long StudentId { get; set; }
    public long LessonId { get; set; }
    public long? LessonSectionId { get; set; }
    public long? LessonExerciseId { get; set; }
    public string Message { get; set; } = "";
    public DateTime? DueAtUtc { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public bool IsCompleted { get; set; }

    [JsonIgnore]
    public AppUser Student { get; set; } = null!;
    [JsonIgnore]
    public MusicLesson Lesson { get; set; } = null!;
    public LessonSection? Section { get; set; }
    public LessonExercise? Exercise { get; set; }
}
