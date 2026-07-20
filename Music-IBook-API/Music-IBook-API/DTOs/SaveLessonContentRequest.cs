namespace Music_IBook_API.DTOs
{
    public class SaveLessonContentRequest
    {
        public List<AddLessonNoteRequest> Notes { get; set; } = [];
        public List<LessonSectionRequest> Sections { get; set; } = [];
        public List<LessonAnnotationRequest> Annotations { get; set; } = [];
        public List<LessonExerciseRequest> Exercises { get; set; } = [];
    }

    public class LessonSectionRequest
    {
        public string Title { get; set; } = "";
        public double StartBeat { get; set; } = 1;
        public double EndBeat { get; set; } = 1;
        public int DefaultTempo { get; set; } = 80;
        public string Difficulty { get; set; } = "Beginner";
        public string Hand { get; set; } = "Both";
        public int SortOrder { get; set; }
    }

    public class LessonAnnotationRequest
    {
        public double StartBeat { get; set; } = 1;
        public double? EndBeat { get; set; }
        public string Kind { get; set; } = "TeacherNote";
        public string Text { get; set; } = "";
    }

    public class LessonExerciseRequest
    {
        public string Title { get; set; } = "";
        public string Type { get; set; } = "Metronome";
        public string Instruction { get; set; } = "";
        public string ConfigJson { get; set; } = "{}";
        // This references a section's SortOrder so sections and exercises can be saved atomically.
        public int? SectionSortOrder { get; set; }
        public int SortOrder { get; set; }
    }
}
