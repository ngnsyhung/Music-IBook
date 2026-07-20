using Microsoft.EntityFrameworkCore;
using System.Reflection.Emit;

namespace Music_IBook_API.Models
{
    public class MusicIBookDbContext : DbContext
    {
        public MusicIBookDbContext(DbContextOptions<MusicIBookDbContext> options)
            : base(options) { }

        public DbSet<AppUser> Users => Set<AppUser>();
        public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();
        public DbSet<MusicLesson> Lessons => Set<MusicLesson>();
        public DbSet<LessonNote> LessonNotes => Set<LessonNote>();
        public DbSet<StudentLessonProgress> StudentLessonProgresses => Set<StudentLessonProgress>();
        public DbSet<PracticeSession> PracticeSessions => Set<PracticeSession>();
        public DbSet<StudentNoteAttempt> StudentNoteAttempts => Set<StudentNoteAttempt>();
        public DbSet<LessonSection> LessonSections => Set<LessonSection>();
        public DbSet<LessonAnnotation> LessonAnnotations => Set<LessonAnnotation>();
        public DbSet<LessonExercise> LessonExercises => Set<LessonExercise>();
        public DbSet<StudentAssignment> StudentAssignments => Set<StudentAssignment>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<AppUser>()
                .HasIndex(x => x.Email)
                .IsUnique();

            modelBuilder.Entity<AppUser>()
                .HasMany(x => x.LessonsCreated)
                .WithOne(x => x.Teacher)
                .HasForeignKey(x => x.TeacherId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<MusicLesson>()
                .HasMany(x => x.Notes)
                .WithOne(x => x.Lesson)
                .HasForeignKey(x => x.LessonId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<MusicLesson>()
                .HasMany(x => x.Sections)
                .WithOne(x => x.Lesson)
                .HasForeignKey(x => x.LessonId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<MusicLesson>()
                .HasMany(x => x.Annotations)
                .WithOne(x => x.Lesson)
                .HasForeignKey(x => x.LessonId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<MusicLesson>()
                .HasMany(x => x.Exercises)
                .WithOne(x => x.Lesson)
                .HasForeignKey(x => x.LessonId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<LessonSection>()
                .HasIndex(x => new { x.LessonId, x.SortOrder })
                .IsUnique();

            modelBuilder.Entity<LessonAnnotation>()
                .HasIndex(x => new { x.LessonId, x.StartBeat });

            modelBuilder.Entity<LessonExercise>()
                .HasIndex(x => new { x.LessonId, x.SortOrder });

            modelBuilder.Entity<LessonExercise>()
                .HasOne(x => x.Section)
                .WithMany(x => x.Exercises)
                .HasForeignKey(x => x.LessonSectionId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<StudentAssignment>()
                .HasIndex(x => new { x.StudentId, x.CreatedAtUtc });

            modelBuilder.Entity<StudentAssignment>()
                .HasOne(x => x.Student)
                .WithMany()
                .HasForeignKey(x => x.StudentId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<StudentAssignment>()
                .HasOne(x => x.Lesson)
                .WithMany()
                .HasForeignKey(x => x.LessonId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<StudentAssignment>()
                .HasOne(x => x.Section)
                .WithMany()
                .HasForeignKey(x => x.LessonSectionId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<StudentAssignment>()
                .HasOne(x => x.Exercise)
                .WithMany()
                .HasForeignKey(x => x.LessonExerciseId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<StudentLessonProgress>()
                .HasIndex(x => new { x.StudentId, x.LessonId })
                .IsUnique();

            modelBuilder.Entity<StudentLessonProgress>()
                .HasOne(x => x.Student)
                .WithMany(x => x.Progresses)
                .HasForeignKey(x => x.StudentId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<StudentNoteAttempt>()
                .HasOne(x => x.PracticeSession)
                .WithMany(x => x.NoteAttempts)
                .HasForeignKey(x => x.PracticeSessionId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<StudentNoteAttempt>()
                .HasOne(x => x.LessonNote)
                .WithMany(x => x.StudentNoteAttempts)
                .HasForeignKey(x => x.LessonNoteId)
                .OnDelete(DeleteBehavior.Restrict);

            // These queries drive the teacher progress charts and error analysis.
            modelBuilder.Entity<PracticeSession>()
                .HasIndex(x => new { x.StudentId, x.LessonId, x.StartedAtUtc });

            modelBuilder.Entity<StudentNoteAttempt>()
                .HasIndex(x => new { x.PracticeSessionId, x.IsCorrect });
        }
    }
}
