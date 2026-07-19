namespace Music_IBook_API.DTOs;

public class CreateLessonRequest
{
    public string Title { get; set; } = "";
    public string Composer { get; set; } = "";
    public string Clef { get; set; } = "treble";
    public string KeySignature { get; set; } = "D Major";
    public string TimeSignature { get; set; } = "2/4";
    public string TimeSignatureMap { get; set; } = "";
    public int Tempo { get; set; } = 80;

    public string TheoryTitle { get; set; } = "";
    public string TheoryContent { get; set; } = "";
    public string PracticeGuide { get; set; } = "";
}

public class AddLessonNoteRequest
{
    public double Second { get; set; }
    public double StartBeat { get; set; } = 1;
    public double DurationBeat { get; set; } = 1;
    public int Velocity { get; set; } = 90;
    public int Staff { get; set; }
    public int Voice { get; set; }
    public string Note { get; set; } = "";
    public string Duration { get; set; } = "";
    public string Lyric { get; set; } = "";
    public string Chord { get; set; } = "";
}
