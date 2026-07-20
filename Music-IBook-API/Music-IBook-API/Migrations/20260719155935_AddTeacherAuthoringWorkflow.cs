using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Music_IBook_API.Migrations
{
    /// <inheritdoc />
    public partial class AddTeacherAuthoringWorkflow : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_StudentNoteAttempts_PracticeSessionId",
                table: "StudentNoteAttempts");

            migrationBuilder.DropIndex(
                name: "IX_PracticeSessions_StudentId",
                table: "PracticeSessions");

            migrationBuilder.AddColumn<string>(
                name: "DefaultHand",
                table: "Lessons",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "Both");

            migrationBuilder.AddColumn<string>(
                name: "Difficulty",
                table: "Lessons",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "Beginner");

            migrationBuilder.CreateTable(
                name: "LessonAnnotations",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    LessonId = table.Column<long>(type: "bigint", nullable: false),
                    StartBeat = table.Column<double>(type: "float", nullable: false),
                    EndBeat = table.Column<double>(type: "float", nullable: true),
                    Kind = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Text = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonAnnotations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LessonAnnotations_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "LessonSections",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    LessonId = table.Column<long>(type: "bigint", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    StartBeat = table.Column<double>(type: "float", nullable: false),
                    EndBeat = table.Column<double>(type: "float", nullable: false),
                    DefaultTempo = table.Column<int>(type: "int", nullable: false),
                    Difficulty = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Hand = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonSections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LessonSections_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "LessonExercises",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    LessonId = table.Column<long>(type: "bigint", nullable: false),
                    LessonSectionId = table.Column<long>(type: "bigint", nullable: true),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Type = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Instruction = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ConfigJson = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonExercises", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LessonExercises_LessonSections_LessonSectionId",
                        column: x => x.LessonSectionId,
                        principalTable: "LessonSections",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_LessonExercises_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StudentAssignments",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    StudentId = table.Column<long>(type: "bigint", nullable: false),
                    LessonId = table.Column<long>(type: "bigint", nullable: false),
                    LessonSectionId = table.Column<long>(type: "bigint", nullable: true),
                    LessonExerciseId = table.Column<long>(type: "bigint", nullable: true),
                    Message = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DueAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsCompleted = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StudentAssignments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StudentAssignments_LessonExercises_LessonExerciseId",
                        column: x => x.LessonExerciseId,
                        principalTable: "LessonExercises",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_StudentAssignments_LessonSections_LessonSectionId",
                        column: x => x.LessonSectionId,
                        principalTable: "LessonSections",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_StudentAssignments_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_StudentAssignments_Users_StudentId",
                        column: x => x.StudentId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_StudentNoteAttempts_PracticeSessionId_IsCorrect",
                table: "StudentNoteAttempts",
                columns: new[] { "PracticeSessionId", "IsCorrect" });

            migrationBuilder.CreateIndex(
                name: "IX_PracticeSessions_StudentId_LessonId_StartedAtUtc",
                table: "PracticeSessions",
                columns: new[] { "StudentId", "LessonId", "StartedAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_LessonAnnotations_LessonId_StartBeat",
                table: "LessonAnnotations",
                columns: new[] { "LessonId", "StartBeat" });

            migrationBuilder.CreateIndex(
                name: "IX_LessonExercises_LessonId_SortOrder",
                table: "LessonExercises",
                columns: new[] { "LessonId", "SortOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_LessonExercises_LessonSectionId",
                table: "LessonExercises",
                column: "LessonSectionId");

            migrationBuilder.CreateIndex(
                name: "IX_LessonSections_LessonId_SortOrder",
                table: "LessonSections",
                columns: new[] { "LessonId", "SortOrder" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_StudentAssignments_LessonExerciseId",
                table: "StudentAssignments",
                column: "LessonExerciseId");

            migrationBuilder.CreateIndex(
                name: "IX_StudentAssignments_LessonId",
                table: "StudentAssignments",
                column: "LessonId");

            migrationBuilder.CreateIndex(
                name: "IX_StudentAssignments_LessonSectionId",
                table: "StudentAssignments",
                column: "LessonSectionId");

            migrationBuilder.CreateIndex(
                name: "IX_StudentAssignments_StudentId_CreatedAtUtc",
                table: "StudentAssignments",
                columns: new[] { "StudentId", "CreatedAtUtc" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LessonAnnotations");

            migrationBuilder.DropTable(
                name: "StudentAssignments");

            migrationBuilder.DropTable(
                name: "LessonExercises");

            migrationBuilder.DropTable(
                name: "LessonSections");

            migrationBuilder.DropIndex(
                name: "IX_StudentNoteAttempts_PracticeSessionId_IsCorrect",
                table: "StudentNoteAttempts");

            migrationBuilder.DropIndex(
                name: "IX_PracticeSessions_StudentId_LessonId_StartedAtUtc",
                table: "PracticeSessions");

            migrationBuilder.DropColumn(
                name: "DefaultHand",
                table: "Lessons");

            migrationBuilder.DropColumn(
                name: "Difficulty",
                table: "Lessons");

            migrationBuilder.CreateIndex(
                name: "IX_StudentNoteAttempts_PracticeSessionId",
                table: "StudentNoteAttempts",
                column: "PracticeSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_PracticeSessions_StudentId",
                table: "PracticeSessions",
                column: "StudentId");
        }
    }
}

