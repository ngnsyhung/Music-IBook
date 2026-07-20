using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Music_IBook_API.Migrations
{
    /// <inheritdoc />
    public partial class OptimizeDatabase : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PracticeSessionDetails");

            migrationBuilder.DropColumn(
                name: "DefaultHand",
                table: "Lessons");

            migrationBuilder.DropColumn(
                name: "Difficulty",
                table: "Lessons");

            migrationBuilder.DropColumn(
                name: "PracticeGuide",
                table: "Lessons");

            migrationBuilder.DropColumn(
                name: "TheoryContent",
                table: "Lessons");

            migrationBuilder.DropColumn(
                name: "TheoryTitle",
                table: "Lessons");

            migrationBuilder.AddColumn<string>(
                name: "Fingering",
                table: "LessonNotes",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Fingering",
                table: "LessonNotes");

            migrationBuilder.AddColumn<string>(
                name: "DefaultHand",
                table: "Lessons",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Difficulty",
                table: "Lessons",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "PracticeGuide",
                table: "Lessons",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "TheoryContent",
                table: "Lessons",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "TheoryTitle",
                table: "Lessons",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateTable(
                name: "PracticeSessionDetails",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    LessonNoteId = table.Column<long>(type: "bigint", nullable: false),
                    PracticeSessionId = table.Column<long>(type: "bigint", nullable: false),
                    ExpectedNote = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsCorrect = table.Column<bool>(type: "bit", nullable: false),
                    PressedAtSecond = table.Column<double>(type: "float", nullable: false),
                    PressedNote = table.Column<string>(type: "nvarchar(max)", nullable: false)
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

            migrationBuilder.CreateIndex(
                name: "IX_PracticeSessionDetails_LessonNoteId",
                table: "PracticeSessionDetails",
                column: "LessonNoteId");

            migrationBuilder.CreateIndex(
                name: "IX_PracticeSessionDetails_PracticeSessionId",
                table: "PracticeSessionDetails",
                column: "PracticeSessionId");
        }
    }
}
