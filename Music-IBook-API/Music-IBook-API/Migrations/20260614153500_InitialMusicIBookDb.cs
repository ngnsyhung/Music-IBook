using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Music_IBook_API.Migrations
{
    /// <inheritdoc />
    public partial class InitialMusicIBookDb : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FullName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Email = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    PasswordHash = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Role = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Lessons",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TeacherId = table.Column<long>(type: "bigint", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Composer = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Clef = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    KeySignature = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    TimeSignature = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    TheoryTitle = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    TheoryContent = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PracticeGuide = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    AudioUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    AudioFileName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsPublished = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Lessons", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Lessons_Users_TeacherId",
                        column: x => x.TeacherId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "PasswordResetTokens",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<long>(type: "bigint", nullable: false),
                    Token = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ExpiresAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsUsed = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PasswordResetTokens", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PasswordResetTokens_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LessonNotes",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    LessonId = table.Column<long>(type: "bigint", nullable: false),
                    Second = table.Column<double>(type: "float", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Duration = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Lyric = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Chord = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonNotes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LessonNotes_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PracticeSessions",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    StudentId = table.Column<long>(type: "bigint", nullable: false),
                    LessonId = table.Column<long>(type: "bigint", nullable: false),
                    Score = table.Column<int>(type: "int", nullable: false),
                    CorrectCount = table.Column<int>(type: "int", nullable: false),
                    WrongCount = table.Column<int>(type: "int", nullable: false),
                    Accuracy = table.Column<double>(type: "float", nullable: false),
                    StartedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    FinishedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PracticeSessions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PracticeSessions_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PracticeSessions_Users_StudentId",
                        column: x => x.StudentId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StudentLessonProgresses",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    StudentId = table.Column<long>(type: "bigint", nullable: false),
                    LessonId = table.Column<long>(type: "bigint", nullable: false),
                    LastPositionSecond = table.Column<double>(type: "float", nullable: false),
                    CompletedNoteCount = table.Column<int>(type: "int", nullable: false),
                    BestScore = table.Column<int>(type: "int", nullable: false),
                    TotalAttempts = table.Column<int>(type: "int", nullable: false),
                    IsCompleted = table.Column<bool>(type: "bit", nullable: false),
                    LastStudiedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StudentLessonProgresses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StudentLessonProgresses_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_StudentLessonProgresses_Users_StudentId",
                        column: x => x.StudentId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "PracticeSessionDetails",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PracticeSessionId = table.Column<long>(type: "bigint", nullable: false),
                    LessonNoteId = table.Column<long>(type: "bigint", nullable: false),
                    ExpectedNote = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PressedNote = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsCorrect = table.Column<bool>(type: "bit", nullable: false),
                    PressedAtSecond = table.Column<double>(type: "float", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PracticeSessionDetails", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PracticeSessionDetails_LessonNotes_LessonNoteId",
                        column: x => x.LessonNoteId,
                        principalTable: "LessonNotes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PracticeSessionDetails_PracticeSessions_PracticeSessionId",
                        column: x => x.PracticeSessionId,
                        principalTable: "PracticeSessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StudentNoteAttempts",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PracticeSessionId = table.Column<long>(type: "bigint", nullable: false),
                    LessonNoteId = table.Column<long>(type: "bigint", nullable: false),
                    ExpectedNote = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PlayedNote = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ExpectedSecond = table.Column<double>(type: "float", nullable: false),
                    PlayedSecond = table.Column<double>(type: "float", nullable: false),
                    TimeOffsetMs = table.Column<double>(type: "float", nullable: false),
                    IsCorrectPitch = table.Column<bool>(type: "bit", nullable: false),
                    IsCorrectTiming = table.Column<bool>(type: "bit", nullable: false),
                    IsCorrect = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StudentNoteAttempts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StudentNoteAttempts_LessonNotes_LessonNoteId",
                        column: x => x.LessonNoteId,
                        principalTable: "LessonNotes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_StudentNoteAttempts_PracticeSessions_PracticeSessionId",
                        column: x => x.PracticeSessionId,
                        principalTable: "PracticeSessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_LessonNotes_LessonId",
                table: "LessonNotes",
                column: "LessonId");

            migrationBuilder.CreateIndex(
                name: "IX_Lessons_TeacherId",
                table: "Lessons",
                column: "TeacherId");

            migrationBuilder.CreateIndex(
                name: "IX_PasswordResetTokens_UserId",
                table: "PasswordResetTokens",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_PracticeSessionDetails_LessonNoteId",
                table: "PracticeSessionDetails",
                column: "LessonNoteId");

            migrationBuilder.CreateIndex(
                name: "IX_PracticeSessionDetails_PracticeSessionId",
                table: "PracticeSessionDetails",
                column: "PracticeSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_PracticeSessions_LessonId",
                table: "PracticeSessions",
                column: "LessonId");

            migrationBuilder.CreateIndex(
                name: "IX_PracticeSessions_StudentId",
                table: "PracticeSessions",
                column: "StudentId");

            migrationBuilder.CreateIndex(
                name: "IX_StudentLessonProgresses_LessonId",
                table: "StudentLessonProgresses",
                column: "LessonId");

            migrationBuilder.CreateIndex(
                name: "IX_StudentLessonProgresses_StudentId_LessonId",
                table: "StudentLessonProgresses",
                columns: new[] { "StudentId", "LessonId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_StudentNoteAttempts_LessonNoteId",
                table: "StudentNoteAttempts",
                column: "LessonNoteId");

            migrationBuilder.CreateIndex(
                name: "IX_StudentNoteAttempts_PracticeSessionId",
                table: "StudentNoteAttempts",
                column: "PracticeSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Email",
                table: "Users",
                column: "Email",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PasswordResetTokens");

            migrationBuilder.DropTable(
                name: "PracticeSessionDetails");

            migrationBuilder.DropTable(
                name: "StudentLessonProgresses");

            migrationBuilder.DropTable(
                name: "StudentNoteAttempts");

            migrationBuilder.DropTable(
                name: "LessonNotes");

            migrationBuilder.DropTable(
                name: "PracticeSessions");

            migrationBuilder.DropTable(
                name: "Lessons");

            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}
