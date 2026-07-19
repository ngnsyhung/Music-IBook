using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Music_IBook_API.Migrations
{
    /// <inheritdoc />
    public partial class AddPolyphonicScoreMetadata : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "TimeSignatureMap",
                table: "Lessons",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "Staff",
                table: "LessonNotes",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "Voice",
                table: "LessonNotes",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TimeSignatureMap",
                table: "Lessons");

            migrationBuilder.DropColumn(
                name: "Staff",
                table: "LessonNotes");

            migrationBuilder.DropColumn(
                name: "Voice",
                table: "LessonNotes");
        }
    }
}
