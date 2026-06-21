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
        public DbSet<PracticeSessionDetail> PracticeSessionDetails => Set<PracticeSessionDetail>();
        public DbSet<StudentNoteAttempt> StudentNoteAttempts => Set<StudentNoteAttempt>();

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

            modelBuilder.Entity<PracticeSessionDetail>()
                .HasOne(x => x.PracticeSession)
                .WithMany(x => x.Details)
                .HasForeignKey(x => x.PracticeSessionId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<PracticeSessionDetail>()
                .HasOne(x => x.LessonNote)
                .WithMany()
                .HasForeignKey(x => x.LessonNoteId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
