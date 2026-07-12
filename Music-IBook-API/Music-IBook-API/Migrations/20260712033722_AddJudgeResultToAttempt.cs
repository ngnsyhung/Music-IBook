using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Music_IBook_API.Migrations
{
    /// <inheritdoc />
    public partial class AddJudgeResultToAttempt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "JudgeResult",
                table: "StudentNoteAttempts",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "JudgeResult",
                table: "StudentNoteAttempts");
        }
    }
}
