namespace Music_IBook_API.DTOs
{
    public class SaveLessonContentRequest
    {
        public List<AddLessonNoteRequest> Notes { get; set; } = [];
    }
}
